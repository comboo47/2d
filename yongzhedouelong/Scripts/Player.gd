extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -310.0
var holdFireTime = float(0)
var underControle = true
signal pickUpPoker(number,flower)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var mousePosition:Vector2

var screen_size
# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var _velocity = Vector2.ZERO
	if Input.is_action_just_pressed("interaction"):
		#addPoker(randi()%12+1,randi()%3)
		if $InteractionInterface.interactionItem != null:
			var i = $InteractionInterface.interactionItem
			if i.get_node("canPickUp"):
				i.get_node("canPickUp").pickUp(self)
			#print(i)
	if Input.is_action_pressed("fire"):
		holdFireTime += delta
		if holdFireTime >= 0.1:
			$".".get_meta("CurrentWeapon").holdFire()
	if Input.is_action_just_released("fire"):
		holdFireTime = 0
		$".".get_meta("CurrentWeapon").fire()			
	AnimControle()
	
	position = position.clamp(Vector2.ZERO, screen_size)
	pass


func addPoker(_number,_flower):
	emit_signal("pickUpPoker",_number,_flower)
	pass

func AnimControle():
	if velocity.x:
		$AnimatedSprite2D.play("walk")
		if velocity.x >0:
			$AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.play("idle")
