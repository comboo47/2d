extends Node

var interactionItem = null
var displayOn = true
# Called when the node enters the scene tree for the first time.

func showCanPickUp():
	#for i in $".".get_overlapping_areas():
		#if i.get_node("canPickUp"):
			#$AnimatedSprite2D.play()
			#$AnimatedSprite2D.show()
		#interactionItem = i
		#break
	
	$AnimatedSprite2D.play()
	$AnimatedSprite2D.show()
	pass
func hideCanPickUp():
	interactionItem = null
	$AnimatedSprite2D.hide()
	pass


func _process(delta):
	#if displayOn:
	if interactionItem == null:
		hideCanPickUp()
		if $".".has_overlapping_areas():
			for i in $".".get_overlapping_areas():
				if i.get_node("canPickUp") && i.get_node("canPickUp").canPickUp:
					interactionItem = i
					break
	if interactionItem != null:
		showCanPickUp()
		$AnimatedSprite2D.global_position = interactionItem.global_position - Vector2(0,16)
		if interactionItem.get_node("canPickUp") && !interactionItem.get_node("canPickUp").canPickUp:
			interactionItem = null
			hideCanPickUp()
		else:
			if !$".".has_overlapping_areas():
				interactionItem = null
		
