extends Node
@export var number = 1
@export var flower = 1
@export var color = Color.YELLOW
@export var timeIndex = float(1)

var picker = null
# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.wait_time = timeIndex
	setCardDisplay(number,flower)
	$Timer.start()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
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
	flower = randi() % 3
	setCardDisplay(number,flower)

func pickEffect(node):
	$Timer.stop()
	$EndTimer.start()
	picker = node

func _on_end_timer_timeout():
	picker.addPoker(number,flower)
	pass # Replace with function body.
