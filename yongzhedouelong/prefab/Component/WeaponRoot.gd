extends Node

@export var currentWeapon:int
func _enter_tree():
	var bullet_manager = get_node("/root/BulletManager")
	var player:mainPlayer = get_node("/root/Player")
	player.set_meta("CurrentWeapon",get_child(currentWeapon))
	var weapon = player.get_meta("CurrentWeapon")
	weapon.connect("player_fired_bullet",Callable(bullet_manager,"handle_bullet_spawn"))
func _ready():
	var weapons = get_children()
	for i:Node2D in weapons:
		if i == weapons[currentWeapon]:
			i.show()
		else:
			i.hide()
	
