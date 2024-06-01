extends Node

var oriPosition = 0
var picker
@export var targetPosition = Vector2(0,0)
@export var totalTime = float(0)

func _ready():
	$TotalTimer.wait_time = totalTime
	totalTime = totalTime / 0.05
	targetPosition = targetPosition/totalTime
	oriPosition = $".".get_parent().position
	pass

func pickUp(node:Node):
	$Timer.start()
	$TotalTimer.start()
	picker = node
	pass
func pickUpDisplay():
	$".".get_parent().position += targetPosition
	$".".get_parent().get_node("AnimatedSprite2D").flip_h = !$".".get_parent().get_node("AnimatedSprite2D").flip_h 
	print($".".get_parent().position)
	
	pass

func _releaseSelf():
	picker.addPoker(randi()%12+1,randi()%3)
	$".".get_parent().queue_free()
	pass
	
