class_name BuffManager extends Node

var buffList:Array[AttributeBuff]
var waitToRemove:Array[AttributeBuff]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta: float) -> void:
	pass
func _physics_process(delta: float) -> void:
	for buff in buffList:
		buff.run_process(delta)
		if buff.is_pending_remove:
			waitToRemove.append(buff)
	for buff in waitToRemove:
		buffList.erase(buff)
	waitToRemove.clear()

func _OnBuffApply()->void:

	pass
func _OnBuffRemove()->void:
	pass
	
