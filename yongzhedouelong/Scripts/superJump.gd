extends Node
@export var jumpVelocity = float(-500)

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("default")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_body_entered(body):
	if body.is_in_group("Player"):
		if body.position.y <= $".".position.y && body.velocity.y > 0:
			body.velocity.y = jumpVelocity
			$AnimatedSprite2D.play("trigger")
			await $AnimatedSprite2D.animation_finished
			$AnimatedSprite2D.play("default")
	pass # Replace with function body.
