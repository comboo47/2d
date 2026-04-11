extends Node2D

## 处理子弹生成
## 参数格式: bullet, spawn_position, direction, speed, bullet_type
## 或者兼容旧格式: bullet, position, rotation, direction, type, owner
func handle_bullet_spawn(bullet, spawn_position, direction_or_rotation, arg3, arg4, arg5=null):
	add_child(bullet)

	# 处理不同的参数格式
	if arg5 != null:
		# 旧格式: bullet, position, rotation, direction, type, owner
		bullet.position = spawn_position
		bullet.rotation = direction_or_rotation
		bullet.bulletOwner = arg5
		var direction = arg3
		var type = arg4
		if type == 0:
			bullet.set_axis_velocity(direction)
		elif type == 1:
			bullet.gravity_scale = 0
			bullet.linear_velocity = direction
	else:
		# 新格式: bullet, spawn_position, direction, speed, bullet_type
		bullet.global_position = spawn_position
		var direction = direction_or_rotation
		var speed = arg3
		var bullet_type = arg4
		bullet.rotation = direction.angle()
		if bullet_type == 0:
			bullet.set_axis_velocity(direction.normalized() * speed)
		elif bullet_type == 1:
			bullet.gravity_scale = 0
			bullet.linear_velocity = direction.normalized() * speed