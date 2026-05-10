class_name Flow_EnemySpawn extends GameplayFlowBase
## 敌人生成流程
## 演示 Flow 如何定义生成逻辑

## 敌人等级（可配置）
@export var enemy_level: int = 1

func _execute_flow(context: GameplayFlowContext) -> void:
	var enemy = context.source

	# 1. 播放生成特效（Action: 播放 VFX）
	if VfxManager.instance:
		var spawn_position = enemy.global_position + Vector2(0, -10)
		VfxManager.instance.play_vfx(VfxConfig.VfxType.SPAWN_EFFECT, spawn_position)

	# 2. 根据等级分支逻辑
	if enemy_level >= 5:
		# 高级敌人：播放额外特效
		_spawn_high_level_effect(enemy)
	else:
		# 普通敌人：仅基础特效
		_spawn_normal_effect(enemy)

	# 3. 初始化敌人属性（Action: 修改属性）
	_init_enemy_attributes(enemy)

func _spawn_high_level_effect(enemy: BattleActor) -> void:
	# 分支：高级敌人有额外光环特效
	if VfxManager.instance:
		VfxManager.instance.play_vfx_follow(VfxConfig.VfxType.AURA_EFFECT, enemy, Vector2(0, 0))

func _spawn_normal_effect(enemy: BattleActor) -> void:
	# 分支：普通敌人无额外特效
	pass

func _init_enemy_attributes(enemy: BattleActor) -> void:
	# Action: 初始化敌人属性
	if enemy == null:
		return

	# 根据等级设置 HP
	var base_hp = 100.0 * enemy_level
	var attr_comp = enemy.GetAttributes()
	if attr_comp:
		var hp_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Hp)
		if hp_attr:
			hp_attr.base_value = base_hp
