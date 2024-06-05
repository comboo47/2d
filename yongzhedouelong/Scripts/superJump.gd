extends Node
@export var jumpVelocity = float(-500)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_body_entered(body):
	if body.is_in_group("Player"):
		var by = body.position.y
		var sy = $".".position.y
		var bv = body.velocity.y
		if by <= sy && bv > 0:
			body.velocity.y = jumpVelocity
	pass # Replace with function body.
