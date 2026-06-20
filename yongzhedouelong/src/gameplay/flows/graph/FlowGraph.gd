class_name FlowGraph extends Resource
## Flow 节点树根容器（第十三期，取代 GameplayFlowBase 作为 flow 的资源载体）。
## Flow = 一串 Duration（主线串行）。由各宿主持有，经 FlowInterpreter 驱动。

@export var flow_id: String = ""
@export var flow_name: String = ""
## 主线：Duration 序列，解释器逐个推进，全部跑完 = flow 结束。
@export var durations: Array[FlowDuration] = []

## 深拷贝（宿主装备/施放时取独立实例，禁止写回共享 .tres）。
func deep_duplicate() -> FlowGraph:
	return duplicate(true) as FlowGraph

#region 流式拼装助手（脚本侧构建 graph 更可读）
## 单 Duration 的 graph（最常见：一串 INSTANT 动作）。
static func single(duration: FlowDuration, id: String = "") -> FlowGraph:
	var g := FlowGraph.new()
	g.flow_id = id
	g.durations = [duration]
	return g

## INSTANT Duration（进入即跑完 actions）。
static func instant(actions: Array[FlowNode]) -> FlowDuration:
	var d := FlowDuration.new()
	d.lifetime_mode = FlowDuration.LifetimeMode.INSTANT
	d.children = actions
	return d

## 定长 Duration（秒）。
static func seconds(value: float, children: Array[FlowNode] = []) -> FlowDuration:
	var d := FlowDuration.new()
	d.lifetime_mode = FlowDuration.LifetimeMode.SECONDS
	d.lifetime_value = value
	d.children = children
	return d

## 永久 Duration（挂 Trigger 监听，靠 finish_parent 或宿主 cancel 结束）。
static func forever(children: Array[FlowNode] = []) -> FlowDuration:
	var d := FlowDuration.new()
	d.lifetime_mode = FlowDuration.LifetimeMode.FOREVER
	d.children = children
	return d

## 数据 Action。
static func action(name: String, opts: Dictionary = {}) -> FlowAction:
	var a := FlowAction.new()
	a.action_name = name
	a.opts = opts
	return a

## 脚本叶子 Action。
static func leaf_action(leaf: FlowLeaf) -> FlowAction:
	var a := FlowAction.new()
	a.leaf = leaf
	return a

## Trigger。
static func trigger(event_type: int, actions: Array[FlowNode], end_mode: FlowTrigger.EndMode = FlowTrigger.EndMode.ONCE, finish_parent: bool = false, count: int = 1) -> FlowTrigger:
	var t := FlowTrigger.new()
	t.event_type = event_type
	t.actions = actions
	t.end_mode = end_mode
	t.finish_parent = finish_parent
	t.count = count
	return t
#endregion
