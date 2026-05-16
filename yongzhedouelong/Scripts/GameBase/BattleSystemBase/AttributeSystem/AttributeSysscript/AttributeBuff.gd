@tool
class_name AttributeBuff extends Resource

@export var id: String = ""
@export var name: String = ""
@export var buff_id: String = ""
@export var buff_Name: String = ""
@export var buff_name: String = ""
@export var buffDuration := 0.0
@export var buffPeriod := 0
@export var isLeaveReset := false
@export var BuffEffects: Array[AttributeBuffEffect] = []
@export var duration: float = 0.0
@export var merging := DurationMerging.Restart
@export var stack: int = 1
@export var max_stack: int = 1
@export var event_flows: Dictionary = {}

enum DurationMerging {
	Restart,
	Addtion,
	NoEffect,
}

var BuffSource: BattleActor = null
var BuffTarget: BattleActor = null
var attribute_modifier: AttributeModifier = null
var remaining_time: float = 0.0
var is_pending_remove := false
var applied_attribute = null
var _tick_elapsed := 0.0

func write_all_children_data() -> void:
	pass

func Create(_source: BattleActor, _target: BattleActor) -> void:
	initialize_runtime(_source, _target)
	for effect in BuffEffects:
		if effect:
			effect.Create(_source, _target, self)

func initialize_runtime(_source: BattleActor, _target: BattleActor) -> void:
	_normalize_legacy_fields()
	BuffSource = _source
	BuffTarget = _target
	remaining_time = get_runtime_duration()
	_tick_elapsed = 0.0
	is_pending_remove = false
	stack = clampi(stack, 1, max(1, max_stack))

func deep_duplicate(_source: BattleActor, _target: BattleActor) -> AttributeBuff:
	var duplicated_buff := duplicate(true) as AttributeBuff
	duplicated_buff.initialize_runtime(_source, _target)
	return duplicated_buff

func run_process(delta: float) -> Array[GameplayEvent]:
	var events: Array[GameplayEvent] = []
	if is_pending_remove:
		return events

	var active_duration := get_runtime_duration()
	if active_duration > 0.0:
		remaining_time = max(remaining_time - delta, 0.0)
		if is_zero_approx(remaining_time):
			is_pending_remove = true

	if buffPeriod > 0:
		_tick_elapsed += delta
		while _tick_elapsed >= float(buffPeriod):
			_tick_elapsed -= float(buffPeriod)
			events.append(_make_event(GameplayEvent.EventType.BUFF_TICK))

	return events

func handle_gameplay_event(event: GameplayEvent) -> void:
	if event == null or is_pending_remove:
		return
	if not event_flows.has(event.event_type):
		return

	var context := GameplayFlowContext.create_from_event(event)
	context.buff = self
	context.source = BuffSource
	if context.target == null:
		context.target = BuffTarget
	context.stack = stack

	for flow in event_flows[event.event_type]:
		if flow is GameplayFlowBase:
			flow.deep_duplicate().execute(context)

func emit_lifecycle_event(type: GameplayEvent.EventType) -> void:
	var event := _make_event(type)
	GameplayEventBus.emit_event(event)
	handle_gameplay_event(event)

func add_stack(amount: int) -> void:
	var old_stack := stack
	stack = clampi(stack + amount, 1, max(1, max_stack))
	if stack != old_stack:
		emit_lifecycle_event(GameplayEvent.EventType.BUFF_STACK_CHANGED)

func restart_duration() -> void:
	remaining_time = get_runtime_duration()

func extend_duration(time: float) -> void:
	remaining_time += time

func operate(base_value: float) -> float:
	if attribute_modifier:
		return attribute_modifier.operate(base_value)
	return base_value

func set_merging(_merging: DurationMerging) -> void:
	merging = _merging

func set_duration(time: float) -> AttributeBuff:
	duration = time
	buffDuration = time
	remaining_time = time
	return self

func buff_execute() -> void:
	for effect in BuffEffects:
		if effect:
			effect.EffectGo()

func _make_event(type: GameplayEvent.EventType) -> GameplayEvent:
	var event := GameplayEvent.create(type, BuffSource, BuffTarget)
	event.buff = self
	event.event_data["buff_id"] = get_runtime_id()
	event.event_data["stack"] = stack
	return event

func get_runtime_id() -> String:
	return buff_id if not buff_id.is_empty() else id

func get_runtime_name() -> String:
	if not buff_name.is_empty():
		return buff_name
	if not buff_Name.is_empty():
		return buff_Name
	return name

func get_runtime_duration() -> float:
	return duration if duration > 0.0 else buffDuration

func _normalize_legacy_fields() -> void:
	if buff_id.is_empty():
		buff_id = id
	if id.is_empty():
		id = buff_id
	if buff_name.is_empty():
		buff_name = buff_Name if not buff_Name.is_empty() else name
	if buff_Name.is_empty():
		buff_Name = buff_name
	if name.is_empty():
		name = buff_name
	if duration <= 0.0 and buffDuration > 0.0:
		duration = buffDuration
	if buffDuration <= 0.0 and duration > 0.0:
		buffDuration = duration
