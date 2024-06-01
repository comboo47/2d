extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -310.0

signal pickUpPoker(number,flower)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

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
			print(i)
	if Input.is_action_pressed("left"):
		_velocity.x -= 1
	if Input.is_action_pressed("right"):
		_velocity.x += 1
	if Input.is_action_just_pressed("fire"):
		$Weapon.fire()
	if _velocity.length() > 0:
		_velocity = _velocity.normalized() * SPEED
		$AnimatedSprite2D.play("walk")
		if _velocity.x >0:
			$AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.play("idle")
	
	
	position = position.clamp(Vector2.ZERO, screen_size)
	pass


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()

func addPoker(_number,_flower):
	emit_signal("pickUpPoker",_number,_flower)
	pass
