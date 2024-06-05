extends Node2D


func _ready():
	var bullet_manager = get_node("/root/BulletManager")
	var player = get_node("/root/Player")
	var mainUI = get_node("/root/MainUI")
	var weapon = player.get_meta("CurrentWeapon")
	weapon.connect("player_fired_bullet",Callable(bullet_manager,"handle_bullet_spawn"))
	player.connect("pickUpPoker",Callable(mainUI,"pickUpPoker"))
	player.position = $PlayerStart.position
