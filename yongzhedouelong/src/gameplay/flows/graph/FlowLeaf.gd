class_name FlowLeaf extends Resource
## 脚本叶子基类（第十三期）。节点树表达"流程结构"，带具体计算的逻辑（如 BowShot 的
## speed=lerp(base,max,charge_ratio)）放在脚本叶子里——行为树通行做法。
## 子类重写 run()，内部可调 FlowActions.* 静态库（无状态，直接复用）。

## 执行叶子逻辑。host 是宿主（actor/子弹等，可空），供需要时用。
func run(_ctx: GameplayFlowContext, _host = null) -> void:
	pass
