extends Node2D


func handle_bullet_spawn(bullet,position,direction):
	add_child(bullet)
	bullet.position = position
	bullet.set_axis_velocity(direction)
