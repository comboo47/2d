extends RigidBody2D

@export var max_hp = 0
@export var damage = 1
@export var speed = 50
var ori_modulate
var ori_scale
var hp
# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play()
	ori_modulate = $".".modulate
	ori_scale = $AnimatedSprite2D.scale
	hp = max_hp
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _beHurt(dmg):
	hp = hp - dmg
	if(hp <= 0):
		setDead()
	_hitDisplay()
func setDead():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($".","scale",Vector2(),0.2)
	await tween.finished
	$".".queue_free()
	pass

func _hitDisplay():
	ori_modulate.a = (float(hp)/float(max_hp))
	print(hp,max_hp,(float(hp)/float(max_hp)))
	ori_modulate = Color(ori_modulate)
	$".".modulate = Color.SLATE_GRAY
	$AnimatedSprite2D.scale = ori_scale*1.1
	$HitTimer.start()
func _hitDisplayEnd():
	$".".modulate = ori_modulate
	$AnimatedSprite2D.scale = ori_scale
