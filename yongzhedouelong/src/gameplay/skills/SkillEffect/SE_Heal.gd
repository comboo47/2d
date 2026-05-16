class_name SE_Heal extends SkillEffectBase
## 治疗效果
## 对目标恢复生命值

## 基础治疗值
@export var base_heal: float = 20.0

## 治疗倍率
@export var heal_multiplier: float = 1.0

## 目标选择方式
enum HealTarget {
	SKILL_TARGET,   # 技能目标
	SELF,           # 自身
	ALL_ALLIES,     # 所有友方
}

@export var heal_target: HealTarget = HealTarget.SELF

## 最大目标数量（用于 ALL_ALLIES）
@export var max_targets: int = 5

## 执行治疗效果
func apply(context: GameplayFlowContext, skill: SkillBase) -> void:
	# 确定目标列表
	var targets = _select_targets(context, skill)

	# 对每个目标治疗
	for target in targets:
		_heal_target(target, skill)

## 选择目标
func _select_targets(context: GameplayFlowContext, skill: SkillBase) -> Array[BattleActor]:
	var targets: Array[BattleActor] = []

	match heal_target:
		HealTarget.SKILL_TARGET:
			if context.target:
				targets.append(context.target)

		HealTarget.SELF:
			if skill.skill_owner:
				targets.append(skill.skill_owner)

		HealTarget.ALL_ALLIES:
			targets = _find_all_allies(skill)
			if targets.size() > max_targets:
				targets = targets.slice(0, max_targets)

	return targets

## 查找所有友方
func _find_all_allies(skill: SkillBase) -> Array[BattleActor]:
	var targets: Array[BattleActor] = []

	if skill.skill_owner and skill.skill_owner.get_tree():
		var nodes = skill.skill_owner.get_tree().get_nodes_in_group("player")
		for node in nodes:
			if node is BattleActor:
				targets.append(node)

	return targets

## 治疗单个目标
func _heal_target(target: BattleActor, skill: SkillBase) -> void:
	var heal_amount = base_heal * heal_multiplier

	var hp_attr = target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp)
	if hp_attr:
		# 治疗是增加 HP
		hp_attr.add(heal_amount)

		# 显示治疗数字（绿色）
		if UIManager.instance:
			# 使用 show_damage 显示负数表示治疗
			UIManager.instance.show_damage(target, -heal_amount)

func get_description() -> String:
	var desc = "治疗 %.1f" % base_heal
	if heal_multiplier != 1.0:
		desc += " × %.1f" % heal_multiplier
	return desc