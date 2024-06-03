extends RigidBody2D

@export var damage = 1
@export var speed = 250
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
	if body.has_method("_beHurt"):
		body._beHurt(damage)
	$Timer.start()
		


func _on_body_entered(body):
	_releaseSelf()
	pass # Replace with function body.
