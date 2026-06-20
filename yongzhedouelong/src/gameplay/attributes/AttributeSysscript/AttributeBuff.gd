@tool
class_name AttributeBuff extends Resource

@export var id: String = ""
@export var name: String = ""
@export var buff_id: String = ""
@export var buff_Name: String = ""
@export var buff_name: String = ""
@export var buffDuration := 0.0
@export var buffPeriod := 0
@export var isLeaveReset := false
@export var duration: float = 0.0
@export var merging := DurationMerging.Restart
@export var stack: int = 1
@export var max_stack: int = 1

## 双轨：BuffFlow（轨道一，FlowGraph 节点树，随 buff apply 拉起、remove cancel，
## 由 buff 自身宿主经 FlowInterpreter 驱动）+ effects（轨道二，
## 选已定义的 EffectBase：ModifierEffect 改面板属性可逆 / StateEffect 高维状态）。
## 第十三期：buff_flow 从 GameplayFlowBase 改为 FlowGraph 节点树。
@export var buff_flow: FlowGraph = null
@export var effects: Array[EffectBase] = []

enum DurationMerging {
	Restart,
	Addtion,
	NoEffect,
}

var BuffSource: BattleActor = null
var BuffTarget: BattleActor = null
var remaining_time: float = 0.0
var is_pending_remove := false
var applied_attribute = null
var _tick_elapsed := 0.0

## BuffFlow 运行时解释器（buff 自身宿主，节点树经 FlowInterpreter 驱动）+ 其 context。
var _buff_interp: FlowInterpreter = null
var _buff_ctx: GameplayFlowContext = null

func write_all_children_data() -> void:
	pass

func Create(_source: BattleActor, _target: BattleActor) -> void:
	initialize_runtime(_source, _target)

func initialize_runtime(_source: BattleActor, _target: BattleActor) -> void:
	_normalize_legacy_fields()
	BuffSource = _source
	BuffTarget = _target
	remaining_time = get_runtime_duration()
	_tick_elapsed = 0.0
	is_pending_remove = false
	stack = clampi(stack, 1, max(1, max_stack))

func deep_duplicate(_source: BattleActor, _target: BattleActor) -> AttributeBuff:
	var duplicated_buff := duplicate(true) as AttributeBuff
	duplicated_buff.initialize_runtime(_source, _target)
	return duplicated_buff

func run_process(delta: float) -> Array[GameplayEvent]:
	var events: Array[GameplayEvent] = []
	if is_pending_remove:
		return events

	var active_duration := get_runtime_duration()
	if active_duration > 0.0:
		remaining_time = max(remaining_time - delta, 0.0)
		if is_zero_approx(remaining_time):
			is_pending_remove = true

	# 驱动 BuffFlow 解释器每帧推进
	if _buff_interp:
		_buff_interp.advance(delta)

	if buffPeriod > 0:
		_tick_elapsed += delta
		while _tick_elapsed >= float(buffPeriod):
			_tick_elapsed -= float(buffPeriod)
			# 周期到点：产出 BUFF_TICK 事件；BuffManager 会经 handle_gameplay_event 转给 buff_flow.on_event。
			events.append(_make_event(GameplayEvent.EventType.BUFF_TICK))

	return events

#region 第八期：双轨生命周期驱动（由 BuffManager 在 apply/remove 时调用）
## buff 应用时：拉起 BuffFlow + 生效所有 effects。
func on_applied() -> void:
	_buff_ctx = _make_ctx()
	if buff_flow:
		_buff_interp = FlowInterpreter.new()
		_buff_interp.start(buff_flow.deep_duplicate(), _buff_ctx, BuffTarget)
	for eff in effects:
		if eff:
			eff.apply(_buff_ctx, self)

## buff 移除时：cancel BuffFlow + 逆序还原所有 effects。
func on_removed() -> void:
	if _buff_ctx == null:
		_buff_ctx = _make_ctx()
	for i in range(effects.size() - 1, -1, -1):
		if effects[i]:
			effects[i].remove(_buff_ctx, self)
	if _buff_interp:
		_buff_interp.cancel()
		_buff_interp = null

func _make_ctx() -> GameplayFlowContext:
	var ctx := GameplayFlowContext.new()
	ctx.source = BuffSource
	ctx.target = BuffTarget
	ctx.buff = self
	ctx.stack = stack
	return ctx
#endregion

## 第八期：总线/生命周期事件转发给 BuffFlow（替代旧 event_flows 字典）。
## BuffManager 把与本 buff source/target 相关的事件、以及 BUFF_APPLIED/REMOVED/TICK 转到这里。
func handle_gameplay_event(event: GameplayEvent) -> void:
	if event == null or is_pending_remove:
		return
	if _buff_interp == null:
		return
	if _buff_ctx == null:
		_buff_ctx = _make_ctx()
	_buff_ctx.stack = stack
	_buff_interp.deliver_event(event)

func emit_lifecycle_event(type: GameplayEvent.EventType) -> void:
	var event := _make_event(type)
	GameplayEventBus.emit_event(event)
	handle_gameplay_event(event)

func add_stack(amount: int) -> void:
	var old_stack := stack
	stack = clampi(stack + amount, 1, max(1, max_stack))
	if stack != old_stack:
		emit_lifecycle_event(GameplayEvent.EventType.BUFF_STACK_CHANGED)

func restart_duration() -> void:
	remaining_time = get_runtime_duration()

func extend_duration(time: float) -> void:
	remaining_time += time

func set_merging(_merging: DurationMerging) -> void:
	merging = _merging

func set_duration(time: float) -> AttributeBuff:
	duration = time
	buffDuration = time
	remaining_time = time
	return self

func _make_event(type: GameplayEvent.EventType) -> GameplayEvent:
	var event := GameplayEvent.create(type, BuffSource, BuffTarget)
	event.buff = self
	event.event_data["buff_id"] = get_runtime_id()
	event.event_data["stack"] = stack
	return event

func get_runtime_id() -> String:
	return buff_id if not buff_id.is_empty() else id

func get_runtime_name() -> String:
	if not buff_name.is_empty():
		return buff_name
	if not buff_Name.is_empty():
		return buff_Name
	return name

func get_runtime_duration() -> float:
	return duration if duration > 0.0 else buffDuration

func _normalize_legacy_fields() -> void:
	if buff_id.is_empty():
		buff_id = id
	if id.is_empty():
		id = buff_id
	if buff_name.is_empty():
		buff_name = buff_Name if not buff_Name.is_empty() else name
	if buff_Name.is_empty():
		buff_Name = buff_name
	if name.is_empty():
		name = buff_name
	if duration <= 0.0 and buffDuration > 0.0:
		duration = buffDuration
	if buffDuration <= 0.0 and duration > 0.0:
		buffDuration = duration
