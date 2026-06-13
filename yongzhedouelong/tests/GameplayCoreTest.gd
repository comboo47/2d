extends SceneTree

const SaveManagerScript = preload("res://src/app/SaveManager.gd")
const TEST_SAVE_PATH := "user://save_manager_test/progress.json"

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

class StubWeapon extends Node:
	## 模拟武器：记录 trigger_skill_by_type 被以哪种触发类型调用
	var hit_triggered := false
	var kill_triggered := false

	func trigger_skill_by_type(trigger_type, _context = null) -> void:
		if trigger_type == WeaponSkillSlot.TriggerType.ON_HIT:
			hit_triggered = true
		elif trigger_type == WeaponSkillSlot.TriggerType.ON_KILL:
			kill_triggered = true

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
	_run("bullet_hit_resolves_damage_and_triggers_on_hit", _test_bullet_hit_resolves_damage_and_triggers_on_hit)
	_run("bullet_hit_lethal_triggers_on_kill", _test_bullet_hit_lethal_triggers_on_kill)
	_run("buff_tick_event_triggers_flow", _test_buff_tick_event_triggers_flow)
	_run("skill_triggers_configured_flow", _test_skill_triggers_configured_flow)
	_run("level_runner_initializes_actors_buffs_and_start_flow", _test_level_runner_initializes_actors_buffs_and_start_flow)
	_run("four_act_campaign_outline_matches_secret_realm_revenge_plan", _test_four_act_campaign_outline_matches_secret_realm_revenge_plan)
	_run("save_manager_missing_file_returns_default_progress", _test_save_manager_missing_file_returns_default_progress)
	_run("save_manager_save_and_load_round_trip", _test_save_manager_save_and_load_round_trip)
	_run("save_manager_mark_level_completed_deduplicates_levels_and_merges_rewards", _test_save_manager_mark_level_completed_deduplicates_levels_and_merges_rewards)
	_run("save_manager_unlock_level_deduplicates_levels", _test_save_manager_unlock_level_deduplicates_levels)
	_run("save_manager_reset_progress_restores_default_shape", _test_save_manager_reset_progress_restores_default_shape)
	_run("save_manager_malformed_json_falls_back_to_default_progress", _test_save_manager_malformed_json_falls_back_to_default_progress)
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

func _test_four_act_campaign_outline_matches_secret_realm_revenge_plan() -> Variant:
	var campaign := load("res://resources/gameplay/campaign/secret_realm_revenge_campaign.tres")
	if campaign == null:
		return "campaign outline should load"
	if campaign.acts.size() != 4:
		return "expected four acts, got %d" % campaign.acts.size()

	var act_one = campaign.get_act_by_id("act_01_sect_escape")
	var act_two = campaign.get_act_by_id("act_02_secret_realm")
	var act_three = campaign.get_act_by_id("act_03_outer_counterattack")
	var act_four = campaign.get_act_by_id("act_04_sect_revenge")

	if act_one == null or act_one.primary_gameplay != "escape_tutorial":
		return "act one should be the sect escape tutorial"
	if act_one.reward_tier != "starter_kit":
		return "act one should provide starter kit rewards"
	if act_two == null or not act_two.uses_room_clear_routes:
		return "act two should use dungeon room-clear routing"
	if act_two.reward_tier != "cultivation_resources":
		return "act two should reward cultivation resources"
	if act_three == null or not act_three.uses_room_clear_routes:
		return "act three should preserve room-clear routing"
	if act_three.reward_tier != "artifact_build":
		return "act three should reward artifacts"
	if act_four == null or act_four.reward_tier != "endgame_tuning":
		return "act four should focus on endgame tuning rewards"
	if act_four.act_id != "act_04_sect_revenge":
		return "act four final boss should be the betrayer senior brother"
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

func _test_save_manager_missing_file_returns_default_progress() -> Variant:
	_remove_test_save_file()
	var manager := _make_save_manager()
	var progress = manager.load_progress()

	if progress.get("schema_version") != 1:
		return "expected schema_version 1"
	if progress.get("current_level_id") != "":
		return "expected empty current_level_id"
	if progress.get("completed_levels", []).size() != 0:
		return "expected no completed levels"
	if progress.get("unlocked_levels", []).size() != 0:
		return "expected no unlocked levels"
	if not progress.get("rewards", {}) is Dictionary:
		return "expected rewards dictionary"
	return true

func _test_save_manager_save_and_load_round_trip() -> Variant:
	_remove_test_save_file()
	var manager := _make_save_manager()
	var progress := {
		"schema_version": 1,
		"current_level_id": "level_01",
		"completed_levels": ["level_01"],
		"unlocked_levels": ["level_01", "level_02"],
		"rewards": {"coin": 3},
		"updated_at": ""
	}

	if not manager.save_progress(progress):
		return "save_progress should return true"
	if not FileAccess.file_exists(TEST_SAVE_PATH):
		return "save file should exist"

	var reloaded := _make_save_manager()
	var loaded = reloaded.load_progress()
	if loaded.get("current_level_id") != "level_01":
		return "expected current_level_id level_01"
	if loaded.get("completed_levels", []) != ["level_01"]:
		return "expected completed level round trip"
	if loaded.get("unlocked_levels", []) != ["level_01", "level_02"]:
		return "expected unlocked levels round trip"
	if loaded.get("rewards", {}).get("coin") != 3:
		return "expected coin reward round trip"
	return true

