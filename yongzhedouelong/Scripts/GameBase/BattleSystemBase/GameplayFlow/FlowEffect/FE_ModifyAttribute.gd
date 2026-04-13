class_name FE_ModifyAttribute extends FlowEffectBase
## 修改属性效果
## 直接修改目标的属性值

## 目标属性类型
@export var attribute_type: AttributeConfig.AttributeName = AttributeConfig.AttributeName.Hp

## 操作类型
enum ModifyOperation {
	ADD,      # 增加值
	SUB,      # 减少值
	SET,      # 设置为固定值
	MULTIPLY, # 乘以系数
}

@export var operation: ModifyOperation = ModifyOperation.ADD

## 操作值
@export var value: float = 10.0

## 执行属性修改
func apply(context: GameplayFlowContext) -> void:
	if context.target == null:
		push_warning("FE_ModifyAttribute: 目标为空")
		return

	var attr_comp = context.target.GetAttributes()
	if attr_comp == null:
		push_warning("FE_ModifyAttribute: 目标没有 AttributeComponent")
		return

	var attr = attr_comp.find_attribute(attribute_type)
	if attr == null:
		push_warning("FE_ModifyAttribute: 未找到属性 %s" % AttributeConfig.AttributeName.keys()[attribute_type])
		return

	# 根据操作类型修改属性
	match operation:
		ModifyOperation.ADD:
			attr.add(value)
		ModifyOperation.SUB:
			attr.sub(value)
		ModifyOperation.SET:
			attr.set_value(value)
		ModifyOperation.MULTIPLY:
			# MULTIPLY 需要特殊处理，Attribute 可能没有 multiply 方法
			var current = attr.computed_value
			attr.set_value(current * value)

func get_description() -> String:
	var attr_name = AttributeConfig.AttributeName.keys()[attribute_type]
	var op_name = ModifyOperation.keys()[operation]
	return "属性 %s %s %.1f" % [attr_name, op_name, value]