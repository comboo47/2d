extends SceneTree
## 第十三期 FlowInterpreter 节点树解释器核心测试（不接宿主）。
## 运行：godot --headless --path . -s res://tests/FlowInterpreterTest.gd

var _failures := 0
var _nodes: Array[Node] = []

func _initialize() -> void:
	_run("instant_runs_action", _test_instant)
	_run("forever_trigger_fires_multiple", _test_forever_never)
	_run("once_trigger_finishes_duration", _test_once_finish)
	_run("count_trigger_ends_after_n", _test_count)
	_run("multi_duration_serial", _test_serial)
	_run("seconds_duration_gates_on_elapsed", _test_seconds)
	_run("cancel_stops_delivery", _test_cancel)
	_run("leaf_action_runs", _test_leaf)
	_run("flow_actions_spread_directions", _test_spread)
	quit(_failures)

func _run(name: String, c: Callable) -> void:
	var r = c.call()
	if r is bool and r == true:
		print("PASS ", name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [name, str(r)])
	_cleanup()

#region helpers
func _make_attr(n: AttributeConfig.AttributeName, v: float) -> Attribute:
	var a := Attribute.new()
	a.attribute_name = n
	a.base_value = v
	return a

func _make_actor(hp: float) -> BattleActor:
	var actor := BattleActor.new()
	var comp := AttributeComponent.new()
	var set := AttributeSet.new()
	set.attributes = [
		_make_attr(AttributeConfig.AttributeName.Hp, hp),
		_make_attr(AttributeConfig.AttributeName.Atk, 0.0),
		_make_attr(AttributeConfig.AttributeName.Armor, 0.0),
		_make_attr(AttributeConfig.AttributeName.Mana, 0.0),
		_make_attr(AttributeConfig.AttributeName.Crit, 0.0),
	]
	comp.attribute_set = set
	actor.add_child(comp)
	actor.SetAttributes(comp)
	get_root().add_child(actor)
	_nodes.append(actor)
	return actor

func _dmg_action(amount: float) -> FlowAction:
	return FlowGraph.action("deal_damage", {"base": amount, "use_atk": false, "use_armor": false})

func _ctx(src: BattleActor, tgt: BattleActor) -> GameplayFlowContext:
	var c := GameplayFlowContext.new()
	c.source = src
	c.target = tgt
	return c

func _hp(a: BattleActor) -> float:
	return a.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp).get_value()
#endregion

func _test_instant() -> Variant:
	# INSTANT Duration 进入即跑 deal_damage，且当帧 finished
	var tgt := _make_actor(50.0)
	var actions: Array[FlowNode] = [_dmg_action(10.0)]
	var g := FlowGraph.single(FlowGraph.instant(actions))
	var interp := FlowInterpreter.new()
	interp.start(g, _ctx(null, tgt))
	if not is_equal_approx(_hp(tgt), 40.0):
		return "INSTANT 应造成 10 伤害→40，得到 %s" % _hp(tgt)
	if not interp.is_finished():
		return "无 Trigger 的 INSTANT 应当帧 finished"
	return true

func _test_forever_never() -> Variant:
	# FOREVER Duration + Trigger(BUFF_TICK, NEVER)：deliver 三次 → deal_damage 三次
	var tgt := _make_actor(100.0)
	var trig := FlowGraph.trigger(int(GameplayEvent.EventType.BUFF_TICK), [_dmg_action(5.0)], FlowTrigger.EndMode.NEVER)
	var g := FlowGraph.single(FlowGraph.forever([trig]))
	var interp := FlowInterpreter.new()
	interp.start(g, _ctx(null, tgt))
	for i in 3:
		interp.deliver_event(GameplayEvent.create(GameplayEvent.EventType.BUFF_TICK, null, tgt))
	if not is_equal_approx(_hp(tgt), 85.0):
		return "NEVER 触发 3 次应 -15→85，得到 %s" % _hp(tgt)
	if interp.is_finished():
		return "NEVER + FOREVER 不应自然结束"
	return true

func _test_once_finish() -> Variant:
	# Trigger(ONCE, finish_parent) → 触发后 finished
	var tgt := _make_actor(50.0)
	var trig := FlowGraph.trigger(int(GameplayEvent.EventType.BULLET_HIT), [_dmg_action(8.0)], FlowTrigger.EndMode.ONCE, true)
	var g := FlowGraph.single(FlowGraph.forever([trig]))
	var interp := FlowInterpreter.new()
	interp.start(g, _ctx(null, tgt))
	if interp.is_finished():
		return "未触发前不应 finished"
	interp.deliver_event(GameplayEvent.create(GameplayEvent.EventType.BULLET_HIT, null, tgt))
	if not is_equal_approx(_hp(tgt), 42.0):
		return "ONCE 应造成 8 伤害→42，得到 %s" % _hp(tgt)
	if not interp.is_finished():
		return "ONCE+finish_parent 触发后应 finished"
	# 再 deliver 不应再造成伤害
	interp.deliver_event(GameplayEvent.create(GameplayEvent.EventType.BULLET_HIT, null, tgt))
	if not is_equal_approx(_hp(tgt), 42.0):
		return "finished 后 deliver 不应再触发"
	return true

