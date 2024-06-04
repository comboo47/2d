extends Node

var player 
var energy = float(0)
# Called when the node enters the scene tree for the first time.
func _ready():
	player = $".".get_parent()
	#$Timer.start()
	updateEnergeBarvisible()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $ProgressBar.max_value != 0:
		energy = player.get_meta("CurrentWeapon").getWeaponEnerge()
		$ProgressBar.value = energy
	pass
func updateEnergeBarvisible():
	
	if player.has_meta("CurrentWeapon"):
		if player.get_meta("CurrentWeapon").has_method("getWeaponEnerge"):
			energy = player.get_meta("CurrentWeapon").getWeaponEnerge()
			player.set_meta("weaponEnergyBar",self)
			$ProgressBar.max_value = energy
	else:
		$".".visible = false
