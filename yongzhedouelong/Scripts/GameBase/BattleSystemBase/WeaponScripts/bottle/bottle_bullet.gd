extends RigidBody2D

@export var damagebuffid:String = "1001"
@export var speed = 300
var bulletOwner:BattleActor
# Called when the node enters the scene tree for the first time.
@onready var a = $"."

func _ready():
	$AnimatedSprite2D.play("default")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	$".".look_at($".".linear_velocity)
	pass
func _releaseSelf():
	$".".queue_free()
	
func _on_bullet_hit(body:Node):
	#hurt_somebody(body)
	var boomBody = $BoomArea.get_overlapping_bodies()
	for i in boomBody:
		hurt_somebody(i)
	boomDisplay()
func _on_body_entered(body):
	var boomBody = $BoomArea.get_overlapping_bodies()
	for i in boomBody:
		hurt_somebody(i)
	boomDisplay()
	
	pass # Replace with function body.
func hurt_somebody(body:Node):
	if body.has_method("_beHurt"):
		BattleManager.ApplyBuff(bulletOwner,body,damagebuffid)
	print(body,damagebuffid)
func boomDisplay():
	$".".set_deferred("freeze_mode",1)
	$".".set_deferred("freeze",true)
	$BoomAnimated.visible = true
	$BoomAnimated.rotation = randf()
	$BoomAnimated.play("default")
	$AnimatedSprite2D.visible = false
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	var colorValue = $BoomAnimated.modulate
	colorValue.a = 0.2
	tween.tween_property($BoomAnimated,"scale",Vector2(2,2),0.35)
	tween.tween_property($BoomAnimated,"modulate",colorValue,0.25)
	await tween.finished
	_releaseSelf()
