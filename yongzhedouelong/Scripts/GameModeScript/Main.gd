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
		var buff_id = "1001"
		var buff_resource = DataRegistor.instance.get_buff(buff_id)
		if buff_resource:
			var buff_instance:AttributeBuff = buff_resource.deep_duplicate()
			print(buff_instance.buff_name)
			buff_instance.BuffSource = source
			buff_instance.BuffTarget = target
			target.buffManager.buffList.append(buff_instance)
			target.buffManager._OnBuffApply()
		var resource:AttributeBuff = load("res://prefab/Buffs/new_resource.tres")
		resource.ensure_children_loaded()
		print("aaa")	
