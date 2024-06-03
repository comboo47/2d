extends Node2D
@export var bullet: PackedScene
signal player_fired_bullet(bullet,position,direction,speed)

var mousePos = Vector2()
var defaultSpeed
var addSpeed = float(0)
var direction = Vector2.ZERO
var fireVector
var stepX
var stepY
var positionList:Array
# Called when the node enters the scene tree for the first time.
func _ready():
	var b = bullet.instantiate()
	defaultSpeed = b.speed
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$".".look_at(mousePos)
	$Line2D.position = $Marker2D.position
	$Line2D.rotation = -$".".rotation
	mousePos = get_viewport().get_mouse_position()
	direction = mousePos - get_parent().position
	fireVector = direction.normalized() * (defaultSpeed + addSpeed)
	stepX = fireVector.x
	stepY = fireVector.y
	#print("fireVector:",fireVector,"direction:",direction.normalized())
	#print("X:",stepX,"y:",stepY)
	$Line2D.clear_points()
	for i in range(20):
		$Line2D.add_point(Vector2(stepX*i*delta,(stepY+4.9*i)*i*delta))
		pass
	#get_parent().position
	pass
func holdFire():
	addSpeed += 10

func fire():
	addSpeed = 0
	if get_parent():
		var _bullet = bullet.instantiate()
		#_bullet.rotation = $".".rotation
		#_bullet.linear_velocity = direction.normalized()  * 250
		emit_signal("player_fired_bullet",_bullet,$Marker2D.global_position,fireVector)
	
