extends BattleActor

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
		# 显示伤害数字（受伤 Flow 与 ACTOR_HIT 事件已由 DamageResolver 统一触发，此处只管表现）
		if UIManager.instance:
			UIManager.instance.show_damage(self, dmg)

		# 视觉反馈
		hitDisplay()

## 死亡表现完成标志（掉落+动画跑完）。与 _death_flow_done 两路 join 才最终销毁。
var _presentation_done: bool = false

## 死亡表现（由 BattleActor.kill() 调用）。第十一期：表现与最终销毁分离——
## 表现跑完置 _presentation_done 并尝试销毁；有 DeathFlow 时还需等其 finish。
func _on_death(_killer: BattleActor = null) -> void:
	# 关闭碰撞层
	$".".set_collision_layer_value(2,false)
	# 停 AI（延迟销毁期间不再移动/攻击）
	if bt:
		bt.set_active(false)

	# 处理掉落（永远第一时间执行，不依赖 DeathFlow）
	if DropManager.instance:
		DropManager.instance.handle_enemy_death(self)

	# 死亡动画
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($".","scale",Vector2(),0.2)
	await tween.finished

	_presentation_done = true
	_try_final_destroy()

## DeathFlow finish 门控钩子（override 基类）。
func _finish_death() -> void:
	_try_final_destroy()

## 两路 join：无 DeathFlow 仅看表现；有 DeathFlow 需表现+flow 都完成才销毁。
func _try_final_destroy() -> void:
	if not _presentation_done:
		return
	if has_death_flow() and not _death_flow_done:
		return
	$".".queue_free()
