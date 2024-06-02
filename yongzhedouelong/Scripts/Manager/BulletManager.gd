extends Node2D


func handle_bullet_spawn(bullet,position,direction):
	add_child(bullet)
	bullet.position = position
	bullet.linear_velocity = direction.normalized() * bullet.speed
