extends BattleActor

var isDead:bool = false

@export var EnemyID = 1001
## 掉落表 ID（从配置加载）
@export var drop_table_id: String = ""

@onready var move_component:MoveComponent = $MoveComponent as MoveComponent
@onready var body_area:BodyArea = $BodyArea as BodyArea
@onready var hurt_display_component:HurtDisplayComponent = $HurtDisPlay as HurtDisplayComponent
@onready var atc:AttributeComponent = $AttributeComponent as AttributeComponent
@export var bt:BehaviorTree

func _ready():
	# 绑定 HP 变化监听
	if atc.find_attribute(AttributeConfig.AttributeName.Hp):
		atc.find_attribute(AttributeConfig.AttributeName.Hp).attribute_changed.connect(_beHurt)

	# 激活 BehaviorTree
	if bt:
		bt.set_active(true)

	# 触发生成 Flow
	trigger_spawn_flow()

func getID():
	return EnemyID

## 获取掉落表 ID
func get_drop_table_id() -> String:
	return drop_table_id

## 设置敌人 ID
func set_enemy_id(id: int) -> void:
	EnemyID = id

func hitDisplay():
	hurt_display_component.hitDisplay()

func _beHurt(_attribute:Attribute,_oldvalue:float,_newvalue:float):
	var dmg = _oldvalue - _newvalue  # 伤害为正数
	if dmg > 0:
		# 显示伤害数字
		if UIManager.instance:
			UIManager.instance.show_damage(self, dmg)

		# 触发受伤 Flow
		trigger_hit_flow(dmg)

		# 视觉反馈
		hitDisplay()

func setDead():
	if isDead:
		return  # 防止重复调用

	isDead = true

	# 触发死亡 Flow
	trigger_death_flow()

	# 关闭碰撞层
	$".".set_collision_layer_value(2,false)

	# 处理掉落
	if DropManager.instance:
		DropManager.handle_enemy_death(self)

	# 死亡动画
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($".","scale",Vector2(),0.2)
	await tween.finished

	$".".queue_free()
