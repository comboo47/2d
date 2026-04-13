class_name SE_BuffApply extends SkillEffectBase
## Buff 应用效果
## 对目标应用指定的 Buff

## Buff ID（从 DataRegistry 获取）
@export var buff_id: String = ""

## 是否使用 source 作为 Buff 来源
@export var use_source_as_owner: bool = true

## Buff 持续时间覆盖（可选，-1 表示使用默认）
@export var duration_override: float = -1.0

## 目标选择方式
enum TargetSelection {
	SKILL_TARGET,      # 使用技能的目标
	SELF,              # 自身
	AREA_TARGETS,      # 区域内的目标（需配合 SE_AreaEffect）
	ALL_ENEMIES,       # 所有敌人
	ALL_ALLIES,        # 所有友方
}

@export var target_selection: TargetSelection = TargetSelection.SKILL_TARGET

## 区域半径（用于 AREA_TARGETS）
@export var selection_radius: float = 100.0

## 最大目标数量
@export var max_targets: int = 5

## 执行 Buff 应用
func apply(context: GameplayFlowContext, skill: SkillBase) -> void:
	if buff_id.is_empty():
		push_warning("SE_BuffApply: buff_id 为空")
		return

	# 确定目标列表
	var targets = _select_targets(context, skill)

	# 对每个目标应用 Buff
	for target in targets:
		var buff_source = skill.skill_owner if use_source_as_owner else null
		BattleManager.ApplyBuff(buff_source, target, buff_id)

## 选择目标
func _select_targets(context: GameplayFlowContext, skill: SkillBase) -> Array[BattleActor]:
	var targets: Array[BattleActor] = []

	match target_selection:
		TargetSelection.SKILL_TARGET:
			if context.target:
				targets.append(context.target)

		TargetSelection.SELF:
			if skill.skill_owner:
				targets.append(skill.skill_owner)

		TargetSelection.AREA_TARGETS:
			targets = _find_targets_in_area(context, skill)

		TargetSelection.ALL_ENEMIES:
			targets = _find_all_group("enemy", skill)

		TargetSelection.ALL_ALLIES:
			targets = _find_all_group("player", skill)

	# 限制最大数量
	if targets.size() > max_targets:
		targets = targets.slice(0, max_targets)

	return targets

## 查找区域内目标
func _find_targets_in_area(context: GameplayFlowContext, skill: SkillBase) -> Array[BattleActor]:
	var targets: Array[BattleActor] = []
	var center = context.get_position()

	var query_group = "enemy" if skill.target_type in [SkillConfig.TargetType.ENEMY_SINGLE, SkillConfig.TargetType.ENEMY_AREA] else "player"

	if skill.skill_owner and skill.skill_owner.get_tree():
		var potential = skill.skill_owner.get_tree().get_nodes_in_group(query_group)
		for p in potential:
			if p is BattleActor:
				if center.distance_to(p.global_position) <= selection_radius:
					targets.append(p)

	return targets

## 查找所有组成员
func _find_all_group(group_name: String, skill: SkillBase) -> Array[BattleActor]:
	var targets: Array[BattleActor] = []

	if skill.skill_owner and skill.skill_owner.get_tree():
		var nodes = skill.skill_owner.get_tree().get_nodes_in_group(group_name)
		for node in nodes:
			if node is BattleActor:
				targets.append(node)

	return targets

func get_description() -> String:
	if buff_id.is_empty():
		return "应用 Buff（未配置）"
	return "应用 Buff: %s" % buff_id