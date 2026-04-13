class_name SkillBase extends Resource
## 技能基类
## 定义技能的基础属性、消耗、冷却和效果

## 技能 ID（唯一标识）
@export var skill_id: String = ""

## 技能名称
@export var skill_name: String = ""

## 技能描述
@export_multiline var skill_description: String = ""

## 技能类型
@export var skill_type: SkillConfig.SkillType = SkillConfig.SkillType.ACTIVE

## 目标类型
@export var target_type: SkillConfig.TargetType = SkillConfig.TargetType.ENEMY_SINGLE

## 目标范围（用于 AREA 类型目标）
@export var target_range: float = 100.0

## 消耗类型
@export var cost_type: SkillConfig.CostType = SkillConfig.CostType.MANA

## 消耗值
@export var cost_value: float = 20.0

## 冷却时间（秒）
@export var cooldown_time: float = 5.0

## 技能效果列表
@export var effects: Array[SkillEffectBase] = []

## 触发条件列表（仅 TRIGGERED 类型使用）
@export var triggers: Array[SkillTrigger] = []

## 关联的 GameplayFlow（可选）
@export var on_use_flow_id: String = ""

## 技能图标路径（UI 显示）
@export var icon_path: String = ""

## 运行时数据
var cooldown: SkillCooldown
var skill_owner: BattleActor = null
var is_active: bool = false  # 用于 TOGGLE 类型

## 初始化技能（由 SkillManager 调用）
func initialize(owner: BattleActor) -> void:
	skill_owner = owner

	# 创建冷却管理器
	cooldown = SkillCooldown.new()
	cooldown.init(cooldown_time)

	# 被动技能立即激活
	if skill_type == SkillConfig.SkillType.PASSIVE:
		activate_passive()

## 是否可以使用
func can_use() -> bool:
	# 检查冷却
	if not cooldown.is_ready():
		return false

	# 检查消耗
	if not _check_cost():
		return false

	# TOGGLE 类型检查是否已激活
	if skill_type == SkillConfig.SkillType.TOGGLE and is_active:
		return true  # 可以关闭

	return true

## 使用技能
func use(context: GameplayFlowContext = null) -> bool:
	if not can_use():
		return false

	# 创建默认上下文
	if context == null:
		context = _create_default_context()

	# 消耗资源
	_consume_cost()

	# TOGGLE 类型特殊处理
	if skill_type == SkillConfig.SkillType.TOGGLE:
		is_active = not is_active
		if is_active:
			_execute_effects(context)
		else:
			_cleanup_effects(context)
		return true

	# 开始冷却
	cooldown.start()

	# 执行效果
	_execute_effects(context)

	# 触发 GameplayFlow
	if not on_use_flow_id.is_empty() and FlowRegistry.instance:
		var flow = FlowRegistry.instance.get_flow(on_use_flow_id)
		if flow:
			flow.execute(context)

	return true

## 检查消耗是否足够
func _check_cost() -> bool:
	if skill_owner == null:
		return false

	if cost_type == SkillConfig.CostType.NONE or cost_type == SkillConfig.CostType.COOLDOWN_ONLY:
		return true

	match cost_type:
		SkillConfig.CostType.MANA:
			var mana = _get_mana()
			return mana >= cost_value
		SkillConfig.CostType.ENERGY:
			# 能量系统需要特殊处理（武器能量）
			return true  # 假设能量足够，由 SkillManager 验证
		SkillConfig.CostType.HP:
			var hp = _get_hp()
			return hp > cost_value  # 需要保留至少 1 HP

	return true

## 消耗资源
func _consume_cost() -> void:
	if skill_owner == null:
		return

	match cost_type:
		SkillConfig.CostType.MANA:
			_subtract_mana(cost_value)
		SkillConfig.CostType.HP:
			_subtract_hp(cost_value)

## 获取法力值
func _get_mana() -> float:
	if skill_owner == null:
		return 0.0
	var attr_comp = skill_owner.GetAttributes()
	if attr_comp == null:
		return 0.0
	var mana_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Mana)
	if mana_attr:
		return mana_attr.computed_value
	return 0.0

## 获取生命值
func _get_hp() -> float:
	if skill_owner == null:
		return 0.0
	var attr_comp = skill_owner.GetAttributes()
	if attr_comp == null:
		return 0.0
	var hp_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Hp)
	if hp_attr:
		return hp_attr.computed_value
	return 0.0

## 减少法力值
func _subtract_mana(amount: float) -> void:
	if skill_owner == null:
		return
	var attr_comp = skill_owner.GetAttributes()
	if attr_comp == null:
		return
	var mana_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Mana)
	if mana_attr:
		mana_attr.sub(amount)

## 减少生命值
func _subtract_hp(amount: float) -> void:
	if skill_owner == null:
		return
	var attr_comp = skill_owner.GetAttributes()
	if attr_comp == null:
		return
	var hp_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Hp)
	if hp_attr:
		hp_attr.sub(amount)

## 创建默认上下文
func _create_default_context() -> GameplayFlowContext:
	var context = GameplayFlowContext.new()
	context.source = skill_owner

	# 根据目标类型设置 target
	match target_type:
		SkillConfig.TargetType.SELF:
			context.target = skill_owner
		SkillConfig.TargetType.NONEAREST_ENEMY:
			context.target = _find_nearest_enemy()
		_:
			# 其他类型需要外部传入目标
			context.target = null

	return context

## 寻找最近敌人
func _find_nearest_enemy() -> BattleActor:
	if skill_owner == null:
		return null

	var enemies = skill_owner.get_tree().get_nodes_in_group("enemy")
	var nearest: BattleActor = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if enemy is BattleActor:
			var dist = skill_owner.global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy

	return nearest

## 执行所有效果
func _execute_effects(context: GameplayFlowContext) -> void:
	# 按优先级排序
	var sorted_effects = effects.duplicate()
	sorted_effects.sort_custom(func(a, b): return a.priority < b.priority)

	for effect in sorted_effects:
		if effect:
			effect.apply(context, self)

## 清理所有效果（用于 TOGGLE 关闭）
func _cleanup_effects(context: GameplayFlowContext) -> void:
	for effect in effects:
		if effect:
			effect.cleanup(context, self)

## 激活被动技能
func activate_passive() -> void:
	if skill_owner == null:
		return
	var context = GameplayFlowContext.create_simple(skill_owner)
	_execute_effects(context)

## 更新冷却
func update_cooldown(delta: float) -> void:
	if cooldown:
		cooldown.update(delta)

## 检查触发条件（用于 TRIGGERED 类型）
func check_trigger(trigger_moment: SkillConfig.TriggerMoment, context: GameplayFlowContext) -> bool:
	if skill_type != SkillConfig.SkillType.TRIGGERED:
		return false

	for trigger in triggers:
		if trigger.trigger_moment == trigger_moment:
			var current_time = Time.get_ticks_msec() / 1000.0
			if trigger.check_trigger(context, current_time):
				return true

	return false

## 获取冷却进度（0.0 - 1.0）
func get_cooldown_progress() -> float:
	if cooldown:
		return cooldown.get_progress()
	return 1.0

## 获取技能描述
func get_full_description() -> String:
	var desc = skill_name + "\n"
	desc += "类型: " + SkillConfig.get_skill_type_name(skill_type) + "\n"

	if cost_type != SkillConfig.CostType.NONE:
		desc += "消耗: " + str(cost_value) + " " + SkillConfig.get_cost_type_name(cost_type) + "\n"

	if cooldown_time > 0:
		desc += "冷却: " + str(cooldown_time) + "秒\n"

	desc += "\n" + skill_description

	return desc