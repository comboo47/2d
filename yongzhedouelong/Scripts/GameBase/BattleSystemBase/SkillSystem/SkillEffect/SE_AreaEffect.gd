class_name SE_AreaEffect extends SkillEffectBase
## 区域效果
## 在指定位置创建区域，对区域内目标产生影响

## 区域半径
@export var area_radius: float = 100.0

## 区域持续时间（秒）
@export var duration: float = 1.0

## 区域形状
enum AreaShape {
	CIRCLE,      # 圆形
	RECTANGLE,   # 矩形
}

@export var area_shape: AreaShape = AreaShape.CIRCLE

## 矩形尺寸（用于 RECTANGLE）
@export var rectangle_size: Vector2 = Vector2(100, 50)

## 是否显示区域特效
@export var show_vfx: bool = true

## 区域特效类型
@export var vfx_type: VfxConfig.VfxType = VfxConfig.VfxType.SKILL_EFFECT

## 区域内效果（每帧应用）
@export var per_frame_effects: Array[FlowEffectBase] = []

## 区域内一次性效果（进入时应用）
@export var on_enter_effects: Array[FlowEffectBase] = []

## 区域中心位置（手动指定或自动）
enum CenterType {
	TARGET_POSITION,    # 目标位置
	SOURCE_POSITION,    # 自身位置
	MANUAL_OFFSET,      # 手动偏移
}

@export var center_type: CenterType = CenterType.TARGET_POSITION

## 手动偏移量
@export var manual_offset: Vector2 = Vector2.ZERO

## 执行区域效果
func apply(context: GameplayFlowContext, skill: SkillBase) -> void:
	# 计算区域中心
	var center = _calculate_center(context, skill)

	# 显示特效
	if show_vfx and VfxManager.instance:
		VfxManager.instance.play_vfx(vfx_type, center)

	# 立即应用一次性效果
	_apply_immediate_effects(context, skill, center)

## 计算区域中心
func _calculate_center(context: GameplayFlowContext, skill: SkillBase) -> Vector2:
	match center_type:
		CenterType.TARGET_POSITION:
			if context.target:
				return context.target.global_position
			return context.get_position()
		CenterType.SOURCE_POSITION:
			if skill.skill_owner:
				return skill.skill_owner.global_position
			return Vector2.ZERO
		CenterType.MANUAL_OFFSET:
			if skill.skill_owner:
				return skill.skill_owner.global_position + manual_offset
			return manual_offset

	return Vector2.ZERO

## 应用即时效果（查找区域内目标）
func _apply_immediate_effects(context: GameplayFlowContext, skill: SkillBase, center: Vector2) -> void:
	# 查找区域内目标
	var targets = _find_targets_in_area(center, skill)

	for target in targets:
		# 创建新上下文
		var area_context = GameplayFlowContext.new()
		area_context.source = skill.skill_owner
		area_context.target = target
		area_context.event_data["position"] = center

		# 应用进入效果
		for effect in on_enter_effects:
			if effect:
				effect.apply(area_context)

## 查找区域内目标
func _find_targets_in_area(center: Vector2, skill: SkillBase) -> Array[BattleActor]:
	var targets: Array[BattleActor] = []

	# 根据技能目标类型确定查询对象
	var query_group = "enemy" if skill.target_type in [SkillConfig.TargetType.ENEMY_SINGLE, SkillConfig.TargetType.ENEMY_AREA] else "player"

	# 获取场景中所有潜在目标
	var potential_targets = []
	if skill.skill_owner and skill.skill_owner.get_tree():
		potential_targets = skill.skill_owner.get_tree().get_nodes_in_group(query_group)

	# 检查是否在区域内
	for potential in potential_targets:
		if potential is BattleActor:
			var distance = center.distance_to(potential.global_position)
			if distance <= area_radius:
				targets.append(potential)

	return targets

func get_description() -> String:
	var desc = "区域效果"
	desc += ", 半径 %.0f" % area_radius
	desc += ", 持续 %.1f 秒" % duration
	return desc