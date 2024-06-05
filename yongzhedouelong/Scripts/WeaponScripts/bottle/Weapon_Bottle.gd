extends Node2D
@export var bullet: PackedScene
signal player_fired_bullet(bullet,_position,_rotation,direction,speed)

var mousePos = Vector2()
var defaultSpeed
var direction = Vector2.ZERO
var direction2 = Vector2.ZERO
var direction3 = Vector2.ZERO
var hold = false
var holdTime = 0
var fireVector
var stepX
var stepY
var positionList:Array
var holdNeedTime = float(0.7)
# Called when the node enters the scene tree for the first time.
func _enter_tree():
	$".".get_parent().set_meta("CurrentWeapon",self)

func _ready():
	$AnimatedSprite2D.play("default")
	var b = bullet.instantiate()
	defaultSpeed = b.speed
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$".".look_at(mousePos)
	$AnimatedSprite2D.rotation = -$".".rotation
	$Line2D.position = $Marker2D.position
	$Line2D.rotation = -$".".rotation
	$Line2D2.position = $Marker2D.position
	$Line2D2.rotation = -$".".rotation
	$Line2D3.position = $Marker2D.position
	$Line2D3.rotation = -$".".rotation
	mousePos = get_viewport().get_mouse_position()
	direction = mousePos - get_parent().position
	direction = direction.normalized() * defaultSpeed
	drawLine(direction,delta,$Line2D)
	if hold:
		holdTime += delta
		if holdTime < holdNeedTime:
			$AnimatedSprite2D.play("shake")
		if holdTime >= holdNeedTime:
			if $AnimatedSprite2D.animation != "shakeOver":
				$AnimatedSprite2D.play("shakeOver")
			direction2 = direction.rotated(0.25)
			drawLine(direction2,delta,$Line2D2)
			direction3 = direction.rotated(-0.25)
			drawLine(direction3,delta,$Line2D3)
	else:
		#$Line2D.clear_points()
		$Line2D2.clear_points()
		$Line2D3.clear_points()
	#get_parent().position
	pass
func holdFire():
	hold = true
func fire():
	$AnimatedSprite2D.play("default")
	if holdTime >= holdNeedTime:
		
		var _bullet = bullet.instantiate()
		var _bullet2 = bullet.instantiate()
		#_bullet.rotation = $".".rotation
		#_bullet.linear_velocity = direction.normalized()  * 250
		realFire(_bullet,direction2)
		realFire(_bullet2,direction3)
	if get_parent():
		var _bullet = bullet.instantiate()
		#_bullet.rotation = $".".rotation
		#_bullet.linear_velocity = direction.normalized()  * 250
		realFire(_bullet,direction)
	hold = false
	holdTime = 0
func realFire(_bullet,direction):
	emit_signal("player_fired_bullet",_bullet,$Marker2D.global_position,$Marker2D.global_rotation,direction,0)

func drawLine(firedirection,delta,line):

	stepX = firedirection.x
	stepY = firedirection.y
	#print("fireVector:",fireVector,"direction:",direction.normalized())
	#print("X:",stepX,"y:",stepY)
	line.clear_points()
	for i in range(35):
		line.add_point(Vector2(stepX*i*delta,(stepY+490*i*delta)*i*delta))
	pass
