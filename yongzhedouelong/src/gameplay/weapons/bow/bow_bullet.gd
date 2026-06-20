extends BulletBase
## 弓箭/弩枪子弹（bullet_crossbow.tscn 复用本脚本）。
## 共享逻辑（hurt_somebody/_releaseSelf/apply_definition/运动）在 BulletBase。

## 飞行速度（保留在子类：weapon_base._ready 读取它作为 base_speed 默认；bow=250）。
@export var speed = 250

func _ready():
	$AnimatedSprite2D.play("default")

func _physics_process(delta):
	# 驱动可选运动策略（无 definition 时为空操作，与原 pass 等价）。
	super._physics_process(delta)

## Area2D 命中敌人 → 数据驱动结算（默认 pierce=0 即命中销毁，行为同改造前）。
func _on_bullet_hit(body: Node):
	_on_hit(body)

## 本体撞到墙/地面 → 仅销毁（保持原行为：不结算伤害）。
func _on_body_entered(body):
	_releaseSelf()
