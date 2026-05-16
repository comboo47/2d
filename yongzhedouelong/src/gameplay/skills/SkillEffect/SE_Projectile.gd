class_name SE_Projectile extends SkillEffectBase
## 投射物效果
## 发射子弹/投射物

## 子弹预制体路径
@export var bullet_prefab: PackedScene

## 发射速度
@export var speed: float = 400.0

## 发射方向类型
enum DirectionType {
	TARGET_DIRECTION,    # 朝目标方向
	FIXED_DIRECTION,     # 固定方向
	SPREAD,              # 扇形散射
	HOMING,              # 追踪目标
}

@export var direction_type: DirectionType = DirectionType.TARGET_DIRECTION

## 固定方向角度（度）
@export var fixed_angle: float = 0.0

## 散射数量
@export var spread_count: int = 1

## 散射角度范围（度）
@export var spread_angle: float = 30.0

## 子弹类型（传递给 BulletManager）
@export var bullet_type: int = 0

## 伤害 Buff ID（子弹命中时应用）
@export var damage_buff_id: String = "1001"

## 执行投射物发射
func apply(context: GameplayFlowContext, skill: SkillBase) -> void:
	if bullet_prefab == null:
		push_warning("SE_Projectile: bullet_prefab 为空")
		return

	# 获取发射位置
	var spawn_position = _get_spawn_position(context, skill)

	# 计算发射方向
	var directions = _calculate_directions(context, skill)

	# 发射子弹
	for dir in directions:
		_spawn_bullet(context, skill, spawn_position, dir)

## 获取发射位置
func _get_spawn_position(context: GameplayFlowContext, skill: SkillBase) -> Vector2:
	if skill.skill_owner:
		return skill.skill_owner.global_position
	return context.get_position()

## 计算发射方向列表
func _calculate_directions(context: GameplayFlowContext, skill: SkillBase) -> Array[Vector2]:
	var directions: Array[Vector2] = []

	match direction_type:
		DirectionType.TARGET_DIRECTION:
			# 朝目标方向
			var target_pos = Vector2.ZERO
			if context.target:
				target_pos = context.target.global_position
			else:
				# 使用鼠标位置（玩家技能）
				target_pos = skill.skill_owner.get_viewport().get_mouse_position()

			var base_dir = (target_pos - _get_spawn_position(context, skill)).normalized()
			directions.append(base_dir)

		DirectionType.FIXED_DIRECTION:
			# 固定方向
			var angle_rad = deg_to_rad(fixed_angle)
			var dir = Vector2(cos(angle_rad), sin(angle_rad))
			directions.append(dir)

		DirectionType.SPREAD:
			# 扇形散射
			var base_angle = 0.0
			if context.target:
				var target_pos = context.target.global_position
				base_angle = rad_to_deg((target_pos - _get_spawn_position(context, skill)).angle())

			var half_spread = spread_angle / 2.0
			var step = spread_angle / (spread_count - 1) if spread_count > 1 else 0.0

			for i in range(spread_count):
				var angle = base_angle - half_spread + step * i
				var angle_rad = deg_to_rad(angle)
				var dir = Vector2(cos(angle_rad), sin(angle_rad))
				directions.append(dir)

		DirectionType.HOMING:
			# 追踪方向（子弹本身会追踪）
			var base_dir = Vector2.RIGHT
			if context.target:
				base_dir = (context.target.global_position - _get_spawn_position(context, skill)).normalized()
			directions.append(base_dir)

	return directions

## 发射单个子弹
func _spawn_bullet(context: GameplayFlowContext, skill: SkillBase, position: Vector2, direction: Vector2) -> void:
	# 通过 BulletManager 发射
	if BulletManager.instance:
		BulletManager.instance.handle_bullet_spawn(
			bullet_prefab,
			position,
			direction.angle(),
			direction,
			bullet_type,
			skill.skill_owner
		)
	else:
		push_warning("SE_Projectile: BulletManager 未初始化")

func get_description() -> String:
	var desc = "发射子弹"
	if spread_count > 1:
		desc += " (%d 发)" % spread_count
	desc += ", 速度 %.0f" % speed
	return desc