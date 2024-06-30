extends LimboState


const VERTICAL_FACTOR := 0.8
@export var moveComponent:MoveComponent
@export var animator: AnimatedSprite2D
@export var animation: StringName
@export var speed: float = 500.0


func _enter() -> void:
	animator.play(animation)
	
func _update(_delta: float) -> void:
	var direction_h = Input.get_axis("left", "right")
	moveComponent.moveDirection.x = direction_h
	if direction_h == 0.0:
		get_root().dispatch(EVENT_FINISHED)
