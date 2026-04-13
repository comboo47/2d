class_name FE_Damage extends FlowEffectBase
## 伤害效果
## 对目标造成伤害，支持属性加成和表达式计算

## 基础伤害值
@export var base_damage: float = 10.0

## 是否使用攻击力加成
@export var use_attack_bonus: bool = true

## 是否受护甲减免
@export var use_armor_reduction: bool = true

## 伤害表达式（可选，覆盖 base_damage）
## 可用变量: source, target, base_damage
@export var damage_expression: String = ""

## 缓存的表达式对象
var _cached_expression: Expression = null
var _expression_compiled: bool = false

## 执行伤害效果
func apply(context: GameplayFlowContext) -> void:
	if context.target == null:
		return

	# 计算最终伤害
	var final_damage = _calculate_damage(context)

	# 应用伤害到目标 HP
	var hp_attr = context.target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp)
	if hp_attr:
		hp_attr.sub(final_damage)
		# 更新上下文中的伤害值
		context.event_data["actual_damage"] = final_damage

		# 显示伤害数字
		if UIManager.instance:
			UIManager.instance.show_damage(context.target, final_damage)

## 计算伤害
func _calculate_damage(context: GameplayFlowContext) -> float:
	var damage = base_damage

	# 使用表达式计算（如果有）
	if not damage_expression.is_empty():
		damage = _evaluate_expression(context)

	# 攻击力加成
	if use_attack_bonus and context.source:
		var atk_attr = context.source.GetAttributes().find_attribute(AttributeConfig.AttributeName.Atk)
		if atk_attr:
			damage += atk_attr.computed_value

	# 护甲减免
	if use_armor_reduction and context.target:
		var armor_attr = context.target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Armor)
		if armor_attr:
			damage -= armor_attr.computed_value

	# 最小伤害为 0
	return max(0.0, damage)

## 编译并执行表达式
func _evaluate_expression(context: GameplayFlowContext) -> float:
	if not _expression_compiled:
		_cached_expression = Expression.new()
		var result = _cached_expression.parse(damage_expression, ["source", "target", "base_damage"])
		if result != OK:
			push_error("FE_Damage 表达式解析失败: %s" % _cached_expression.get_error_text())
			return base_damage
		_expression_compiled = true

	var expr_result = _cached_expression.execute([context.source, context.target, base_damage])
	if expr_result is float or expr_result is int:
		return float(expr_result)

	return base_damage

func get_description() -> String:
	var desc = "造成 %.1f 伤害" % base_damage
	if use_attack_bonus:
		desc += " + 攻击力"
	if use_armor_reduction:
		desc += " - 护甲"
	return desc