func _test_save_manager_mark_level_completed_deduplicates_levels_and_merges_rewards() -> Variant:
	_remove_test_save_file()
	var manager := _make_save_manager()

	if not manager.mark_level_completed("level_01", {"coin": 1}):
		return "first mark_level_completed should save"
	if not manager.mark_level_completed("level_01", {"gem": 2}):
		return "second mark_level_completed should save"

	var progress = manager.get_progress()
	if progress.get("current_level_id") != "level_01":
		return "expected current level to be level_01"
	if progress.get("completed_levels", []) != ["level_01"]:
		return "expected completed level to be deduplicated"
	if progress.get("rewards", {}).get("coin") != 1:
		return "expected existing reward to remain"
	if progress.get("rewards", {}).get("gem") != 2:
		return "expected new reward to merge"
	return true

func _test_save_manager_unlock_level_deduplicates_levels() -> Variant:
	_remove_test_save_file()
	var manager := _make_save_manager()

	if not manager.unlock_level("level_02"):
		return "first unlock_level should save"
	if not manager.unlock_level("level_02"):
		return "second unlock_level should save"

	var progress = manager.get_progress()
	if progress.get("unlocked_levels", []) != ["level_02"]:
		return "expected unlocked level to be deduplicated"
	return true

func _test_save_manager_reset_progress_restores_default_shape() -> Variant:
	_remove_test_save_file()
	var manager := _make_save_manager()
	manager.mark_level_completed("level_01", {"coin": 1})

	if not manager.reset_progress():
		return "reset_progress should save"

	var progress = manager.get_progress()
	if progress.get("schema_version") != 1:
		return "expected schema_version 1 after reset"
	if progress.get("current_level_id") != "":
		return "expected empty current_level_id after reset"
	if progress.get("completed_levels", []).size() != 0:
		return "expected no completed levels after reset"
	if progress.get("unlocked_levels", []).size() != 0:
		return "expected no unlocked levels after reset"
	if progress.get("rewards", {}).size() != 0:
		return "expected no rewards after reset"
	return true

func _test_save_manager_malformed_json_falls_back_to_default_progress() -> Variant:
	_remove_test_save_file()
	_write_test_save_text("{ this is not valid json")

	var manager := _make_save_manager()
	var progress = manager.load_progress()
	if progress.get("schema_version") != 1:
		return "expected schema_version 1 for malformed file fallback"
	if progress.get("completed_levels", []).size() != 0:
		return "expected default completed levels for malformed file fallback"
	if not FileAccess.file_exists(TEST_SAVE_PATH):
		return "malformed file should remain on disk"
	return true

func _make_save_manager() -> Node:
	var manager = SaveManagerScript.new()
	manager.set_save_path_for_tests(TEST_SAVE_PATH)
	return manager

func _remove_test_save_file() -> void:
	if not FileAccess.file_exists(TEST_SAVE_PATH):
		return
	var dir := DirAccess.open(TEST_SAVE_PATH.get_base_dir())
	if dir:
		dir.remove(TEST_SAVE_PATH.get_file())

func _write_test_save_text(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE_PATH.get_base_dir())
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(text)

func _test_bullet_hit_resolves_damage_and_triggers_on_hit() -> Variant:
	GameplayEventBus.clear_history()
	var source := _make_actor(0.0, 0.0, 0.0)
	var target := _make_actor(50.0, 0.0, 0.0)
	var weapon := StubWeapon.new()
	get_root().add_child(weapon)
	_track_node(weapon)

	# 运行时 load（此时 autoload 已注册，BattleManager.gd 可编译）
	var battle_manager = load("res://src/gameplay/battle/BattleManager.gd")
	var result = battle_manager.resolve_bullet_hit(source, target, 12.0, "", "", weapon)
	if result == null:
		return "resolve_bullet_hit should return a DamageResult"

	var hp := target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp)
	if not is_equal_approx(hp.get_value(), 38.0):
		return "expected target hp 38 after 12 damage, got %s" % hp.get_value()
	if not _has_event(GameplayEvent.EventType.DAMAGE_APPLIED):
		return "expected DAMAGE_APPLIED event"
	if not weapon.hit_triggered:
		return "expected weapon ON_HIT to be triggered on hit"
	if weapon.kill_triggered:
		return "ON_KILL should not trigger while target survives"
	return true

func _test_bullet_hit_lethal_triggers_on_kill() -> Variant:
	var source := _make_actor(0.0, 0.0, 0.0)
	var target := _make_actor(10.0, 0.0, 0.0)
	var weapon := StubWeapon.new()
	get_root().add_child(weapon)
	_track_node(weapon)

	var battle_manager = load("res://src/gameplay/battle/BattleManager.gd")
	battle_manager.resolve_bullet_hit(source, target, 15.0, "", "", weapon)
	if not weapon.hit_triggered:
		return "expected ON_HIT to trigger on lethal hit"
	if not weapon.kill_triggered:
		return "expected ON_KILL to trigger when target hp drops to 0"
	return true
