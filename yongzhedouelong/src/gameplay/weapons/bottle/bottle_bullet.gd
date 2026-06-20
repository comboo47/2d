extends BulletBase
## 瓶子子弹：命中即范围爆炸（BoomArea 内全体结算）+ 爆炸动画后销毁。
## 共享逻辑（hurt_somebody/_releaseSelf/apply_definition/运动）在 BulletBase。
## 保留自身的命中分发与 boomDisplay()，行为与改造前一致。

## 飞行速度（保留在子类：weapon_base._ready 读取它作为 base_speed 默认；bottle=300）。
@export var speed = 300

@onready var a = $"."

func _ready():
	$AnimatedSprite2D.play("default")

func _physics_process(delta):
	# 先驱动可选运动策略（无 definition 时为空操作），再让朝向跟随速度。
	super._physics_process(delta)
	$".".look_at($".".linear_velocity)

func _on_bullet_hit(body: Node):
	_explode()

func _on_body_entered(body):
	_explode()

## 范围结算：对 BoomArea 内所有目标造成伤害，然后播放爆炸表现。
func _explode() -> void:
	var boomBody = $BoomArea.get_overlapping_bodies()
	for i in boomBody:
		hurt_somebody(i)
	boomDisplay()

func boomDisplay():
	$".".set_deferred("freeze_mode", 1)
	$".".set_deferred("freeze", true)
	$BoomAnimated.visible = true
	$BoomAnimated.rotation = randf()
	$BoomAnimated.play("default")
	$AnimatedSprite2D.visible = false
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	var colorValue = $BoomAnimated.modulate
	colorValue.a = 0.2
	tween.tween_property($BoomAnimated, "scale", Vector2(2, 2), 0.35)
	tween.tween_property($BoomAnimated, "modulate", colorValue, 0.25)
	await tween.finished
	_releaseSelf()
