class_name	Move_Input_Component
extends Node

@export var moveComponent:MoveComponent

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event:InputEvent) -> void:
	var direction_h = Input.get_axis("left", "right")
	moveComponent.moveDirection.x = direction_h
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if Input.is_action_just_pressed("jump"):
		moveComponent.tryJump()
	pass
