class_name HurtDisplayComponent
extends Node

var ori_modulate
var ori_scale
@export var animSprit2D:AnimatedSprite2D
@export var displayTime:float = 0.1
@export var displayColor:Color = Color.SLATE_GRAY

@onready var hit_timer:Timer = $HitTimer as Timer
# Called when the node enters the scene tree for the first time.
	
func _ready() -> void:
	ori_modulate = $".".get_parent().modulate
	ori_scale = animSprit2D.scale
	hit_timer.timeout.connect(hitDisplayEnd)
	hit_timer.wait_time = displayTime
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func hitDisplay():
	ori_modulate = Color(ori_modulate)
	$".".get_parent().modulate = displayColor
	animSprit2D.scale = ori_scale*1.1
	hit_timer.start()
func hitDisplayEnd():
	$".".get_parent().modulate = ori_modulate
	animSprit2D.scale = ori_scale
