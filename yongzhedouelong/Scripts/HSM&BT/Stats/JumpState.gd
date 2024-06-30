extends LimboState

@export var animator:AnimatedSprite2D
@export var animationName:StringName
@export var moveComponent:MoveComponent

func _enter()->void:
	animator.play(animationName)
	moveComponent.tryJump()

func _update(_delta: float) -> void:
	var direction_h = Input.get_axis("left", "right")
	moveComponent.moveDirection.x = direction_h
	if agent.is_on_floor():
		get_root().dispatch(EVENT_FINISHED)
