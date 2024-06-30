extends CharacterBody2D

@export var EnemyID = 1001
@export var max_hp = float(0)
@export var damage = 1
@export var speed = 50
var ori_modulate
var ori_scale
var hp = float(0)
var isDead = false
var target

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play()
	ori_modulate = $".".modulate
	ori_scale = $AnimatedSprite2D.scale
	hp = max_hp
	pass # Replace with function body.
func getID():
	return EnemyID

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	target = get_node("/root/Player")
	pass

func _beHurt(dmg):
	hp = hp - dmg
	if(hp <= 0):
		if !isDead:
			setDead()
	_hitDisplay()
func setDead():
	isDead = true
	$".".set_collision_layer_value(2,false)
	if get_node("/root/DropManager"):
		get_node("/root/DropManager").dropPoker(self)
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
