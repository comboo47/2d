class_name StateEffect extends EffectBase
## 高维状态效果基类（无敌/隐身/视野修改等）。
## 与 ModifierEffect 区别：不改属性数值，而是设/清一个布尔或高维状态。
## apply 设状态、remove 还原。用 buff runtime_id 在目标上打标记，支持多 buff 叠加同状态。
##
## 第一版仅作抽象基类 + 一个示例子类 StateEffect_Invincible 证明生命周期闭环；
## 具体状态语义（如何让角色真的无敌/隐身）随各系统接入再实现。

## 状态键（target 上 meta 的命名空间，子类覆盖）。
func state_key() -> String:
	return "state_effect"

func apply(ctx: GameplayFlowContext, buff: AttributeBuff) -> void:
	if ctx == null or ctx.target == null or buff == null:
		return
	var holders := _holders(ctx)
	var sid := buff.get_runtime_id()
	if not holders.has(sid):
		holders.append(sid)
	ctx.target.set_meta(_meta_key(), holders)
	_on_state_enter(ctx, holders.size())

func remove(ctx: GameplayFlowContext, buff: AttributeBuff) -> void:
	if ctx == null or ctx.target == null or buff == null:
		return
	var holders := _holders(ctx)
	holders.erase(buff.get_runtime_id())
	ctx.target.set_meta(_meta_key(), holders)
	if holders.is_empty():
		_on_state_exit(ctx)
	else:
		_on_state_enter(ctx, holders.size())

## 当前是否处于该状态（任一 holder 存在）。
func is_active(ctx: GameplayFlowContext) -> bool:
	return not _holders(ctx).is_empty()

#region 子类钩子
## 状态生效（首次进入或叠加层数变化）。count = 当前持有该状态的 buff 数。
func _on_state_enter(_ctx: GameplayFlowContext, _count: int) -> void:
	pass

## 状态完全退出（最后一个 holder 移除）。
func _on_state_exit(_ctx: GameplayFlowContext) -> void:
	pass
#endregion

func _meta_key() -> String:
	return "_state_" + state_key()

func _holders(ctx: GameplayFlowContext) -> Array:
	if ctx.target.has_meta(_meta_key()):
		return ctx.target.get_meta(_meta_key())
	return []
