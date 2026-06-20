extends SceneTree
## 特质系统第一版回归测试。
## 运行：godot --headless --path . -s res://tests/TraitSystemTest.gd

var _failures := 0

func _initialize() -> void:
	_run("bag_base_and_modifier_chain", _test_bag_chain)
	_run("bag_remove_modifier_by_source_restores", _test_bag_restore)
	_run("bag_no_declared_property_noop", _test_bag_noop)
	_run("bag_decrement_base", _test_bag_decrement)
	_run("definition_validate", _test_definition_validate)
	_run("container_add_and_dispatch", _test_container_dispatch)
	_run("bounce_flow_veto_decrement_reflect", _test_bounce_flow)
	_run("bounce_flow_exhausted_releases", _test_bounce_exhausted)
	quit(_failures)

func _run(name: String, c: Callable) -> void:
	var r = c.call()
	if r is bool and r == true:
		print("PASS ", name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [name, str(r)])

const AM = preload("res://src/gameplay/attributes/AttributeSysscript/AttributeModifier.gd")

#region PropertyBag
func _test_bag_chain() -> Variant:
	var bag := TraitPropertyBag.new()
	bag.set_base("atk", 5.0)
	if bag.get_value("atk") != 5.0:
		return "base 应为 5"
	bag.add_modifier("atk", AM.OperationType.ADD, 10.0, "buff_a")
	bag.add_modifier("atk", AM.OperationType.MULT, 2.0, "buff_b")
	# (5+10)*2 = 30
	if bag.get_value("atk") != 30.0:
		return "链式结算应为 30，得到 %s" % bag.get_value("atk")
	if bag.get_base("atk") != 5.0:
		return "base 不应被 modify 改"
	return true

func _test_bag_restore() -> Variant:
	var bag := TraitPropertyBag.new()
	bag.set_base("atk", 5.0)
	bag.add_modifier("atk", AM.OperationType.ADD, 10.0, "talent_x")
	if bag.get_value("atk") != 15.0:
		return "加修改源后应为 15"
	bag.remove_modifiers_by_source("talent_x")
	if bag.get_value("atk") != 5.0:
		return "移除来源后应还原为 5，得到 %s" % bag.get_value("atk")
	return true

func _test_bag_noop() -> Variant:
	var bag := TraitPropertyBag.new()
	# 未声明 LastHitDmgInc → 加修改源应 no-op（共享黑板语义）
	bag.add_modifier("LastHitDmgInc", AM.OperationType.MULT, 2.0, "trait_b")
	if bag.has("LastHitDmgInc"):
		return "未声明属性不应因 modify 而存在"
	if bag.get_value("LastHitDmgInc", -1.0) != -1.0:
		return "未声明属性应返回 default"
	return true

func _test_bag_decrement() -> Variant:
	var bag := TraitPropertyBag.new()
	bag.set_base("bounce_count", 3.0)
	if bag.decrement_base("bounce_count") != 2.0:
		return "递减应为 2"
	if bag.get_value("bounce_count") != 2.0:
		return "递减后 get 应为 2"
	return true
#endregion

#region Definition
func _test_definition_validate() -> Variant:
	var d := TraitDefinition.new()
	var errs := d.validate()
	var j := ", ".join(errs)
	if not j.contains("trait_id"):
		return "应报告 trait_id 空"
	if not j.contains("trait_flow"):
		return "应报告缺 trait_flow"
	# 修好
	d.trait_id = "t"
	d.trait_flow = FlowGraph.new()
	if not d.validate().is_empty():
		return "修复后应通过，仍有：%s" % ", ".join(d.validate())
	return true
#endregion

#region Container
# 探针特质叶子：记录 run 次数（trait graph 经解释器驱动）。
class ProbeLeaf extends FlowLeaf:
	static var hits := 0
	func run(_c, _h = null) -> void:
		ProbeLeaf.hits += 1

