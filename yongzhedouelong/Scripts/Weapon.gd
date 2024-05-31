extends Node2D
@export var bullet: PackedScene
signal player_fired_bullet(bullet,position,direction,speed)

var mousePos
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	mousePos = get_viewport().get_mouse_position()
	#get_parent().position
	$".".look_at(mousePos)
	pass

func fire():
	var _bullet = bullet.instantiate()
	var direction = Vector2.ZERO
	direction = mousePos - get_parent().position
	#_bullet.rotation = $".".rotation
	#_bullet.linear_velocity = direction.normalized()  * 250
	emit_signal("player_fired_bullet",_bullet,$Marker2D.global_position,direction)
	
