extends LimboState

@export var anim:AnimatedSprite2D
func _enter()->void:
	var tween = $".".create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(anim,"modulate",Color(1, 0, 0, 0.5),0.15)
	await tween.finished
	get_root().dispatch(EVENT_FINISHED)

func _update(_delta: float) -> void:
	
	pass
func _exit() -> void:
	var tween = $".".create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(anim,"modulate",Color.WHITE,0.15)
