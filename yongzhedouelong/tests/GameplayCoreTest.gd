extends SceneTree

class RecordingEffect extends FlowEffectBase:
	var label := ""

	func _init(effect_label := "", effect_priority := 0) -> void:
		label = effect_label
		priority = effect_priority

	func apply(context: GameplayFlowContext) -> void:
		if not context.event_data.has("order"):
			context.event_data["order"] = []
		context.event_data["order"].append(label)

class DamageBonusEffect extends FlowEffectBase:
	func apply(context: GameplayFlowContext) -> void:
		if context.damage_request:
			context.damage_request.amount += 5.0

class EventCountingFlow extends GameplayFlowBase:
	var count := 0

	func _init() -> void:
		effects = [RecordingEffect.new("event", 0)]

	func start(context: GameplayFlowContext) -> bool:
		count += 1
		return super.start(context)

var _failures := 0
var _test_nodes: Array[Node] = []

func _initialize() -> void:
	_run("flow_executes_effects_by_priority", _test_flow_executes_effects_by_priority)
	_run("damage_resolver_applies_request_and_emits_events", _test_damage_resolver_applies_request_and_emits_events)
	_run("buff_tick_event_triggers_flow", _test_buff_tick_event_triggers_flow)
	_run("skill_triggers_configured_flow", _test_skill_triggers_configured_flow)
	_run("level_runner_initializes_actors_buffs_and_start_flow", _test_level_runner_initializes_actors_buffs_and_start_flow)
	quit(_failures)

func _run(test_name: String, test_callable: Callable) -> void:
	var result = test_callable.call()
	if result is bool and result == true:
		print("PASS ", test_name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [test_name, str(result)])
	_cleanup_test_nodes()

func _test_flow_executes_effects_by_priority() -> Variant:
	var flow := GameplayFlowBase.new()
	flow.effects = [
		RecordingEffect.new("late", 20),
		RecordingEffect.new("early", 0),
		RecordingEffect.new("middle", 10)
	]

	var context := GameplayFlowContext.new()
	context.event_data["order"] = []
	var executed := flow.start(context)

	if executed != true:
		return "flow.start should return true"
	if context.event_data["order"] != ["early", "middle", "late"]:
		return "unexpected effect order: %s" % [context.event_data["order"]]
	return true

func _test_damage_resolver_applies_request_and_emits_events() -> Variant:
	GameplayEventBus.clear_history()
	var source := _make_actor(0.0, 12.0, 0.0)
	var target := _make_actor(50.0, 0.0, 2.0)

	var request := DamageRequest.new()
	request.source = source
	request.target = target
	request.amount = 10.0
	request.formula = "damage.amount + source_attr(\"Atk\") - target_attr(\"Armor\")"
	request.tags = ["skill", "fire"]

	var result := DamageResolver.resolve(request)
	var hp := target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp)

	if not is_equal_approx(result.final_amount, 20.0):
		return "expected final damage 20, got %s" % result.final_amount
	if not is_equal_approx(hp.get_value(), 30.0):
		return "expected target hp 30, got %s" % hp.get_value()
	if not _has_event(GameplayEvent.EventType.DAMAGE_APPLIED):
		return "expected DAMAGE_APPLIED event"
	return true

func _test_buff_tick_event_triggers_flow() -> Variant:
	var source := _make_actor(0.0, 5.0, 0.0)
	var target := _make_actor(40.0, 0.0, 0.0)
	var flow := GameplayFlowBase.new()
	var damage_effect := FE_Damage.new()
	damage_effect.base_damage = 1.0
	damage_effect.damage_expression = "source_attr(\"Atk\") + buff.stack"
	damage_effect.use_attack_bonus = false
	damage_effect.use_armor_reduction = false
	flow.effects = [damage_effect]

	var buff := AttributeBuff.new()
	buff.buff_id = "burn_test"
	buff.buff_name = "Burn Test"
	buff.duration = 3.0
	buff.buffPeriod = 1
	buff.max_stack = 5
	buff.stack = 2
	buff.event_flows = {
		GameplayEvent.EventType.BUFF_TICK: [flow]
	}
	target.buffManager.apply_buff(buff, source, target)
	target.buffManager._physics_process(1.0)

	var hp := target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp)
	if not is_equal_approx(hp.get_value(), 33.0):
		return "expected burn tick to deal 7 damage, got hp %s" % hp.get_value()
	return true

