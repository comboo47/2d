extends RayCast2D

var isHit = false
var hitPoint = Vector2()
var onTween = false
var oriPosition
var parent
func _ready():
	parent = $".".get_parent()
	pass

func _process(delta):
	pass
	#print($".".get_collider().name)
func _physics_process(delta):
	if !isHit:
		if $".".get_collider() != null:
			if $".".get_collider().name == "TileMap":
				hitPoint = $".".get_collision_point() + Vector2(0,-8)
				isHit = true
				dropDisplayOn()
	if onTween:
		$".".get_parent().position = oriPosition + $Path2D/PathFollow2D.position
		pass
	pass
	#print($".".get_collision_point())
func dropDisplayOn():
	$".".get_parent().global_position = hitPoint
	onTween =true
	print(parent.name)
	oriPosition = $".".get_parent().position
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($Path2D/PathFollow2D,"progress_ratio",float(1.0),0.5)
	await tween.finished
	onTween = false
