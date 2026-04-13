extends Node

var player
var energy = float(0)
var energyShow = false

# Called when the node enters the scene tree for the first time.
func _ready():
	player = $".".get_parent()
	updateEnergyBarvisible()


# Called every frame. 'delta' is the elapsed time from the previous frame.
func _process(delta):
	if energyShow:
		var weapon = player.get_meta("CurrentWeapon")
		if weapon and weapon.has_method("getWeaponEnergy"):
			energy = weapon.getWeaponEnergy()
			energy = clamp(energy, 0, $ProgressBar.max_value)
			$ProgressBar.value = energy
		else:
			# 武器切换后不再支持能量显示，隐藏
			energyShow = false
			$".".visible = false

func updateEnergyBarvisible():
	if player.has_meta("CurrentWeapon"):
		var weapon = player.get_meta("CurrentWeapon")
		if weapon and weapon.has_method("getWeaponEnergy"):
			energy = weapon.getWeaponEnergy()
			player.set_meta("weaponEnergyBar", self)
			$ProgressBar.max_value = energy
			energyShow = true
			$".".visible = true
		else:
			$".".visible = false
	else:
		$".".visible = false