func _test_skill_triggers_configured_flow() -> Variant:
	var source := _make_actor(0.0, 0.0, 0.0)
	var skill := SkillBase.new()
	skill.skill_id = "skill_flow_test"
	skill.skill_type = SkillConfig.SkillType.ACTIVE
	skill.cost_type = SkillConfig.CostType.NONE
	skill.cooldown_time = 0.0
	var flow := GameplayFlowBase.new()
	flow.effects = [RecordingEffect.new("skill_flow", 0)]
	skill.flow_refs = [flow]
	skill.initialize(source)

	var context := GameplayFlowContext.create_simple(source)
	context.event_data["order"] = []
	if not skill.use(context):
		return "skill.use should return true"
	if context.event_data["order"] != ["skill_flow"]:
		return "skill did not run configured flow"
	if context.skill != skill:
		return "context.skill should be assigned during skill use"
	return true

func _test_level_runner_initializes_actors_buffs_and_start_flow() -> Variant:
	var level := LevelDefinition.new()
	var actor_def := LevelActorDefinition.new()
	actor_def.actor_scene = _make_actor_scene()
	actor_def.position = Vector2(12, 8)
	level.initial_actors = [actor_def]

	var start_flow := GameplayFlowBase.new()
	start_flow.effects = [RecordingEffect.new("level_start", 0)]
	level.event_flows = {
		GameplayEvent.EventType.LEVEL_START: [start_flow]
	}

	var runner := LevelRunner.new()
	get_root().add_child(runner)
	_track_node(runner)
	runner.level_definition = level
	runner.start_level()

	if runner.spawned_actors.size() != 1:
		return "expected one spawned actor"
	if runner.spawned_actors[0].global_position != Vector2(12, 8):
		return "actor position was not initialized"
	if runner.runtime_context.event_data.get("order", []) != ["level_start"]:
		return "level start flow did not run"
	return true

func _make_actor(hp: float, atk: float, armor: float, add_to_root := true) -> BattleActor:
	var actor := BattleActor.new()
	var component := AttributeComponent.new()
	var set := AttributeSet.new()
	set.attributes = [
		_make_attribute(AttributeConfig.AttributeName.Hp, hp),
		_make_attribute(AttributeConfig.AttributeName.Atk, atk),
		_make_attribute(AttributeConfig.AttributeName.Armor, armor),
		_make_attribute(AttributeConfig.AttributeName.Mana, 0.0),
		_make_attribute(AttributeConfig.AttributeName.Crit, 0.0)
	]
	component.attribute_set = set
	actor.add_child(component)
	actor.SetAttributes(component)
	if add_to_root:
		get_root().add_child(actor)
		_track_node(actor)
	return actor

func _make_attribute(attribute_name: AttributeConfig.AttributeName, value: float) -> Attribute:
	var attr := Attribute.new()
	attr.attribute_name = attribute_name
	attr.base_value = value
	attr.computed_value = value
	return attr

func _make_actor_scene() -> PackedScene:
	var actor := _make_actor(10.0, 1.0, 0.0, false)
	var packed := PackedScene.new()
	packed.pack(actor)
	actor.free()
	return packed

func _has_event(event_type: GameplayEvent.EventType) -> bool:
	for event in GameplayEventBus.emitted_events:
		if event.event_type == event_type:
			return true
	return false

func _track_node(node: Node) -> void:
	if node and not _test_nodes.has(node):
		_test_nodes.append(node)

func _cleanup_test_nodes() -> void:
	for node in _test_nodes:
		if is_instance_valid(node):
			node.free()
	_test_nodes.clear()
