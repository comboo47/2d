class_name FlowDuration extends FlowNode
## 生命周期壳（第十三期）——flow 主线的串行单元。
## 一个 Duration 有自己的时长；内部 children 并行挂多个 Trigger/Action（支线并行）。
## 全部 Duration 跑完 = flow 结束。

enum LifetimeMode {
	INSTANT,   # 0 帧：进入即跑完直属 Action，无未结束 Trigger 则当帧推进
	FRAMES,    # 定长 N 帧
	SECONDS,   # 定长 N 秒
	FOREVER,   # 永久：靠内部 Trigger 的 finish_parent 推进，否则随宿主 cancel 才结束
}

@export var lifetime_mode: LifetimeMode = LifetimeMode.INSTANT
## FRAMES 时取整为帧数，SECONDS 时为秒数。
@export var lifetime_value: float = 0.0
## 并行子节点：FlowTrigger（持续监听）/ FlowAction（进入即跑的瞬时动作）。
@export var children: Array[FlowNode] = []
