extends LimboState

@export var animator:AnimatedSprite2D
@export var animationName:StringName


func _enter()->void:
	animator.play(animationName)
