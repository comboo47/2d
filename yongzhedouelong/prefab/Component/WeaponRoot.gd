extends Node

@export var weaponOwner:BattleActor
@export_range(0, 2) var currentWeapon:int

func _enter_tree():
	if weaponOwner == null:
		push_error("WeaponRoot: weaponOwner 为 null!")
		return

	weaponOwner.set_meta("CurrentWeapon",get_child(currentWeapon))
	# 设置第一个武器的 owner
	var first_weapon = get_child(currentWeapon)

	# 使用 "property" in object 检查属性是否存在（而非 get() 检查值是否为 null）
	if "owner_actor" in first_weapon:
		first_weapon.owner_actor = weaponOwner
	elif "weaponOwner" in first_weapon:
		first_weapon.weaponOwner = weaponOwner
	else:
		push_warning("WeaponRoot: 武器没有 owner_actor 或 weaponOwner 属性")

func _ready():
	updateWeapon()

func updateWeapon():
	weaponOwner.set_meta("CurrentWeapon",get_child(currentWeapon))
	var bullet_manager = get_node("/root/BulletManager")
	var weapon = weaponOwner.get_meta("CurrentWeapon")

	# 连接统一的 weapon_fired 信号（兼容旧信号名 player_fired_bullet）
	if weapon.has_signal("weapon_fired"):
		if not weapon.is_connected("weapon_fired",Callable(bullet_manager,"handle_bullet_spawn")):
			weapon.connect("weapon_fired",Callable(bullet_manager,"handle_bullet_spawn"))
	elif weapon.has_signal("player_fired_bullet"):
		if not weapon.is_connected("player_fired_bullet",Callable(bullet_manager,"handle_bullet_spawn")):
			weapon.connect("player_fired_bullet",Callable(bullet_manager,"handle_bullet_spawn"))

	# 设置武器的 owner
	if "owner_actor" in weapon:
		weapon.owner_actor = weaponOwner
	elif "weaponOwner" in weapon:
		weapon.weaponOwner = weaponOwner

	var weapons = get_children()
	for i:Node2D in weapons:
		if i == weapons[currentWeapon]:
			i.show()
		else:
			i.hide()

func setCurrentWeapon(i:int):
	currentWeapon = i
	updateWeapon()
