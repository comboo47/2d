class_name WeaponBottle extends WeaponBase
## 瓶子武器
## 蓄力触发散射（三颗子弹）

## 散射角度（弧度）
@export var spread_angle: float = 0.25

## 散射弹道预览线
@onready var trajectory_line2: Line2D = $Line2D2 if has_node("Line2D2") else null
@onready var trajectory_line3: Line2D = $Line2D3 if has_node("Line2D3") else null

func _ready() -> void:
	super._ready()
	weapon_type = WeaponConfig.WeaponType.BOTTLE
	bullet_type = WeaponConfig.BulletType.NORMAL

	# 瓶子专用参数
	charge_time = 0.7
	max_charge_speed = base_speed  # 瓶子速度不变

## 发射瓶子
func fire() -> void:
	# 判断是否触发散射
	if hold_time >= charge_time:
		# 散射三颗子弹
		var dir1 = _aim_direction
		var dir2 = _aim_direction.rotated(spread_angle)
		var dir3 = _aim_direction.rotated(-spread_angle)

		emit_bullet(dir2, base_speed)  # 左
		emit_bullet(dir3, base_speed)  # 右
	else:
		# 单颗子弹
		emit_bullet(_aim_direction, base_speed)

	# 重置蓄力
	hold_time = 0.0
	_is_holding = false
	_set_state(WeaponConfig.WeaponState.IDLE)

## 更新弹道预览（三条）
func _update_trajectory(delta: float) -> void:
	# 主弹道
	if trajectory_line:
		trajectory_line.clear_points()
		_draw_single_trajectory(trajectory_line, _aim_direction, delta)

	# 蓄力足够时显示散射弹道
	if hold_time >= charge_time:
		if trajectory_line2:
			trajectory_line2.clear_points()
			_draw_single_trajectory(trajectory_line2, _aim_direction.rotated(spread_angle), delta)

		if trajectory_line3:
			trajectory_line3.clear_points()
			_draw_single_trajectory(trajectory_line3, _aim_direction.rotated(-spread_angle), delta)
	else:
		# 清除散射弹道
		if trajectory_line2:
			trajectory_line2.clear_points()
		if trajectory_line3:
			trajectory_line3.clear_points()

## 绘制单条弹道轨迹
func _draw_single_trajectory(line: Line2D, dir: Vector2, delta: float) -> void:
	var speed = base_speed
	var gravity = 490.0
	var step_x = dir.x * speed
	var step_y = dir.y * speed

	for i in range(35):
		var point = Vector2(step_x * i * delta, (step_y + gravity * i * delta) * i * delta)
		line.add_point(point)
