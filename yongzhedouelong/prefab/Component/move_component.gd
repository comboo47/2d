class_name MoveComponent
extends Node
@export var enableGravity:bool
@export var actor:CharacterBody2D
@export var speed:Vector2
@export var jumpSpeed:float
@export var moveDirection:Vector2

var timer: Timer = null

var under_control = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# 安全获取 Timer 节点（如果存在）
	if has_node("Timer"):
		timer = $Timer

func moveToDirection(vector:Vector2):
	moveDirection = vector
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if enableGravity and not actor.is_on_floor():
		actor.velocity.y += gravity * delta	
	if under_control:
		if moveDirection.y:
			actor.velocity.y = moveDirection.y * abs(speed.y)
			pass
		if moveDirection.x:
			actor.velocity.x = moveDirection.x * abs(speed.x)
		else:
			actor.velocity.x = move_toward(actor.velocity.x, 0, speed.x)
			if enableGravity == false:
				actor.velocity.y = move_toward(actor.velocity.y, 0, speed.y)
	actor.move_and_slide()
	pass

func tryJump(canjump = false):
	if actor.is_on_floor() or canjump:
		actor.velocity.y = jumpSpeed

func hitBackSmall(direction:Vector2,backSpeed:Vector2,backTime:float):
	if timer != null:
		if timer.is_stopped():
			under_control = false
			actor.velocity.x = direction.x * backSpeed.x
			actor.velocity.y = direction.y * backSpeed.y
			timer.wait_time = backTime
			timer.start()
			await timer.timeout
			under_control = true
	pass
