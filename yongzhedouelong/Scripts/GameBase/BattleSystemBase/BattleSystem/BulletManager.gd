extends Node2D

## 处理子弹生成
## 旧格式: bullet, position, rotation(float), direction(Vector2), type(int), owner(BattleActor)
## 新格式: bullet, spawn_position, direction(Vector2), speed(float), bullet_type(int)
func handle_bullet_spawn(bullet, spawn_position, direction_or_rotation, arg3, arg4, arg5=null):
	add_child(bullet)

	# 根据参数类型判断格式
	# direction_or_rotation 是 Vector2 = 新格式
	# direction_or_rotation 是 float = 旧格式
	if direction_or_rotation is Vector2:
		# 新格式: bullet, spawn_position, direction, speed, bullet_type
		var direction: Vector2 = direction_or_rotation
		var speed: float = arg3
		var bullet_type: int = arg4
		bullet.global_position = spawn_position
		bullet.rotation = direction.angle()
		if bullet_type == 0:
			bullet.set_axis_velocity(direction.normalized() * speed)
		elif bullet_type == 1:
			bullet.gravity_scale = 0
			bullet.linear_velocity = direction.normalized() * speed
	else:
		# 旧格式: bullet, position, rotation, direction, type, owner
		var rotation: float = direction_or_rotation
		var direction: Vector2 = arg3
		var type: int = arg4
		bullet.position = spawn_position
		bullet.rotation = rotation
		if arg5 != null:
			bullet.bulletOwner = arg5
		if type == 0:
			bullet.set_axis_velocity(direction)
		elif type == 1:
			bullet.gravity_scale = 0
			bullet.linear_velocity = direction