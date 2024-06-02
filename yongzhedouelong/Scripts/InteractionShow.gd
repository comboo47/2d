extends Node

var interactionItem:Node = null
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
	var interactionList:Array
	if interactionItem == null:
		hideCanPickUp()
		if $".".has_overlapping_areas():
			for i in $".".get_overlapping_areas():
				if i.get_node("canPickUp") && i.get_node("canPickUp").canPickUp:
					interactionItem = i
					break
	if interactionItem != null:
		showCanPickUp()
		if $".".has_overlapping_areas():
			for i in $".".get_overlapping_areas():
				if i.get_node("canPickUp") && i.get_node("canPickUp").canPickUp:
					interactionList.append(i)
			if interactionList.size() > 0:
				var dis = float(999)
				var item:Node
				for j in interactionList:
					var disTemp
					disTemp = Vector2(j.global_position - $".".get_parent().global_position).length()
					if disTemp< dis:
						item = j
						dis = disTemp
					#print("item:",j.name,"   distance:",disTemp,"   dis:",dis)
				interactionItem = item
		$AnimatedSprite2D.global_position = interactionItem.global_position - Vector2(0,16)
		if interactionItem.get_node("canPickUp") && !interactionItem.get_node("canPickUp").canPickUp:
			interactionItem = null
			hideCanPickUp()
		else:
			if !$".".has_overlapping_areas():
				interactionItem = null
		