func _test_count() -> Variant:
	# Trigger(COUNT=2)：第2次触发后 ended
	var tgt := _make_actor(100.0)
	var trig := FlowGraph.trigger(int(GameplayEvent.EventType.BULLET_HIT), [_dmg_action(5.0)], FlowTrigger.EndMode.COUNT, false, 2)
	var g := FlowGraph.single(FlowGraph.forever([trig]))
	var interp := FlowInterpreter.new()
	interp.start(g, _ctx(null, tgt))
	for i in 4:
		interp.deliver_event(GameplayEvent.create(GameplayEvent.EventType.BULLET_HIT, null, tgt))
	# 只前 2 次生效 → -10
	if not is_equal_approx(_hp(tgt), 90.0):
		return "COUNT=2 应只触发 2 次→90，得到 %s" % _hp(tgt)
	return true

func _test_serial() -> Variant:
	# 两个 INSTANT Duration 串行：各造成一次伤害
	var tgt := _make_actor(100.0)
	var d1 := FlowGraph.instant([_dmg_action(10.0)] as Array[FlowNode])
	var d2 := FlowGraph.instant([_dmg_action(20.0)] as Array[FlowNode])
	var g := FlowGraph.new()
	g.durations = [d1, d2]
	var interp := FlowInterpreter.new()
	interp.start(g, _ctx(null, tgt))
	# 两个 INSTANT 应连续跑完 → -30
	if not is_equal_approx(_hp(tgt), 70.0):
		return "两 INSTANT 串行应 -30→70，得到 %s" % _hp(tgt)
	if not interp.is_finished():
		return "全部 Duration 跑完应 finished"
	return true

func _test_seconds() -> Variant:
	# SECONDS Duration：advance 累计到 lifetime_value 才结束（死亡延迟门控同款）。
	var tgt := _make_actor(100.0)
	var d_fx := FlowGraph.instant([_dmg_action(10.0)] as Array[FlowNode])
	var d_delay := FlowGraph.seconds(1.0)
	var g := FlowGraph.new()
	g.durations = [d_fx, d_delay]
	var interp := FlowInterpreter.new()
	interp.start(g, _ctx(null, tgt))
	# INSTANT 跑完→进入 SECONDS Duration，未到 1.0s 不应结束
	if interp.is_finished():
		return "SECONDS 未到时长不应 finished"
	interp.advance(0.4)
	if interp.is_finished():
		return "0.4s 不应 finished"
	interp.advance(0.7)  # 累计 1.1s ≥ 1.0
	if not interp.is_finished():
		return "累计超过 1.0s 应 finished"
	if not is_equal_approx(_hp(tgt), 90.0):
		return "INSTANT 段应造成 10 伤害→90，得到 %s" % _hp(tgt)
	return true

func _test_cancel() -> Variant:
	var tgt := _make_actor(100.0)
	var trig := FlowGraph.trigger(int(GameplayEvent.EventType.BULLET_HIT), [_dmg_action(5.0)], FlowTrigger.EndMode.NEVER)
	var g := FlowGraph.single(FlowGraph.forever([trig]))
	var interp := FlowInterpreter.new()
	interp.start(g, _ctx(null, tgt))
	interp.cancel()
	if interp.active_trigger_count() != 0:
		return "cancel 后活跃 Trigger 应为 0"
	interp.deliver_event(GameplayEvent.create(GameplayEvent.EventType.BULLET_HIT, null, tgt))
	if not is_equal_approx(_hp(tgt), 100.0):
		return "cancel 后 deliver 不应触发"
	return true

# 脚本叶子测试用
class ProbeLeaf extends FlowLeaf:
	static var ran := 0
	func run(_ctx, _host = null) -> void:
		ProbeLeaf.ran += 1

func _test_leaf() -> Variant:
	ProbeLeaf.ran = 0
	var tgt := _make_actor(50.0)
	var a := FlowGraph.leaf_action(ProbeLeaf.new())
	var g := FlowGraph.single(FlowGraph.instant([a] as Array[FlowNode]))
	var interp := FlowInterpreter.new()
	interp.start(g, _ctx(null, tgt))
	if ProbeLeaf.ran != 1:
		return "脚本叶子 run 应被调一次，得到 %d" % ProbeLeaf.ran
	return true

func _test_spread() -> Variant:
	# FlowActions._spread_directions：散射方向数（迁自旧 FlowRuntimeTest）。
	var dirs = FlowActions._spread_directions(Vector2.RIGHT, 3, 0.4)
	if dirs.size() != 3:
		return "散射应产生 3 个方向，得到 %d" % dirs.size()
	if FlowActions._spread_directions(Vector2.RIGHT, 1, 0.0).size() != 1:
		return "单发应只返回 1 个方向"
	return true

func _cleanup() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()
