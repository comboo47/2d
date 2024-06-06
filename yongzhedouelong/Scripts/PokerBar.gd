extends Control
#$GridContainer/TextureRect

# Called when the node enters the scene tree for the first time.
func _ready():
	var path = "res://art/SpriteFrams/UI/card_"
	var file_name = "A_0"
	var file_end = ".tres"
	
	for i in range($GridContainer.get_child_count()):
		var h = i%4
		var v = i/4
		
		file_name = str(v+1)+"_"+str(h) 
		$GridContainer.get_child(i).texture = ResourceLoader.load(path+file_name+file_end)
		$GridContainer.get_child(i).modulate = Color.DIM_GRAY
	
	#测试模块
	#for i in range(5):
		#pickUpCard(randi()%12+1,randi()%3)
	#pickUpCard(1,0)
	#pickUpCard(1,3)
	#pickUpCard(13,0)
	#pickUpCard(13,3)
	pass # Replace with function body.

func pickUpCard(number,flower):
	#$GridContainer.get_child((number-1)*4 + flower).modulate = Color.AQUA
	if number >1 and number <= 5:
		$GridContainer.get_child((number-1)*4 + flower).modulate = Color.WHITE
	if (number >=6 and number <= 9) || (number >=10 and number < 13):
		$GridContainer.get_child((number-1)*4 + flower).modulate = Color.SKY_BLUE
	if number == 10 || number ==1 || number ==13:
		$GridContainer.get_child((number-1)*4 + flower).modulate = Color.ORANGE
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func dropUpCard(number,flower):
	$GridContainer.get_child((number-1)*4 + flower).modulate = Color.DIM_GRAY
	pass
func _process(delta):
	
	pass
