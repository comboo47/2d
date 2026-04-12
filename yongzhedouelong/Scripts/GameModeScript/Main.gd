extends Node2D

func _ready():
	var player = get_node("/root/Player")
	player.position = $PlayerStart.position

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("testButton"):
		var num = randf() * 100
		var player = get_node("/root/Player")
		UIManager.instance.show_damage(player, num)
