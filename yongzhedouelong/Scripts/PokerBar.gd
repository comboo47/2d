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
	for i in range(5):
		_pickupCard(randi()%12+1,randi()%3)
	_pickupCard(1,0)
	_pickupCard(1,3)
	_pickupCard(13,0)
	_pickupCard(13,3)
	pass # Replace with function body.

func _pickupCard(number,flower):
	$GridContainer.get_child((number-1)*4 + flower).modulate = Color.AQUA
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass
