class_name popDamageWidget extends Control

@export var numberList:Array[Resource]
@onready var h_box_container: HBoxContainer = $Path2D/PathFollow2D/HBoxContainer
@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D

var damageValue = []
var popPosition:Vector2 = Vector2.ZERO

func init(_actor:BattleActor,_damageNumber:float = 15) -> void:
	popPosition = _actor.global_position + Vector2(0,-12) + Vector2(randf()*7.5,randf()*7.5)
	damageValue = split_number_to_list_str(ceil(_damageNumber))
	

func _ready() -> void:	
	for num in damageValue:
		var numResouce = numberList[num].duplicate(true	)
		var textureRect:TextureRect = TextureRect.new() 
		textureRect.texture = numResouce
		textureRect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		h_box_container.add_child(textureRect)
	popDamage()

func split_number_to_list_str(num: int) -> Array:
	# 处理0的特殊情况
	if num == 0:
		return [0]
	# 转为字符串并去除负号，遍历每个字符转为数字
	var num_str = str(abs(num))  # 取绝对值后转字符串，避免负号干扰
	var digit_list = []
	for char in num_str:
		digit_list.append(int(char))
	return digit_list

func popDamage()->void:
	self.global_position = popPosition
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(path_follow_2d, "progress_ratio",1,0.5)
	tween.play()
	pass


func _on_timer_timeout() -> void:
	self.queue_free()
	pass # Replace with function body.
