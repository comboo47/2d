extends LimboState


const VERTICAL_FACTOR := 0.8
@export var moveComponent:MoveComponent
@export var animator: AnimatedSprite2D
@export var animation: StringName
@export var speed: float = 500.0
@export var fx_movedust: GPUParticles2D

func _enter() -> void:
	animator.play(animation)
	
	fx_movedust.amount_ratio = 1
	fx_movedust.restart()
	
	
func _update(_delta: float) -> void:
	var direction_h = Input.get_axis("left", "right")
	moveComponent.moveDirection.x = direction_h
	
	if direction_h == 0.0:
		get_root().dispatch(EVENT_FINISHED)


func _on_exited() -> void:
	fx_movedust.amount_ratio = 0	
	pass # Replace with function body.
