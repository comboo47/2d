extends Area2D
class_name BodyArea

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


func getActorAreaType()->int:
	return actorAreaType

func _physics_process(delta):
	if slide:
		slideTimeIndex += delta
		$".".get_parent().velocity.x = (direction*velocityX).x
		
		$".".get_parent().move_and_slide()
		if slideTimeIndex >= slideTime:
			slide = false
			
			
			slideTimeIndex = 0
	pass

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
					direction = ($".".global_position - area.global_position).normalized() 
					$".".get_parent().velocity.y = (direction*velocityY).y
					slide = true
		if actorAreaType == 1:
			print(actorAreaType,",",areaType)
			match areaType:
				0:
					direction = ($".".global_position - area.global_position).normalized() 
					$".".get_parent().velocity.y = (direction*velocityY).y
					#slide = true
				1:#对方是怪物
					pass	
		pass # Replace with function body.

	
