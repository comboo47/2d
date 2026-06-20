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

	# 2. 先设 owner_actor（on_weapon_enter 里 _setup_bindings 需要 owner 才能装 skill）
	if weaponOwner != null and "owner_actor" in new_weapon:
		new_weapon.owner_actor = weaponOwner

	# 3. 触发新武器的进入事件
	if new_weapon.has_method("on_weapon_enter"):
		new_weapon.on_weapon_enter()

	# 3. 更新 meta 数据（weaponOwner 可能为 null：组件场景被单独运行时无玩家父节点）
	if weaponOwner != null:
		weaponOwner.set_meta("CurrentWeapon", new_weapon)

	# 4. 设置 owner_actor（已在 step 2 设过，此处保险幂等）
	if weaponOwner != null and "owner_actor" in new_weapon:
		new_weapon.owner_actor = weaponOwner

	# 5. 显示/隐藏武器
	for i:Node2D in weapons:
		if i == new_weapon:
			i.show()
		else:
			i.hide()

	# 6. 更新上一个武器索引
	_previous_weapon = currentWeapon

func setCurrentWeapon(i:int):
	currentWeapon = i
	updateWeapon()
