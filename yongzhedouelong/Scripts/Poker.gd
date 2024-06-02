extends Node
@export var number = 1
@export var flower = 4
@export var color = Color.YELLOW
@export var timeIndex = float(1)

var picker = null
var onTween = false
var oriPosition
# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.wait_time = timeIndex
	setCardDisplay(number,flower)
	$Timer.start()
	if flower == 4:
		flower = randi() % 3
	dropDisplay()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if onTween:
		$".".position = oriPosition + $Path2D/PathFollow2D.position
		print($Path2D/PathFollow2D.position)
	
	pass
func setCardDisplay(number,flower):
	number = clamp(number,1,13)
	flower = clamp(flower,0,3)
	var path = "res://art/SpriteFrams/UI/card_"
	var file_name = "A_0"
	var file_end = ".tres"
		
	file_name = str(number)+"_"+str(flower) 
	$Sprite2D.texture = ResourceLoader.load(path+file_name+file_end)
	if number >1 && number <= 5:
		$Sprite2D.modulate = Color.WHITE
	if (number >=6 && number <= 9) || (number >=10 && number < 13):
		$Sprite2D.modulate = Color.SKY_BLUE
	if number == 10 || number ==1 || number ==13:
		$Sprite2D.modulate = Color.ORANGE
func randomCard():
	number = randi() % 12+1
	setCardDisplay(number,flower)

func pickEffect(node):
	$Timer.stop()
	$EndTimer.start()
	picker = node

func _on_end_timer_timeout():
	picker.addPoker(number,flower)
	pass # Replace with function body.
	
func dropDisplay():
	oriPosition = $".".position
	onTween = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($Path2D/PathFollow2D,"progress_ratio",float(1.0),0.5)
	await tween.finished
	onTween = false
	pass
func _cubic_bezier(ctrole0: Vector2, ctrole1: Vector2, t: float):
	var p0 = Vector2(0,0)
	var p3 = Vector2(1,1)
	var p1 = p0 + ctrole0
	var p2 = p3 - ctrole1
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var q2 = p2.lerp(p3, t)

	var r0 = q0.lerp(q1, t)
	var r1 = q1.lerp(q2, t)

	var s = r0.lerp(r1, t)
	return s
