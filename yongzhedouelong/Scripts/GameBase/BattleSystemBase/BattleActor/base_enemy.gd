extends BattleActor

var isDead:bool = false


@export var EnemyID = 1001
@onready var move_component:MoveComponent = $MoveComponent as MoveComponent
@onready var body_area:BodyArea = $BodyArea as BodyArea
@onready var hurt_display_component:HurtDisplayComponent = $HurtDisPlay as HurtDisplayComponent
@onready var atc:AttributeComponent = $AttributeComponent as AttributeComponent
@export var bt:BehaviorTree

func _ready():
	if atc.find_attribute(AttributeConfig.AttributeName.Hp):
		atc.find_attribute(AttributeConfig.AttributeName.Hp).attribute_changed.connect(_beHurt)
	
	if bt:
		bt.set_active(true)
	pass

func getID():
	return EnemyID
# Get the gravity from the project settings to be synced with RigidBody nodes.

func hitDisplay():
	
	hurt_display_component.hitDisplay()

func _beHurt(_attribute:Attribute,_oldvalue:float,_newvalue:float):
	var dmg = _oldvalue - _newvalue  # 伤害为正数
	if dmg > 0:
		UIManager.instance.show_damage(self, dmg)
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
