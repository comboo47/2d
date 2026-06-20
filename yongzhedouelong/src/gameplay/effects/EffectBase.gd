class_name EffectBase extends Resource
## 效果基类（第八期，推倒重写，只挂 buff）。
## buff 的 effects 列表持有一组 EffectBase；buff apply 时调 apply()、remove 时调 remove()。
## 与 flow 正交：flow 管 gameplay 编排（动作库），effect 管「挂在 buff 上、随 buff 生灭」的逻辑承载。
##
## 子类：ModifierEffect（面板属性可逆数值修改）、StateEffect（无敌/隐身/视野等高维状态）。
## source/target/buff 全走传入的 ctx + buff 参数；不用 Expression（旧 E_* 表达式驱动已废弃，
## 需要公式走 flow 动作库 deal_damage 的 formula）。

## buff 应用时调用。子类重写实现生效逻辑。
func apply(_ctx: GameplayFlowContext, _buff: AttributeBuff) -> void:
	pass

## buff 移除时调用。子类重写实现还原逻辑（与 apply 对称）。
func remove(_ctx: GameplayFlowContext, _buff: AttributeBuff) -> void:
	pass

func get_description() -> String:
	return "Effect"
