extends Node2D

## 处理子弹生成
## 支持多种信号格式：
## - 新格式 (WeaponBase): bullet, position, direction, speed, type, owner
## - 旧格式1: bullet, position, rotation, direction, type, owner (Bottle/Crossbow)
## - 旧格式2: bullet, position, rotation, direction, type (无 owner)
## - 旧格式3: bullet, position, rotation, direction, speed (Bow - 无owner)
func handle_bullet_spawn(bullet_packed, spawn_position, arg2, arg3, arg4, arg5=null, arg6=null):
	# 实例化子弹
	var bullet = bullet_packed.instantiate() if bullet_packed is PackedScene else bullet_packed
	add_child(bullet)

	# 设置位置
	bullet.global_position = spawn_position

	# 判断参数格式并设置子弹属性
	# 新格式: arg2 是 direction(Vector2), arg3 是 speed(float), arg4 是 type(int), arg5 是 owner
	if arg2 is Vector2 and arg3 is float:
		# 新格式 (WeaponBase.weapon_fired)
		bullet.rotation = arg2.angle()
		var bullet_type = arg4 if arg4 is int else 0
		var owner = arg5 if arg5 is BattleActor else null

		# 设置 owner（检查属性是否存在）
		if "bulletOwner" in bullet:
			bullet.bulletOwner = owner
		if owner == null:
			push_warning("BulletManager: 武器 owner_actor 为 null，子弹无法正确应用 Buff")

		# 根据类型设置物理
		if bullet_type == WeaponConfig.BulletType.STRAIGHT:
			# 无重力直射
			bullet.gravity_scale = 0
			bullet.linear_velocity = arg2.normalized() * arg3
		else:
			# 有重力
			bullet.set_axis_velocity(arg2.normalized() * arg3)

	elif arg2 is float:
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
