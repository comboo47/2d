extends SceneTree
## 第十期 关卡结束判定回归测试：敌人全灭→LEVEL_END(victory=true)。
## 运行：godot --headless --path . -s res://tests/LevelEndConditionTest.gd

var _failures := 0
var _nodes: Array[Node] = []

func _initialize() -> void:
	call_deferred("_run_all")

func _run_all() -> void:
	_run("enemy_cleared_emits_level_end_victory", _test_victory)
	_run("partial_kill_no_level_end", _test_partial)
	quit(_failures)

func _run(name: String, c: Callable) -> void:
	GameplayEventBus.clear_history()
	var r = c.call()
	if r is bool and r == true:
		print("PASS ", name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [name, str(r)])
	_cleanup()

# 造一个带 N 个敌人的 LevelDefinition（敌人用纯 BattleActor + HP 属性，不依赖场景）。
func _make_runner(enemy_count: int) -> LevelRunner:
	var runner := LevelRunner.new()
	root.add_child(runner)
	_nodes.append(runner)
	var level := LevelDefinition.new()
	level.level_id = "test_level"
	level.next_level_id = "test_next"
	var actors: Array[LevelActorDefinition] = []
	for i in enemy_count:
		var ad := LevelActorDefinition.new()
		ad.actor_scene = _make_enemy_scene()
		ad.position = Vector2(i * 50, 0)
		ad.is_enemy = true
		actors.append(ad)
	level.initial_actors = actors
	runner.level_definition = level
	runner.start_level()
	return runner

func _make_enemy_scene() -> PackedScene:
	var actor := BattleActor.new()
	var comp := AttributeComponent.new()
	var aset := AttributeSet.new()
	var hp := Attribute.new()
	hp.attribute_name = AttributeConfig.AttributeName.Hp
	hp.base_value = 10.0
	var arr: Array[Attribute] = [hp]
	aset.attributes = arr
	comp.attribute_set = aset
	actor.add_child(comp)
	# PackedScene.pack 只打包 owner 指向被打包根的子节点；不设 owner 子节点会丢失。
	comp.owner = actor
	actor.Eattribute = comp
	var packed := PackedScene.new()
	packed.pack(actor)
	actor.free()
	return packed

func _kill(actor: BattleActor) -> void:
	var req := DamageRequest.new()
	req.target = actor
	req.amount = 9999.0
	DamageResolver.resolve(req)

func _test_victory() -> Variant:
	var runner := _make_runner(1)
	if runner.get_alive_enemy_count() != 1:
		return "应有 1 个存活敌人，得到 %d" % runner.get_alive_enemy_count()
	_kill(runner.spawned_actors[0])
	if not runner.is_level_ended():
		return "敌人全灭后应结束"
	var found := false
	for e in GameplayEventBus.emitted_events:
		if e.event_type == GameplayEvent.EventType.LEVEL_END:
			found = true
			if e.event_data.get("victory") != true:
				return "LEVEL_END.victory 应为 true"
			if e.event_data.get("next_level_id") != "test_next":
				return "LEVEL_END.next_level_id 应为 test_next"
	if not found:
		return "应 emit LEVEL_END"
	return true

func _test_partial() -> Variant:
	var runner := _make_runner(2)
	_kill(runner.spawned_actors[0])
	if runner.is_level_ended():
		return "只杀 1/2 不应结束"
	if runner.get_alive_enemy_count() != 1:
		return "应剩 1 个存活敌人"
	return true

func _cleanup() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()
