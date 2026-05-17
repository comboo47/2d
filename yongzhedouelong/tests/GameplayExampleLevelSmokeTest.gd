extends SceneTree

var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/ui/test/GameplayExampleLevel.tscn") as PackedScene
	if packed == null:
		_fail("example scene should load")
		quit(_failures)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	var runner := scene.get_node_or_null("LevelRunner") as LevelRunner
	if runner == null:
		_fail("LevelRunner should exist")
		_cleanup(scene)
		return
	if runner.spawned_actors.size() != 2:
		_fail("expected player and enemy to spawn, got %d" % runner.spawned_actors.size())
		_cleanup(scene)
		return

	var player := runner.spawned_actors[0]
	var enemy := runner.spawned_actors[1]
	var burn := enemy.buffManager.find_buff("example_burn")
	if burn == null:
		_fail("skill should apply example_burn")
		_cleanup(scene)
		return

	var hp_after_skill := _attribute_value(enemy, AttributeConfig.AttributeName.Hp)
	if not is_equal_approx(hp_after_skill, 30.0):
		_fail("enemy hp after skill should be 30, got %.2f" % hp_after_skill)
		_cleanup(scene)
		return

	await create_timer(1.1).timeout
	var hp_after_tick := _attribute_value(enemy, AttributeConfig.AttributeName.Hp)
	if not hp_after_tick < hp_after_skill:
		_fail("burn tick should reduce enemy hp below %.2f, got %.2f" % [hp_after_skill, hp_after_tick])
		_cleanup(scene)
		return

	var skill_manager := player.get_skill_manager()
	if skill_manager == null or skill_manager.get_skill("example_firebolt") == null:
		_fail("player should keep example_firebolt in SkillManager")
		_cleanup(scene)
		return

	print("PASS gameplay_example_level_smoke")
	_cleanup(scene)

func _cleanup(scene: Node) -> void:
	if is_instance_valid(scene):
		scene.free()
	quit(_failures)

func _fail(message: String) -> void:
	_failures += 1
	push_error("FAIL gameplay_example_level_smoke: %s" % message)

func _attribute_value(actor: BattleActor, attribute_name: AttributeConfig.AttributeName) -> float:
	if actor == null or actor.GetAttributes() == null:
		return 0.0
	var attribute := actor.GetAttributes().find_attribute(attribute_name)
	return attribute.get_value() if attribute else 0.0