## FOREVER + Trigger(BULLET_HIT, NEVER) → ProbeLeaf 的特质 graph。
func _make_probe_graph() -> FlowGraph:
	var act := FlowGraph.leaf_action(ProbeLeaf.new())
	var trig := FlowGraph.trigger(int(GameplayEvent.EventType.BULLET_HIT), [act] as Array[FlowNode], FlowTrigger.EndMode.NEVER)
	return FlowGraph.single(FlowGraph.forever([trig] as Array[FlowNode]))

func _test_container_dispatch() -> Variant:
	ProbeLeaf.hits = 0
	var holder := RefCounted.new()
	var c := TraitContainer.new(holder)
	var def := TraitDefinition.new()
	def.trait_id = "probe"
	def.declared_properties = {"foo": 7.0}
	def.trait_flow = _make_probe_graph()
	def.listen_events = [int(GameplayEvent.EventType.BULLET_HIT)]
	c.add_trait(def)
	if not c.has_trait("probe"):
		return "add_trait 后应 has_trait"
	if c.get_property("foo") != 7.0:
		return "声明属性应灌进 bag，得到 %s" % c.get_property("foo")
	# 分发关心的事件 → 叶子收到
	c.dispatch(GameplayEvent.create(GameplayEvent.EventType.BULLET_HIT))
	# 分发不关心的事件 → 不收
	c.dispatch(GameplayEvent.create(GameplayEvent.EventType.BULLET_SPAWNED))
	if ProbeLeaf.hits != 1:
		return "只应转发关心的事件 1 次，得到 %d" % ProbeLeaf.hits
	return true
#endregion

#region Bounce flow
# stub 子弹：有 linear_velocity / rotation / bulletOwner
class StubBullet extends RefCounted:
	var linear_velocity := Vector2(100, 0)
	var rotation := 0.0
	var bulletOwner = null

func _make_bounce_setup(count: float) -> Dictionary:
	var holder := StubBullet.new()
	var c := TraitContainer.new(holder)
	# 手工造 def（headless -s 下不引用 autoload；逻辑等价 trait_bounce.tres）
	# 第十三期：trait_flow 是 FlowGraph(FOREVER + Trigger(BULLET_HIT,NEVER) → FlowLeaf_Bounce)。
	var leaf = load("res://src/gameplay/flows/graph/leaves/FlowLeaf_Bounce.gd").new()
	var act := FlowGraph.leaf_action(leaf)
	var trig := FlowGraph.trigger(int(GameplayEvent.EventType.BULLET_HIT), [act] as Array[FlowNode], FlowTrigger.EndMode.NEVER)
	var graph := FlowGraph.single(FlowGraph.forever([trig] as Array[FlowNode]))
	var def := TraitDefinition.new()
	def.trait_id = "trait_bounce"
	def.declared_properties = {"bounce_count": count}
	def.trait_flow = graph
	def.listen_events = [int(GameplayEvent.EventType.BULLET_HIT)]
	c.add_trait(def)
	return {"holder": holder, "c": c}

func _test_bounce_flow() -> Variant:
	var s := _make_bounce_setup(2.0)
	var c: TraitContainer = s.c
	var holder: StubBullet = s.holder
	var evt := GameplayEvent.create(GameplayEvent.EventType.BULLET_HIT)
	var r = c.dispatch(evt)
	if not r.veto_release:
		return "还能弹时应否决销毁"
	if c.get_property("bounce_count") != 1.0:
		return "弹一次后 bounce_count 应为 1，得到 %s" % c.get_property("bounce_count")
	if holder.linear_velocity.x != -100.0:
		return "应水平反射 vx，得到 %s" % holder.linear_velocity.x
	return true

func _test_bounce_exhausted() -> Variant:
	var s := _make_bounce_setup(0.0)
	var c: TraitContainer = s.c
	var evt := GameplayEvent.create(GameplayEvent.EventType.BULLET_HIT)
	var r = c.dispatch(evt)
	if r.veto_release:
		return "弹射耗尽时不应否决销毁（放行）"
	return true
#endregion
