class_name GameplayFlowBase extends Resource

enum FlowEvent {
	NONE,
	ON_LEVEL_START,
	ON_WAVE_START,
	ON_WAVE_END,
	ON_LEVEL_END,
	ON_TIMER,
	ON_SPAWN,
	ON_DEATH,
	ON_HIT,
	ON_KILL,
	ON_SKILL_USE,
	ON_BUFF_APPLY,
	ON_BUFF_REMOVE,
}

@export var flow_id: String = ""
@export var flow_name: String = ""
@export var trigger_event: FlowEvent = FlowEvent.NONE
@export var condition_expression: String = ""
@export var effects: Array[FlowEffectBase] = []

var _cached_expression: Expression = null
var _condition_compiled := false

func start(context: GameplayFlowContext) -> bool:
	if context == null:
		return false
	if not _check_condition(context):
		return false

	_execute_flow(context)
	_execute_effects(context)
	return true

func execute(context: GameplayFlowContext) -> bool:
	return start(context)

func _execute_flow(_context: GameplayFlowContext) -> void:
	pass

func _execute_effects(context: GameplayFlowContext) -> void:
	var sorted_effects := effects.duplicate()
	sorted_effects.sort_custom(func(a: FlowEffectBase, b: FlowEffectBase) -> bool:
		if a == null:
			return false
		if b == null:
			return true
		return a.priority < b.priority
	)

	for effect in sorted_effects:
		if effect:
			effect.apply(context)

func _check_condition(context: GameplayFlowContext) -> bool:
	if condition_expression.is_empty():
		return true
	if not _condition_compiled:
		_compile_condition()
	if _cached_expression == null:
		push_warning("GameplayFlow '%s' condition failed to compile: %s" % [flow_id, condition_expression])
		return false

	var result = _cached_expression.execute(
		[
			context.source,
			context.target,
			context.skill,
			context.buff,
			context.gameplay_event,
			context.damage_request,
			context.event_data,
			context.stack,
		],
		self
	)
	if _cached_expression.has_execute_failed():
		push_warning("GameplayFlow '%s' condition execution failed: %s" % [flow_id, _cached_expression.get_error_text()])
		return false
	return result == true

func _compile_condition() -> void:
	_cached_expression = Expression.new()
	var parse_result := _cached_expression.parse(
		condition_expression,
		["source", "target", "skill", "buff", "event", "damage", "event_data", "stack"]
	)
	if parse_result != OK:
		push_error("GameplayFlow '%s' condition parse error: %s" % [flow_id, _cached_expression.get_error_text()])
		_cached_expression = null
	_condition_compiled = true

func get_event_name() -> String:
	return FlowEvent.keys()[trigger_event] if trigger_event >= 0 and trigger_event < FlowEvent.keys().size() else "UNKNOWN"

func deep_duplicate() -> GameplayFlowBase:
	var copy := duplicate(true) as GameplayFlowBase
	copy._cached_expression = null
	copy._condition_compiled = false
	return copy
