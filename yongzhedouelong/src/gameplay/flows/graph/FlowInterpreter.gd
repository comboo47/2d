class_name FlowInterpreter extends RefCounted
## Flow 节点树运行时解释器（第十三期，取代 FlowRuntime）。
## per-instance：每个宿主（buff/skill/actor/trait/level）new 一个并持有，生命周期严绑宿主。
## 不进场景树（RefCounted）、不订阅总线——宿主代为喂帧（advance）/喂事件（deliver_event），
## 宿主死→cancel（确定性同步清理，替代杀不掉的协程 await）。
##
## 主线：durations 串行推进（_cursor）。进入一个 Duration 即跑其直属 Action + 建 Trigger 监听态；
## Duration 到期（定长）或被 Trigger finish_parent → 推进游标；越界 → _finished。

var graph: FlowGraph = null
var context: GameplayFlowContext = null
var _host = null

var _cursor: int = -1
var _active: FlowDuration = null
var _elapsed: float = 0.0          # 当前 Duration 已推进（FRAMES：帧数；SECONDS：秒）
## 当前 Duration 活跃 Trigger 运行态：[{trigger: FlowTrigger, fired: int, ended: bool}]
var _trigger_states: Array = []
var _finished: bool = false
var _finish_requested: bool = false

#region 公共 API
func start(g: FlowGraph, ctx: GameplayFlowContext, host = null) -> void:
	graph = g
	context = ctx
	_host = host
	_cursor = -1
	_finished = false
	if g == null or g.durations.is_empty():
		_finished = true
		return
	_advance_cursor()

## 每帧推进当前 Duration（宿主调）。
func advance(delta: float) -> void:
	if _finished or _active == null:
		return
	match _active.lifetime_mode:
		FlowDuration.LifetimeMode.FRAMES:
			_elapsed += 1.0
		FlowDuration.LifetimeMode.SECONDS:
			_elapsed += delta
		_:
			pass
	# 到期判定：INSTANT 已在 enter 处理；定长看 _elapsed；FOREVER 永不自然到期
	var expired := false
	match _active.lifetime_mode:
		FlowDuration.LifetimeMode.FRAMES:
			expired = _elapsed >= _active.lifetime_value
		FlowDuration.LifetimeMode.SECONDS:
			expired = _elapsed >= _active.lifetime_value
	if _finish_requested or expired:
		_advance_cursor()

## 分发事件给当前 Duration 未结束的匹配 Trigger（宿主桥接总线/私有事件到这里）。
func deliver_event(event: GameplayEvent) -> void:
	if _finished or event == null:
		return
	var type_int := int(event.event_type)
	for st in _trigger_states:
		if st.ended:
			continue
		var trig: FlowTrigger = st.trigger
		if trig.event_type != type_int:
			continue
		# 可选过滤
		if trig.filter_script != null:
			var f = trig.filter_script.new()
			if f.has_method("run") and not f.run(context, _host):
				continue
		# 触发：执行 actions
		context.gameplay_event = event
		for a in trig.actions:
			_run_action(a)
		st.fired += 1
		# 结束语义
		match trig.end_mode:
			FlowTrigger.EndMode.ONCE:
				st.ended = true
			FlowTrigger.EndMode.COUNT:
				if st.fired >= trig.count:
					st.ended = true
			FlowTrigger.EndMode.NEVER:
				pass
		if trig.finish_parent:
			_finish_requested = true
	if _finish_requested:
		_advance_cursor()

## 确定性清理（宿主死/移除调）。同步、非协程——无泄漏窗口。
func cancel() -> void:
	_finished = true
	_trigger_states.clear()
	_active = null

func is_finished() -> bool:
	return _finished

## 一次性把 graph 跑到 finished（INSTANT 动作链）。供 skill/level/actor 旧 string-id 等
## 「一次性 flow」宿主复用。含迭代守卫——误配 FOREVER/SECONDS（不靠 delta 结束）时不死循环。
static func run_oneshot(g: FlowGraph, ctx: GameplayFlowContext, host = null) -> void:
	if g == null:
		return
	var it := FlowInterpreter.new()
	it.start(g.deep_duplicate(), ctx, host)
	var guard := 0
	while not it.is_finished() and guard < 256:
		it.advance(0.0)
		guard += 1
	if not it.is_finished():
		push_warning("FlowInterpreter.run_oneshot: graph '%s' 未在 256 次推进内结束（误配 FOREVER/SECONDS？一次性 flow 应全 INSTANT）" % g.flow_id)

func active_trigger_count() -> int:
	var n := 0
	for st in _trigger_states:
		if not st.ended:
			n += 1
	return n
#endregion

#region 内部
func _advance_cursor() -> void:
	_cursor += 1
	if graph == null or _cursor >= graph.durations.size():
		_finished = true
		_active = null
		_trigger_states.clear()
		return
	_enter_duration(graph.durations[_cursor])

func _enter_duration(d: FlowDuration) -> void:
	_active = d
	_elapsed = 0.0
	_finish_requested = false
	_trigger_states.clear()
	# 建 Trigger 监听态 + 进入即跑直属 Action
	for child in d.children:
		if child is FlowTrigger:
			_trigger_states.append({"trigger": child, "fired": 0, "ended": false})
		elif child is FlowAction:
			_run_action(child)
	# INSTANT：无未结束 Trigger 则当帧推进
	if d.lifetime_mode == FlowDuration.LifetimeMode.INSTANT and active_trigger_count() == 0:
		_advance_cursor()

func _run_action(node: FlowNode) -> void:
	if not (node is FlowAction):
		return
	var act: FlowAction = node
	# 脚本叶子优先
	if act.leaf != null:
		act.leaf.run(context, _host)
		return
	match act.action_name:
		"fire_projectile": FlowActions.fire_projectile(context, act.opts)
		"deal_damage": FlowActions.deal_damage(context, act.opts)
		"modify_attr": FlowActions.modify_attr(context, act.opts)
		"apply_buff":
			var target = act.buff_res if act.buff_res != null else act.opts.get("buff_id", "")
			FlowActions.apply_buff(context, target, act.opts)
		"spawn_entity": FlowActions.spawn_entity(context, act.opts)
		"play_vfx": FlowActions.play_vfx(context, act.opts)
		"finish": FlowActions.finish(context)
		_:
			if not act.action_name.is_empty():
				push_warning("FlowInterpreter: 未知 action_name '%s'" % act.action_name)
#endregion
