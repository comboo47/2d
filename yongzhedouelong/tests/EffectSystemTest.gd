extends SceneTree
## 第八期 Effect 体系 + Flow 动作库 + Attribute 修改源栈回归测试。
## 运行：godot --headless --path . -s res://tests/EffectSystemTest.gd

var _failures := 0
var _nodes: Array[Node] = []

func _initialize() -> void:
	_run("attribute_modifier_source_reversible", _test_attr_source_reversible)
	_run("attribute_modifier_source_stacks", _test_attr_source_stacks)
	_run("modifier_effect_apply_remove_roundtrip", _test_modifier_effect_roundtrip)
	_run("state_effect_lifecycle", _test_state_effect_lifecycle)
	_run("flow_actions_spread_directions", _test_flow_actions_spread)
	_run("flow_actions_deal_damage_via_resolver", _test_flow_actions_deal_damage)
	_run("buff_with_modifier_effect_applies_and_reverts", _test_buff_modifier_effect)
	_run("buff_flow_lifecycle", _test_buff_flow_lifecycle)
	quit(_failures)

func _run(name: String, c: Callable) -> void:
	var r = c.call()
	if r is bool and r == true:
		print("PASS ", name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [name, str(r)])
	_cleanup()

#region Attribute 修改源栈
func _test_attr_source_reversible() -> Variant:
	var attr := _make_attr(AttributeConfig.AttributeName.Atk, 10.0)
	attr.add_modifier_source("buff_a", AttributeModifier.OperationType.ADD, 5.0)
	if not is_equal_approx(attr.get_value(), 15.0):
		return "加源后应为 15，得到 %s" % attr.get_value()
	attr.remove_modifier_source("buff_a")
	if not is_equal_approx(attr.get_value(), 10.0):
		return "移除源后应还原 10，得到 %s" % attr.get_value()
	if not is_equal_approx(attr.base_value, 10.0):
		return "base 不应被改"
	return true

func _test_attr_source_stacks() -> Variant:
	var attr := _make_attr(AttributeConfig.AttributeName.Atk, 10.0)
	attr.add_modifier_source("a", AttributeModifier.OperationType.ADD, 5.0)
	attr.add_modifier_source("b", AttributeModifier.OperationType.MULT, 2.0)
	# (10+5)*2 = 30
	if not is_equal_approx(attr.get_value(), 30.0):
		return "链式应为 30，得到 %s" % attr.get_value()
	attr.remove_modifier_source("a")
	# 10*2 = 20
	if not is_equal_approx(attr.get_value(), 20.0):
		return "移除 a 后应为 20，得到 %s" % attr.get_value()
	return true
#endregion

#region ModifierEffect
func _test_modifier_effect_roundtrip() -> Variant:
	var target := _make_actor(0.0, 10.0, 0.0)
	var buff := AttributeBuff.new()
	buff.buff_id = "atk_up"
	var eff := ModifierEffect.new()
	eff.attribute_type = AttributeConfig.AttributeName.Atk
	eff.operation = AttributeModifier.OperationType.ADD
	eff.value = 7.0
	var ctx := GameplayFlowContext.new()
	ctx.target = target
	ctx.buff = buff

	eff.apply(ctx, buff)
	var atk := target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Atk)
	if not is_equal_approx(atk.get_value(), 17.0):
		return "apply 后 atk 应为 17，得到 %s" % atk.get_value()
	eff.remove(ctx, buff)
	if not is_equal_approx(atk.get_value(), 10.0):
		return "remove 后 atk 应还原 10，得到 %s" % atk.get_value()
	return true
#endregion

#region StateEffect
func _test_state_effect_lifecycle() -> Variant:
	var target := _make_actor(10.0, 0.0, 0.0)
	var buff := AttributeBuff.new()
	buff.buff_id = "inv"
	var eff := StateEffect_Invincible.new()
	var ctx := GameplayFlowContext.new()
	ctx.target = target
	ctx.buff = buff

	eff.apply(ctx, buff)
	if not target.has_meta("invincible") or not target.get_meta("invincible"):
		return "apply 后应设无敌标记"
	if not eff.is_active(ctx):
		return "apply 后 is_active 应为 true"
	eff.remove(ctx, buff)
	if target.has_meta("invincible"):
		return "remove 后应清无敌标记"
	if eff.is_active(ctx):
		return "remove 后 is_active 应为 false"
	return true
#endregion

#region FlowActions
func _test_flow_actions_spread() -> Variant:
	# 单发
	var one := FlowActions._spread_directions(Vector2.RIGHT, 1, 0.0)
	if one.size() != 1:
		return "spread_count=1 应返回 1 个方向"
	# 3 发散射
	var three := FlowActions._spread_directions(Vector2.RIGHT, 3, PI / 2.0)
	if three.size() != 3:
		return "spread_count=3 应返回 3 个方向，得到 %d" % three.size()
	# 中间一发应接近原方向
	if not three[1].is_equal_approx(Vector2.RIGHT):
		return "3 发散射中间一发应为原方向"
	return true

