extends LimboState

@export var animator:AnimatedSprite2D
@export var animationName:StringName

func _enter()->void:
	animator.play(animationName)

func _update(_delta: float) -> void:
	var horizontal_move: float = Input.get_axis("left", "right")
	var vertical_move: float = Input.get_axis(&"move_up", &"move_down")
	if horizontal_move != 0.0 or vertical_move != 0.0:
		get_root().dispatch(EVENT_FINISHED)
