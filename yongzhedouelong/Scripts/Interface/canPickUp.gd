extends Node

var oriPosition = 0
var picker
var canPickUp = true
@export var targetPosition = Vector2(0,-16)
@export var totalTime = float(0.5)

func _ready():
	pass

func pickUp(node:Node):
	canPickUp = false
	#$TotalTimer.start()
	picker = node
	pickUpDisplay()
	$".".get_parent().pickEffect(picker)
	pass
func pickUpDisplay():
	var tween = $".".create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($".".get_parent(),"position",$".".get_parent().position + targetPosition,totalTime)
	$".".get_parent().pickEffect(picker)
	await tween.finished
	_releaseSelf()
	pass
func _releaseSelf():
	#picker.addPoker(randi()%12+1,randi()%3)
	$".".get_parent().queue_free()
	pass
	
