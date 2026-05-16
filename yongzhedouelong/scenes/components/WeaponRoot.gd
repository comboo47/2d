extends Node

@export var weaponOwner:BattleActor
@export_range(0, 2) var currentWeapon:int

## 上一个武器索引（用于触发 weapon_exit）
var _previous_weapon: int = -1

func _enter_tree():
	if weaponOwner == null:
		push_error("WeaponRoot: weaponOwner 为 null!")
		return

	var weapon = get_child(currentWeapon)
	weaponOwner.set_meta("CurrentWeapon", weapon)

	# 设置 owner_actor（WeaponBase 子类都有此属性）
	if "owner_actor" in weapon:
		weapon.owner_actor = weaponOwner

func _ready():
	# 初始化上一个武器索引
	_previous_weapon = currentWeapon
	updateWeapon()

func updateWeapon():
	var weapons = get_children()
	var new_weapon = weapons[currentWeapon]

	# 1. 触发旧武器的退出事件
	if _previous_weapon >= 0 and _previous_weapon < weapons.size() and _previous_weapon != currentWeapon:
		var old_weapon = weapons[_previous_weapon]
		if old_weapon.has_method("on_weapon_exit"):
			old_weapon.on_weapon_exit()

	# 2. 触发新武器的进入事件
	if new_weapon.has_method("on_weapon_enter"):
		new_weapon.on_weapon_enter()

	# 3. 更新 meta 数据
	weaponOwner.set_meta("CurrentWeapon", new_weapon)

	# 4. 连接 BulletManager 信号
	var bullet_manager = get_node("/root/BulletManager")

	if new_weapon.has_signal("weapon_fired"):
		if not new_weapon.is_connected("weapon_fired",Callable(bullet_manager,"handle_bullet_spawn")):
			new_weapon.connect("weapon_fired",Callable(bullet_manager,"handle_bullet_spawn"))
	elif new_weapon.has_signal("player_fired_bullet"):
		# 兼容旧信号格式
		if not new_weapon.is_connected("player_fired_bullet",Callable(bullet_manager,"handle_bullet_spawn")):
			new_weapon.connect("player_fired_bullet",Callable(bullet_manager,"handle_bullet_spawn"))

	# 5. 设置 owner_actor
	if "owner_actor" in new_weapon:
		new_weapon.owner_actor = weaponOwner

	# 6. 显示/隐藏武器
	for i:Node2D in weapons:
		if i == new_weapon:
			i.show()
		else:
			i.hide()

	# 7. 更新上一个武器索引
	_previous_weapon = currentWeapon

func setCurrentWeapon(i:int):
	currentWeapon = i
	updateWeapon()
