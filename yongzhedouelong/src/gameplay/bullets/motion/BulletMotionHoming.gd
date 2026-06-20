extends BulletMotionBase
## 追踪最近敌人（脚手架最小实现）。
## 关闭重力，每帧朝最近目标方向插值转向，保持当前速率。
## 敌人 group 名在项目里不统一（enemy / Mob / enemies），这里按候选列表容错查找；
## 如需更精确，可在此调整 ENEMY_GROUPS 或改读 BulletDefinition 扩展字段。

const ENEMY_GROUPS := ["enemy", "Mob", "enemies"]

var _turn_rate := 4.0  # 每秒转向插值权重

func setup(bullet: RigidBody2D, _def) -> void:
	bullet.gravity_scale = 0.0

func process(bullet: RigidBody2D, delta: float) -> void:
	var target := _find_nearest(bullet)
	if target == null:
		return
	var speed := bullet.linear_velocity.length()
	if speed <= 0.0:
		return
	var desired := (target.global_position - bullet.global_position).normalized()
	var cur_dir := bullet.linear_velocity.normalized()
	var new_dir := cur_dir.lerp(desired, clampf(_turn_rate * delta, 0.0, 1.0)).normalized()
	bullet.linear_velocity = new_dir * speed
	bullet.rotation = new_dir.angle()

func _find_nearest(bullet: RigidBody2D) -> Node2D:
	var tree := bullet.get_tree()
	if tree == null:
		return null
	var owner_node = bullet.get("bulletOwner")
	var nearest: Node2D = null
	var best := INF
	for g in ENEMY_GROUPS:
		for n in tree.get_nodes_in_group(g):
			if n is Node2D and n != owner_node:
				var d: float = bullet.global_position.distance_squared_to(n.global_position)
				if d < best:
					best = d
					nearest = n
	return nearest
