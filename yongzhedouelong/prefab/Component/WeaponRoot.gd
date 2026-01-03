extends Node

@export var weaponOwner:BattleActor
@export_range(0, 2) var currentWeapon:int

func _enter_tree():
	var bullet_manager = get_node("/root/BulletManager")
	weaponOwner.set_meta("CurrentWeapon",get_child(currentWeapon))
	var weapon = weaponOwner.get_meta("CurrentWeapon")
	weaponOwner.connect("player_fired_bullet",Callable(bullet_manager,"handle_bullet_spawn"))
	$Weapon_Bottle.weaponOwner = self.weaponOwner
func _ready():
	updateWeapon()

func updateWeapon():
	weaponOwner.set_meta("CurrentWeapon",get_child(currentWeapon))
	var bullet_manager = get_node("/root/BulletManager")
	var weapon = weaponOwner.get_meta("CurrentWeapon")
	weapon.connect("player_fired_bullet",Callable(bullet_manager,"handle_bullet_spawn"))
	var weapons = get_children()
	for i:Node2D in weapons:
		if i == weapons[currentWeapon]:
			i.show()
		else:
			i.hide()

func setCurrentWeapon(i:int):
	currentWeapon = i
	updateWeapon()
	pass
