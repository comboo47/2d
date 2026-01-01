extends Node2D


func handle_bullet_spawn(bullet,_position,_rotation,direction,type):
	add_child(bullet)
	bullet.position = _position
	bullet.rotation = _rotation
	if type ==0:
		bullet.set_axis_velocity(direction)
	if type ==1:
		bullet.gravity_scale = 0
		bullet.linear_velocity = direction
