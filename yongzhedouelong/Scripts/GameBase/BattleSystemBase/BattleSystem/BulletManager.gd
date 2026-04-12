extends Node2D

## 处理子弹生成
## 支持多种信号格式：
## - 格式1: bullet, position, rotation, direction, type, owner (Bottle)
## - 格式2: bullet, position, rotation, direction, type (Crossbow)
## - 格式3: bullet, position, rotation, direction, speed (Bow - 无owner)
func handle_bullet_spawn(bullet, spawn_position, arg2, arg3, arg4, arg5=null, arg6=null):
	add_child(bullet)

	# 设置位置
	bullet.global_position = spawn_position

	# 判断参数格式并设置子弹属性
	# arg2 可能是 rotation(float) 或 direction(Vector2)
	if arg2 is float:
		# 旧格式: rotation 是 float
		bullet.rotation = arg2
		var direction = arg3
		var type_or_speed = arg4

		# 设置 bulletOwner（如果有）
		if arg6 != null and arg6 is BattleActor:
			bullet.bulletOwner = arg6
		elif arg5 != null and arg5 is BattleActor:
			bullet.bulletOwner = arg5

		# 根据第5个参数类型判断是 type 还是 speed
		if type_or_speed is int:
			# type 是 int
			if type_or_speed == 0:
				bullet.set_axis_velocity(direction)
			elif type_or_speed == 1:
				bullet.gravity_scale = 0
				bullet.linear_velocity = direction
		else:
			# speed 是 float，direction 是速度向量
			bullet.set_axis_velocity(direction)
	elif arg2 is Vector2:
		# 新格式: direction 是 Vector2
		bullet.rotation = arg2.angle()
		var speed = arg3
		bullet.set_axis_velocity(arg2.normalized() * speed)
