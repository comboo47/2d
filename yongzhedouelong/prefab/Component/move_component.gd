class_name MoveComponent
extends Node
@export var enableGravity:bool
@export var actor:CharacterBody2D
@export var speed:Vector2
@export var jumpSpeed:float
@export var moveDirection:Vector2

@onready var timer = $Timer

var underControle = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if enableGravity and not actor.is_on_floor():
		actor.velocity.y += gravity * delta	
	if underControle:
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

func hitBackSmall(direction:Vector2,backSpeed:Vector2,backTime:float):
	if timer.is_stopped():
		underControle = false
		actor.velocity.x = direction.x * backSpeed.x
		actor.velocity.y = direction.y * backSpeed.y
		timer.wait_time = backTime
		timer.start()
		await timer.timeout
		underControle = true
	pass
