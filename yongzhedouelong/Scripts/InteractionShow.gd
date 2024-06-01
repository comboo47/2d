extends Node

var interactionItem = null
# Called when the node enters the scene tree for the first time.

func showCanPickUp():
	for i in $".".get_overlapping_areas():
		if i.get_node("canPickUp"):
			$AnimatedSprite2D.play()
			$AnimatedSprite2D.show()
		interactionItem = i
		break
	pass
func hideCanPickUp():
	interactionItem = null
	$AnimatedSprite2D.hide()
	pass

	
func _process(delta):
	if interactionItem == null:
		hideCanPickUp()
		if $".".has_overlapping_areas():
			for i in $".".get_overlapping_areas():
				if i.get_node("canPickUp"):
					interactionItem = i
	if interactionItem != null:
		showCanPickUp()
		$AnimatedSprite2D.global_position = interactionItem.global_position - Vector2(0,16)
		if !$".".has_overlapping_areas():
			interactionItem = null
