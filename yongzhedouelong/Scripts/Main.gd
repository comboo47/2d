extends Node2D


func _ready():
	var bullet_manager = $BulletManager
	var player = $CharacterBody2D
	var weapon = player.get_child(0)
	weapon.connect("player_fired_bullet",Callable(bullet_manager,"handle_bullet_spawn"))
