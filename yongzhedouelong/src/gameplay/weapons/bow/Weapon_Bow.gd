class_name WeaponBow extends WeaponBase
## 弓箭武器
## 蓄力增加发射速度

func _ready() -> void:
	super._ready()
	weapon_type = WeaponConfig.WeaponType.BOW
	bullet_type = WeaponConfig.BulletType.NORMAL

	# 弓箭专用参数
	max_charge_speed = 650.0  # base 250 + max 400
	charge_rate = 5.0

## 发射弓箭
func fire() -> void:
	# 计算最终速度
	var final_speed = base_speed + charge_speed

	# 发射子弹
	emit_bullet(_aim_direction, final_speed)

	# 重置蓄力
	hold_time = 0.0
	charge_speed = 0.0
	_is_holding = false
	_set_state(WeaponConfig.WeaponState.IDLE)

## 绘制单条弹道轨迹
func _draw_trajectory(delta: float) -> void:
	if trajectory_line == null:
		return

	trajectory_line.clear_points()

	var speed = get_current_speed()
	var dir = _aim_direction

	# 计算轨迹点（考虑重力）
	var gravity = 490.0
	var step_x = dir.x * speed
	var step_y = dir.y * speed

	for i in range(30):
		var point = Vector2(step_x * i * delta, (step_y + gravity * i * delta) * i * delta)
		trajectory_line.add_point(point)