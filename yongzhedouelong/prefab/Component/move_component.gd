class_name MoveComponent
extends Node
@export var enableGravity:bool
@export var actor:CharacterBody2D
@export var speed:Vector2
@export var jumpSpeed:float

@export var moveDirection:Vector2
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if enableGravity and not actor.is_on_floor():
		actor.velocity.y += gravity * delta	
	if moveDirection.y:
		actor.velocity.y = moveDirection.y * speed.y
		pass
	if moveDirection.x:
		actor.velocity.x = moveDirection.x * speed.x
	else:
		actor.velocity.x = move_toward(actor.velocity.x, 0, speed.x)
	actor.move_and_slide()
	pass

func tryJump():
	if actor.is_on_floor():
		actor.velocity.y = jumpSpeed
	
