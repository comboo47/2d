extends Node2D
@onready var pin_joint_2d: PinJoint2D = $PinJoint2D

func _ready():
	var player = get_node("/root/Player")
	var mainUI = get_node("/root/MainUI")
	player.connect("pickUpPoker",Callable(mainUI,"pickUpPoker"))
	player.position = $PlayerStart.position

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("testButton"):
		var source:BattleActor = get_node("/root/Player")
		var target:BattleActor = $DamageTestEnemy
