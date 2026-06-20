class_name FlowTrigger extends FlowNode
## 持续监听器（第十三期，替代裸 await）。监听某 GameplayEvent 类型，服从所属 Duration 生命周期。
## 触发后两个正交开关：① 执行 actions ② 是否 finish 所属 Duration（让主线往下走）。
## 结束语义 ONCE/COUNT/NEVER 表达"等一次/等N次/等多次（永不结束）"——非 while、非协程。

enum EndMode {
	ONCE,    # 触发一次即结束（最常见：等命中→上buff→结束）
	COUNT,   # 触发 N 次后结束
	NEVER,   # 永不结束（穿透弹：每次命中都上buff，直到 Duration 被 cancel）
}

## 监听的事件类型（GameplayEvent.EventType 的 int 值）。
@export var event_type: int = 0
@export var end_mode: EndMode = EndMode.ONCE
## COUNT 模式的次数。
@export var count: int = 1
## 触发时执行的动作（Action 子树，顺序执行）。
@export var actions: Array[FlowNode] = []
## 触发后是否 finish 所属 Duration（主线继续到下一个 Duration）。
@export var finish_parent: bool = false
## 可选过滤脚本（FlowLeaf 子类，run 返回 bool 决定本次事件是否算命中）。预留"只对特定 source 响应"等。
@export var filter_script: GDScript = null
