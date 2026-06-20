class_name StateEffect_Invincible extends StateEffect
## 示例状态效果：无敌。证明 StateEffect 生命周期闭环。
## 进入时在目标上打 "invincible" 标记，退出时清。DamageResolver/受击逻辑将来可查此标记。

func state_key() -> String:
	return "invincible"

func _on_state_enter(ctx: GameplayFlowContext, _count: int) -> void:
	ctx.target.set_meta("invincible", true)

func _on_state_exit(ctx: GameplayFlowContext) -> void:
	if ctx.target.has_meta("invincible"):
		ctx.target.remove_meta("invincible")

func get_description() -> String:
	return "无敌状态"
