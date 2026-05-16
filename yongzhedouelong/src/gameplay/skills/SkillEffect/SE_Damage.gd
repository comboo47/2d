class_name SE_Damage extends SkillEffectBase
## 伤害效果
## 直接对目标造成伤害（不通过子弹）

## 基础伤害值
@export var base_damage: float = 10.0

## 是否使用攻击力加成
@export var use_attack_bonus: bool = true

## 是否受护甲减免
@export var use_armor_reduction: bool = true

## 伤害倍率（乘以基础伤害）
@export var damage_multiplier: float = 1.0

## 执行伤害效果
func apply(context: GameplayFlowContext, skill: SkillBase) -> void:
	if context.target == null:
		return

	# 计算最终伤害
	var final_damage = _calculate_damage(context, skill)

	# 应用伤害
	var hp_attr = context.target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp)
	if hp_attr:
		hp_attr.sub(final_damage)

		# 显示伤害数字
		if UIManager.instance:
			UIManager.instance.show_damage(context.target, final_damage)

	# 触发命中特效
	if VfxManager.instance:
		VfxManager.instance.play_vfx(VfxConfig.VfxType.HIT_IMPACT, context.target.global_position)

## 计算伤害
func _calculate_damage(context: GameplayFlowContext, skill: SkillBase) -> float:
	var damage = base_damage * damage_multiplier

	# 攻击力加成
	if use_attack_bonus and skill.skill_owner:
		var atk_attr = skill.skill_owner.GetAttributes().find_attribute(AttributeConfig.AttributeName.Atk)
		if atk_attr:
			damage += atk_attr.computed_value

	# 护甲减免
	if use_armor_reduction and context.target:
		var armor_attr = context.target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Armor)
		if armor_attr:
			damage -= armor_attr.computed_value

	return max(0.0, damage)

func get_description() -> String:
	var desc = "造成 %.1f 伤害" % base_damage
	if damage_multiplier != 1.0:
		desc += " × %.1f" % damage_multiplier
	return desc