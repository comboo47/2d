class_name BuffManager extends Node

var buffList:Array[AttributeBuff]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.


func _OnBuffApply()->void:
	for item in buffList:
		item.buff_excute()
		print(item.buff_name)
	pass
func _OnBuffRemove()->void:
	pass
	
