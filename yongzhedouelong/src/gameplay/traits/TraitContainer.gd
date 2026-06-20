class_name TraitContainer extends RefCounted
## 特质容器（每个 holder 一个，第一版挂在子弹上）。
## 职责：持有 holder 的活跃特质（flow 实例 + ctx）+ 一个 TraitPropertyBag；
## 把 holder 的生命周期事件分发给关心该事件的特质 flow（on_event）。
##
## 关键：特质事件【子弹自管，不走 FlowRuntime/GameplayEventBus 全局总线】——
## 子弹量大短命、命中是子弹私有事件、容器随子弹生死，零泄漏。
## （actor 等 holder 若需响应全局事件，在其接入时另行注册，见 memory: trait-system-holder-event-registration）

## 特质事件分发结果（在 dispatch 时塞进 event.event_data["trait_result"]，flow 可写回）。
class TraitDispatchResult extends RefCounted:
	var veto_release: bool = false   # 特质要求"此次命中后不销毁子弹"
	var handled: bool = false        # 是否有特质处理了本事件

var _holder_ref: WeakRef = null
var bag: TraitPropertyBag = null
## 活跃特质：[{def: TraitDefinition, interp: FlowInterpreter, ctx: GameplayFlowContext}]
## 第十三期：flow 实例 → FlowInterpreter（trait_flow 是 FlowGraph 节点树）。
var _active: Array = []

func _init(holder: Object) -> void:
	_holder_ref = weakref(holder)
	bag = TraitPropertyBag.new()

func get_holder() -> Object:
	return _holder_ref.get_ref() if _holder_ref else null

#region 增删查
## 加一个特质：灌声明属性进 bag → start FlowInterpreter（trait_flow 节点树 deep_duplicate）。
func add_trait(def: TraitDefinition, ctx: GameplayFlowContext = null) -> bool:
	if def == null:
		return false
	# 1) 声明属性灌进 bag（已存在则不覆盖，保留先到的——共享黑板语义）
	for key in def.declared_properties:
		if not bag.has(key):
			bag.set_base(key, float(def.declared_properties[key]))
	# 2) ctx 默认以 holder 为 source（子弹则 source=bulletOwner）
	if ctx == null:
		ctx = _make_default_ctx()
	# 3) trait_flow 独立解释器（节点树 deep_duplicate）
	var interp: FlowInterpreter = null
	if def.trait_flow != null:
		interp = FlowInterpreter.new()
		interp.start(def.trait_flow.deep_duplicate(), ctx, get_holder())
	_active.append({"def": def, "interp": interp, "ctx": ctx})
	return true

## 按 id 从注册表取特质并加（供 buff 投放渠道/天赋用）。
func add_trait_by_id(trait_id: String, ctx: GameplayFlowContext = null) -> bool:
	var reg = Engine.get_main_loop().root.get_node_or_null("TraitRegistry") if Engine.get_main_loop() else null
	if reg == null:
		return false
	var def: TraitDefinition = reg.get_trait(trait_id)
	return add_trait(def, ctx) if def != null else false

## 移除某特质（cancel 解释器 + 移除其声明属性的修改源——按 trait_id 作 source）。
func remove_trait(trait_id: String) -> bool:
	for i in range(_active.size() - 1, -1, -1):
		var entry = _active[i]
		if entry.def != null and entry.def.trait_id == trait_id:
			if entry.interp != null:
				entry.interp.cancel()
			_active.remove_at(i)
			return true
	return false

func has_trait(trait_id: String) -> bool:
	for entry in _active:
		if entry.def != null and entry.def.trait_id == trait_id:
			return true
	return false

func is_empty() -> bool:
	return _active.is_empty()
#endregion

#region 属性转发
func get_property(name: String, default: float = 0.0) -> float:
	return bag.get_value(name, default)

func modify_property(name: String, op: int, value: float, source_id: String = "") -> void:
	bag.add_modifier(name, op, value, source_id)
#endregion

#region 事件分发 / tick
## 分发一个事件给关心它的特质 flow。返回 TraitDispatchResult（收集 veto 等）。
func dispatch(event: GameplayEvent) -> TraitDispatchResult:
	var result := TraitDispatchResult.new()
	# 把运行期对象塞进 event_data，供 flow 通过 ctx.gameplay_event 或 event 访问
	event.event_data["trait_result"] = result
	event.event_data["trait_bag"] = bag
	event.event_data["trait_holder"] = get_holder()
	var type_int := int(event.event_type)
	for entry in _active:
		if entry.interp == null or entry.def == null:
			continue
		if entry.def.listen_events.has(type_int):
			result.handled = true
			entry.ctx.gameplay_event = event
			entry.interp.deliver_event(event)
	return result

## 每帧推进特质解释器（定长 Duration 等用；弹射靠事件不依赖此）。
func tick(delta: float) -> void:
	for entry in _active:
		if entry.interp != null:
			entry.interp.advance(delta)

## 全部特质 cancel（holder 销毁时调）。
func stop_all() -> void:
	for entry in _active:
		if entry.interp != null:
			entry.interp.cancel()
	_active.clear()
#endregion

func _make_default_ctx() -> GameplayFlowContext:
	var ctx := GameplayFlowContext.new()
	var holder = get_holder()
	# 子弹 holder：source = bulletOwner（若有）
	if holder != null and "bulletOwner" in holder:
		ctx.source = holder.bulletOwner
	return ctx
