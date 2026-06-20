extends SceneTree
## 第十一/十三期 Actor 作为 SpawnFlow/DeathFlow 宿主回归测试（FlowGraph + FlowInterpreter）。
## 运行：godot --headless --path . -s res://tests/ActorFlowHostTest.gd

var _failures := 0
var _nodes: Array[Node] = []

func _initialize() -> void:
	call_deferred("_run_all")

func _run_all() -> void:
	_run("setup_starts_spawn_flow", _test_spawn)
	_run("null_init_data_no_flow", _test_null)
	_run("death_flow_sync_finish_triggers_finish_death", _test_death_sync)
	_run("death_flow_seconds_gates_finish_death", _test_death_seconds)
	quit(_failures)

func _run(name: String, c: Callable) -> void:
	var r = c.call()
	if r is bool and r == true:
		print("PASS ", name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [name, str(r)])
	_cleanup()

# 记录 run 次数的脚本叶子（@export 计数器在 deep_duplicate 后仍可被实例方法累加）。
class ProbeLeaf extends FlowLeaf:
	static var ran := 0
	func run(_ctx, _host = null) -> void:
		ProbeLeaf.ran += 1

# 桩 actor：override _finish_death 计数，不真 queue_free。
class StubActor extends BattleActor:
	var finish_death_count := 0
	func _finish_death() -> void:
		finish_death_count += 1

func _make_actor() -> StubActor:
	var a := StubActor.new()
	root.add_child(a)
	_nodes.append(a)
	return a

# 单 INSTANT Duration + ProbeLeaf 的 spawn graph。
func _make_probe_graph() -> FlowGraph:
	var act := FlowGraph.leaf_action(ProbeLeaf.new())
	return FlowGraph.single(FlowGraph.instant([act] as Array[FlowNode]))

# 同步即结束的 death graph（单 INSTANT，无延时 Duration）。
func _make_sync_death_graph() -> FlowGraph:
	return FlowGraph.single(FlowGraph.instant([] as Array[FlowNode]))

# 带 SECONDS 延时的 death graph（门控延迟销毁）。
func _make_seconds_death_graph(delay: float) -> FlowGraph:
	var g := FlowGraph.new()
	g.durations = [FlowGraph.seconds(delay)]
	return g

func _test_spawn() -> Variant:
	ProbeLeaf.ran = 0
	var a := _make_actor()
	var data := ActorInitData.new()
	data.spawn_flow = _make_probe_graph()
	a.setup_init_data(data)
	if a._spawn_interp == null:
		return "spawn_flow 应建解释器实例"
	# 单 INSTANT 叶子：start 即跑完一次
	if ProbeLeaf.ran != 1:
		return "spawn_flow 叶子 run 应调一次，得到 %d" % ProbeLeaf.ran
	if not a._spawn_interp.is_finished():
		return "INSTANT spawn_flow 应当帧 finished"
	return true

func _test_null() -> Variant:
	var a := _make_actor()
	a.setup_init_data(null)
	if a._spawn_interp != null:
		return "null init_data 不应建 spawn 解释器"
	return true

func _test_death_sync() -> Variant:
	var a := _make_actor()
	var data := ActorInitData.new()
	data.death_flow = _make_sync_death_graph()
	a.setup_init_data(data)
	a.kill(null)
	# 同步 finish（INSTANT death graph 立即 finished）→ _death_flow_done + _finish_death 被调
	if not a._death_flow_done:
		return "同步 death_flow 后 _death_flow_done 应为 true"
	if a.finish_death_count != 1:
		return "_finish_death 应被调一次，得到 %d" % a.finish_death_count
	return true

func _test_death_seconds() -> Variant:
	var a := _make_actor()
	var data := ActorInitData.new()
	data.death_flow = _make_seconds_death_graph(1.0)
	a.setup_init_data(data)
	a.kill(null)
	# SECONDS 未到 → 不应 finish
	if a._death_flow_done:
		return "SECONDS 未到时不应 _death_flow_done"
	if a.finish_death_count != 0:
		return "未完成时 _finish_death 不应被调"
	# 喂帧推进解释器越过 1.0s（actor._physics_process 内部会 advance + 门控）
	a._physics_process(0.5)
	if a._death_flow_done:
		return "0.5s 不应完成"
	a._physics_process(0.7)  # 累计 1.2s
	if not a._death_flow_done or a.finish_death_count != 1:
		return "累计超 1.0s 应触发 _finish_death 一次，得到 done=%s count=%d" % [a._death_flow_done, a.finish_death_count]
	# 幂等：再喂帧不应重复
	a._physics_process(1.0)
	if a.finish_death_count != 1:
		return "重复推进应幂等（仍 1 次）"
	return true

func _cleanup() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()
