extends RigidBody2D

@export var damage = float(1)
@export var speed = 300
# Called when the node enters the scene tree for the first time.
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
	hurSomeBody(body)
	var boomBody = $BoomArea.get_overlapping_bodies()
	for i in boomBody:
		hurSomeBody(i)
	boomDisplay()
func _on_body_entered(body):
	boomDisplay()
	
	pass # Replace with function body.
func hurSomeBody(body:Node):
	if body.has_method("_beHurt"):
		body._beHurt(damage)
func boomDisplay():
	$BoomAnimated.visible = true
	$BoomAnimated.rotation = randf()
	$BoomAnimated.play("default")
	$AnimatedSprite2D.visible = false
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($BoomAnimated,"scale",Vector2(2,2),0.3)
	await tween.finished
	_releaseSelf()