func _test_flow_actions_deal_damage() -> Variant:
	GameplayEventBus.clear_history()
	var source := _make_actor(0.0, 0.0, 0.0)
	var target := _make_actor(50.0, 0.0, 0.0)
	var ctx := GameplayFlowContext.new()
	ctx.source = source
	ctx.target = target
	var result = FlowActions.deal_damage(ctx, {"base": 12.0, "use_atk": false, "use_armor": false})
	if result == null:
		return "deal_damage 应返回 DamageResult"
	var hp := target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp)
	if not is_equal_approx(hp.get_value(), 38.0):
		return "12 伤害后 hp 应为 38，得到 %s" % hp.get_value()
	var found := false
	for e in GameplayEventBus.emitted_events:
		if e.event_type == GameplayEvent.EventType.DAMAGE_APPLIED:
			found = true
	if not found:
		return "deal_damage 应经 DamageResolver 发 DAMAGE_APPLIED"
	return true
#endregion

#region Buff 双轨
func _test_buff_modifier_effect() -> Variant:
	var target := _make_actor(0.0, 10.0, 0.0)
	var buff := AttributeBuff.new()
	buff.buff_id = "atk_buff"
	buff.duration = 2.0
	var eff := ModifierEffect.new()
	eff.attribute_type = AttributeConfig.AttributeName.Atk
	eff.operation = AttributeModifier.OperationType.ADD
	eff.value = 5.0
	buff.effects = [eff]

	var runtime: AttributeBuff = target.buffManager.apply_buff(buff, target, target)
	var atk := target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Atk)
	if not is_equal_approx(atk.get_value(), 15.0):
		return "apply 后 atk 应为 15，得到 %s" % atk.get_value()
	target.buffManager.remove_buff(runtime)
	if not is_equal_approx(atk.get_value(), 10.0):
		return "remove 后 atk 应还原 10，得到 %s" % atk.get_value()
	return true

func _test_buff_flow_lifecycle() -> Variant:
	# 第十三期：buff_flow 是 FlowGraph，经 _buff_interp 驱动。
	# 用 FOREVER + Trigger(BUFF_TICK,NEVER)→deal_damage 验证：period 到点→事件投递→掉血。
	var target := _make_actor(20.0, 0.0, 0.0)
	var buff := AttributeBuff.new()
	buff.buff_id = "flow_buff"
	buff.duration = 5.0
	buff.buffPeriod = 1
	var dmg := FlowGraph.action("deal_damage", {"base": 3.0, "use_atk": false, "use_armor": false})
	var trig := FlowGraph.trigger(int(GameplayEvent.EventType.BUFF_TICK), [dmg] as Array[FlowNode], FlowTrigger.EndMode.NEVER)
	buff.buff_flow = FlowGraph.single(FlowGraph.forever([trig] as Array[FlowNode]))

	var runtime: AttributeBuff = target.buffManager.apply_buff(buff, target, target)
	if runtime._buff_interp == null:
		return "apply 后应拉起 buff_flow 解释器"
	# 推进 1.1s → 一次 BUFF_TICK 事件（经 handle_gameplay_event 转 deliver_event → deal_damage 3）
	var events := runtime.run_process(1.1)
	for e in events:
		runtime.handle_gameplay_event(e)
	var hp := target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp)
	if not is_equal_approx(hp.get_value(), 17.0):
		return "period 到点应经 buff_flow 掉 3 血→17，得到 %s" % hp.get_value()
	target.buffManager.remove_buff(runtime)
	if runtime._buff_interp != null:
		return "remove 后 buff_flow 解释器应被 cancel 清空"
	return true
#endregion

#region helpers
func _make_attr(attribute_name: AttributeConfig.AttributeName, value: float) -> Attribute:
	var attr := Attribute.new()
	attr.attribute_name = attribute_name
	attr.base_value = value
	return attr

func _make_actor(hp: float, atk: float, armor: float) -> BattleActor:
	var actor := BattleActor.new()
	var component := AttributeComponent.new()
	var set := AttributeSet.new()
	set.attributes = [
		_make_attr(AttributeConfig.AttributeName.Hp, hp),
		_make_attr(AttributeConfig.AttributeName.Atk, atk),
		_make_attr(AttributeConfig.AttributeName.Armor, armor),
		_make_attr(AttributeConfig.AttributeName.Mana, 0.0),
		_make_attr(AttributeConfig.AttributeName.Crit, 0.0),
	]
	component.attribute_set = set
	actor.add_child(component)
	actor.SetAttributes(component)
	get_root().add_child(actor)
	_nodes.append(actor)
	return actor

func _cleanup() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()
#endregion
