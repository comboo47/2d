class_name ModifierEffect extends EffectBase
## 数值修改效果（面板属性，可叠加可逆）。
## apply 时给目标的面板属性压一个带 buff runtime_id 的修改源；remove 时按 id 弹出还原。
## 复用 Attribute 的修改源栈（add_modifier_source/remove_modifier_source）+ AttributeModifier 的运算。
## 仅用于面板属性（攻击/护甲/最大HP/暴击）；资源值（HP/能量）的增减走 flow 动作库即时改。

## 目标属性
@export var attribute_type: AttributeConfig.AttributeName = AttributeConfig.AttributeName.Atk

## 运算类型（复用 AttributeModifier 的 6 种）
@export var operation: AttributeModifier.OperationType = AttributeModifier.OperationType.ADD

## 运算值
@export var value: float = 0.0

func apply(ctx: GameplayFlowContext, buff: AttributeBuff) -> void:
	var attr := _find_attr(ctx)
	if attr == null or buff == null:
		return
	attr.add_modifier_source(buff.get_runtime_id(), operation, value)

func remove(ctx: GameplayFlowContext, buff: AttributeBuff) -> void:
	var attr := _find_attr(ctx)
	if attr == null or buff == null:
		return
	attr.remove_modifier_source(buff.get_runtime_id())

func _find_attr(ctx: GameplayFlowContext) -> Attribute:
	if ctx == null or ctx.target == null:
		return null
	var comp = ctx.target.GetAttributes()
	if comp == null:
		return null
	return comp.find_attribute(attribute_type)

func get_description() -> String:
	var attr_name = AttributeConfig.AttributeName.keys()[attribute_type]
	var op_name = AttributeModifier.OperationType.keys()[operation]
	return "面板属性 %s %s %.1f（可逆）" % [attr_name, op_name, value]
