extends Node2D


func _ready():
	var bullet_manager = get_node("/root/BulletManager")
	var player = $CharacterBody2D
	var mainUI = $MainUI
	var weapon = player.get_meta("CurrentWeapon")
	weapon.connect("player_fired_bullet",Callable(bullet_manager,"handle_bullet_spawn"))
	player.connect("pickUpPoker",Callable(mainUI,"pickUpPoker"))
	
