extends LimboState

@export var animator:AnimatedSprite2D
@export var animationName:StringName
@export var moveComponent:MoveComponent
var fx:Node2D
var fx2:Node2D
@export var fx_jump:PackedScene
func _enter()->void:
	animator.play(animationName)
	moveComponent.tryJump()
	if fx == null:
		fx = fx_jump.instantiate()
		#fx.global_position = animator.get_parent().global_position
		animator.get_parent().add_child(fx)
		fx.position = Vector2(0,12)
		animator.get_parent().get_node("Node2D/GPUParticles2D").restart()
	else:
		animator.get_parent().get_node("Node2D/GPUParticles2D").restart()
	
	

func _update(_delta: float) -> void:
	
	var direction_h = Input.get_axis("left", "right")
	moveComponent.moveDirection.x = direction_h
	if agent.is_on_floor():
		get_root().dispatch(EVENT_FINISHED)


func _on_exited() -> void:
	if fx2 == null:
		fx2 = fx_jump.instantiate()
		#fx.global_position = animator.get_parent().global_position
		animator.get_parent().add_child(fx2)
		fx2.position = Vector2(0,12)
		animator.get_parent().get_node("Node2D/GPUParticles2D").restart()
	else:
		animator.get_parent().get_node("Node2D/GPUParticles2D").restart()
	pass # Replace with function body.
