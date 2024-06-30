extends CharacterBody2D

var isDead:bool = false


@export var EnemyID = 1001
@onready var move_component:MoveComponent = $MoveComponent as MoveComponent
@onready var animated_sprite_2d:AnimatedSprite2D = $AnimatedSprite2D as AnimatedSprite2D
@onready var body_area:BodyArea = $BodyArea as BodyArea
@onready var hurt_display_component:HurtDisplayComponent = $HurtDisPlay as HurtDisplayComponent
@onready var stats:BattleStats = $BattleStats as BattleStats


func _ready():
	pass

func getID():
	return EnemyID
# Get the gravity from the project settings to be synced with RigidBody nodes.

func hitDisplay():
	animated_sprite_2d.modulate.a = (float(stats.curHp)/float(stats.curMaxHp))
	hurt_display_component.hitDisplay()

func _beHurt(dmg):
	stats.curHp = stats.curHp - dmg
	if(stats.curHp <= 0):
		if !isDead:
			setDead()
	hitDisplay()
func setDead():
	isDead = true
	$".".set_collision_layer_value(2,false)
	if get_node("/root/DropManager"):
		get_node("/root/DropManager").dropPoker(self)
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($".","scale",Vector2(),0.2)
	await tween.finished
	$".".queue_free()
	pass
