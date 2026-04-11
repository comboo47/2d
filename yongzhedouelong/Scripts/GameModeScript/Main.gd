extends Node2D
@onready var pin_joint_2d: PinJoint2D = $PinJoint2D

var menu_popup_scene = preload("res://art/UIResource/UI/DamageNumber/PopDamage.tscn")
var menu_popup_instance: Node
func _ready():
	var player = get_node("/root/Player")
	var mainUI = get_node("/root/MainUI")
	player.connect("pickUpPoker",Callable(mainUI,"pickUpPoker"))
	player.position = $PlayerStart.position

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("testButton"):
		var num = randf()*100
		var player = get_node("/root/Player")
		menu_popup_instance = menu_popup_scene.instantiate()
		# 3. 设置实例属性（可选，如位置、名称）
		menu_popup_instance.name = "MenuPopup"
		# 4. 添加到当前场景树（必须！否则实例不会显示）
		
		menu_popup_instance.init(player,num)
		add_child(menu_popup_instance)
