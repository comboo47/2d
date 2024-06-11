extends Area2D
class_name BodyArea

@export var movementComponent:MoveComponent

var actorAreaType = int(1)
var velocityX = float(30)
var velocityY = float(100)
var enteredArea
var slide = false
var direction:Vector2
var slideTime = float(0.25)
var slideTimeIndex = float(0)

# Called when the node enters the scene tree for the first time.
func _ready():
	$".".set_collision_layer_value(13,true)
	$".".set_collision_mask_value(13,true)
	if $".".get_parent().is_in_group("Player"):
		actorAreaType = 0
	if $".".get_parent().is_in_group("Mob"):
		actorAreaType = 1
	pass # Replace with function body.

func _process(delta):
	if $".".get_overlapping_areas():
		for a in $".".get_overlapping_areas():
			if a.has_method("getActorAreaType"):
				var areaType = a.getActorAreaType()
				if actorAreaType == 0:
					print(actorAreaType,",",areaType)
					match areaType:
						0:
							pass
						1:#对方是怪物
							var dis = $".".global_position.distance_to(a.global_position)
							dis = 16/dis
							direction = ($".".global_position - a.global_position).normalized() * dis
							movementComponent.hitBackSmall(direction,Vector2(40,120),0.3)
				if actorAreaType == 1:
					print(actorAreaType,",",areaType)
					match areaType:
						0:
							pass#slide = true
						1:#对方是怪物
							var dis = $".".global_position.distance_to(a.global_position)
							dis = 16/dis
							direction = ($".".global_position - a.global_position).normalized() * dis
							movementComponent.hitBackSmall(direction,Vector2(15,15),0.15)
							pass						

func getActorAreaType()->int:
	return actorAreaType

func _on_area_entered(area):
	if area.has_method("getActorAreaType"):
		enteredArea = area
		var areaType = area.getActorAreaType()
		if actorAreaType == 0:
			print(actorAreaType,",",areaType)
			match areaType:
				0:
					pass
				1:#对方是怪物
	
					var dis = $".".global_position.distance_to(area.global_position)
					dis = 16/dis
					direction = ($".".global_position - area.global_position).normalized() * dis
					movementComponent.hitBackSmall(direction,Vector2(40,120),0.3)

					slide = true
		if actorAreaType == 1:
			print(actorAreaType,",",areaType)
			match areaType:
				0:
					
					pass#slide = true
				1:#对方是怪物
					var dis = $".".global_position.distance_to(area.global_position)
					dis = 16/dis
					direction = ($".".global_position - area.global_position).normalized() * dis
					movementComponent.hitBackSmall(direction,Vector2(15,15),0.15)
					pass	
		pass # Replace with function body.

	
