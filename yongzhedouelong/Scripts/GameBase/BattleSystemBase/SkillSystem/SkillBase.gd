class_name SkillBase extends Resource

@export var skill_id: String = ""
@export var skill_name: String = ""
@export_multiline var skill_description: String = ""
@export var skill_type: SkillConfig.SkillType = SkillConfig.SkillType.ACTIVE
@export var target_type: SkillConfig.TargetType = SkillConfig.TargetType.ENEMY_SINGLE
@export var target_range: float = 100.0
@export var cost_type: SkillConfig.CostType = SkillConfig.CostType.MANA
@export var cost_value: float = 20.0
@export var cooldown_time: float = 5.0
@export var skill_level: int = 1
@export var effects: Array[SkillEffectBase] = []
@export var triggers: Array[SkillTrigger] = []
@export var on_use_flow_id: String = ""
@export var flow_refs: Array[GameplayFlowBase] = []
@export var icon_path: String = ""

var cooldown: SkillCooldown = null
var skill_owner: BattleActor = null
var is_active := false

func initialize(owner: BattleActor) -> void:
	skill_owner = owner
	cooldown = SkillCooldown.new()
	cooldown.init(cooldown_time)
	if skill_type == SkillConfig.SkillType.PASSIVE:
		activate_passive()

func can_use() -> bool:
	if cooldown and not cooldown.is_ready():
		return false
	if not _check_cost():
		return false
	return true

func use(context: GameplayFlowContext = null) -> bool:
	if not can_use():
		return false
	if context == null:
		context = _create_default_context()

	context.skill = self
	context.event_data["skill_id"] = skill_id
	context.event_data["skill_level"] = skill_level

	_consume_cost()

	if skill_type == SkillConfig.SkillType.TOGGLE:
		is_active = not is_active
		if is_active:
			_execute_legacy_effects(context)
			_execute_flows(context)
		else:
			_cleanup_effects(context)
		return true

	if cooldown:
		cooldown.start()

	_execute_legacy_effects(context)
	_execute_flows(context)

	var event := GameplayEvent.create(GameplayEvent.EventType.SKILL_USED, context.source, context.target)
	event.skill = self
	event.event_data = context.event_data
	GameplayEventBus.emit_event(event)
	return true

func _execute_flows(context: GameplayFlowContext) -> void:
	for flow in flow_refs:
		if flow:
			flow.execute(context)

	var registry := _get_flow_registry()
	if not on_use_flow_id.is_empty() and registry:
		var registry_flow: GameplayFlowBase = registry.get_flow(on_use_flow_id)
		if registry_flow:
			registry_flow.execute(context)

func _execute_legacy_effects(context: GameplayFlowContext) -> void:
	var sorted_effects := effects.duplicate()
	sorted_effects.sort_custom(func(a: SkillEffectBase, b: SkillEffectBase) -> bool:
		if a == null:
			return false
		if b == null:
			return true
		return a.priority < b.priority
	)
	for effect in sorted_effects:
		if effect:
			effect.apply(context, self)

func _cleanup_effects(context: GameplayFlowContext) -> void:
	for effect in effects:
		if effect:
			effect.cleanup(context, self)

func activate_passive() -> void:
	if skill_owner == null:
		return
	var context := GameplayFlowContext.create_simple(skill_owner)
	context.skill = self
	_execute_legacy_effects(context)
	_execute_flows(context)

func update_cooldown(delta: float) -> void:
	if cooldown:
		cooldown.update(delta)

func check_trigger(trigger_moment: SkillConfig.TriggerMoment, context: GameplayFlowContext) -> bool:
	if skill_type != SkillConfig.SkillType.TRIGGERED:
		return false
	for trigger in triggers:
		if trigger.trigger_moment == trigger_moment:
			var current_time := Time.get_ticks_msec() / 1000.0
			if trigger.check_trigger(context, current_time):
				return true
	return false

func get_cooldown_progress() -> float:
	if cooldown:
		return cooldown.get_progress()
	return 1.0

func get_full_description() -> String:
	return skill_name + "\n" + skill_description

func _check_cost() -> bool:
	if skill_owner == null:
		return cost_type == SkillConfig.CostType.NONE or cost_type == SkillConfig.CostType.COOLDOWN_ONLY
	match cost_type:
		SkillConfig.CostType.NONE, SkillConfig.CostType.COOLDOWN_ONLY:
			return true
		SkillConfig.CostType.MANA:
			return _get_attribute_value(AttributeConfig.AttributeName.Mana) >= cost_value
		SkillConfig.CostType.HP:
			return _get_attribute_value(AttributeConfig.AttributeName.Hp) > cost_value
		SkillConfig.CostType.ENERGY:
			return true
	return true

func _consume_cost() -> void:
	match cost_type:
		SkillConfig.CostType.MANA:
			_subtract_attribute(AttributeConfig.AttributeName.Mana, cost_value)
		SkillConfig.CostType.HP:
			_subtract_attribute(AttributeConfig.AttributeName.Hp, cost_value)

func _get_attribute_value(attribute_name: AttributeConfig.AttributeName) -> float:
	if skill_owner == null or skill_owner.GetAttributes() == null:
		return 0.0
	var attr := skill_owner.GetAttributes().find_attribute(attribute_name)
	return attr.get_value() if attr else 0.0

func _subtract_attribute(attribute_name: AttributeConfig.AttributeName, amount: float) -> void:
	if skill_owner == null or skill_owner.GetAttributes() == null:
		return
	var attr := skill_owner.GetAttributes().find_attribute(attribute_name)
	if attr:
		attr.sub(amount)

func _create_default_context() -> GameplayFlowContext:
	var context := GameplayFlowContext.new()
	context.source = skill_owner
	match target_type:
		SkillConfig.TargetType.SELF:
			context.target = skill_owner
		SkillConfig.TargetType.NONEAREST_ENEMY:
			context.target = _find_nearest_enemy()
		_:
			context.target = null
	return context

func _find_nearest_enemy() -> BattleActor:
	if skill_owner == null:
		return null
	var enemies := skill_owner.get_tree().get_nodes_in_group("enemy")
	var nearest: BattleActor = null
	var nearest_dist := INF
	for enemy in enemies:
		if enemy is BattleActor:
			var dist := skill_owner.global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy
	return nearest

func _get_flow_registry() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("FlowRegistry")
