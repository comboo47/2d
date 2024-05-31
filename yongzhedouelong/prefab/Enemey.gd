extends RigidBody2D

@export var hp = 0
@export var damage = 1
@export var speed = 50
var ori_modulate
# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play()
	ori_modulate = $".".modulate
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _beHurt(dmg):
	hp = hp - dmg
	if(hp <= 0):
		_releaseSelf()
	_hitDisplay()
func _releaseSelf():
	$".".queue_free()

func _hitDisplay():
	$".".modulate = Color.LIGHT_CORAL
	$HitTimer.start()
func _hitDisplayEnd():
	$".".modulate = ori_modulate
