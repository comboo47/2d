class_name SkillManager extends Node
## 技能管理器
## 挂载在 BattleActor 上，管理角色的所有技能

## 技能列表
var skills: Array[SkillBase] = []

## 按类型分类
var active_skills: Array[SkillBase] = []
var passive_skills: Array[SkillBase] = []
var triggered_skills: Array[SkillBase] = []
var toggle_skills: Array[SkillBase] = []

## 技能拥有者
var skill_owner: BattleActor = null

## 技能槽位映射 {SkillSlot: SkillBase}
var skill_slots: Dictionary = {}

## 信号
signal skill_used(skill: SkillBase)
signal skill_cooldown_finished(skill: SkillBase)
signal skill_triggered(skill: SkillBase, trigger_moment: SkillConfig.TriggerMoment)

func _ready() -> void:
	# 获取父节点作为技能拥有者
	skill_owner = get_parent() as BattleActor

func _physics_process(delta: float) -> void:
	# 更新所有技能的冷却
	for skill in skills:
		skill.update_cooldown(delta)

#region 公共 API - 技能添加
## 添加技能
func add_skill(skill: SkillBase, slot: SkillConfig.SkillSlot = SkillConfig.SkillSlot.SECONDARY) -> void:
	if skill == null:
		return

	# 创建实例副本
	var instance = skill.duplicate(true)
	instance.initialize(skill_owner)

	skills.append(instance)

	# 按类型分类
	match instance.skill_type:
		SkillConfig.SkillType.ACTIVE: active_skills.append(instance)
		SkillConfig.SkillType.PASSIVE: passive_skills.append(instance)
		SkillConfig.SkillType.TRIGGERED: triggered_skills.append(instance)
		SkillConfig.SkillType.TOGGLE: toggle_skills.append(instance)

	# 设置槽位
	skill_slots[slot] = instance

	# 连接冷却完成信号
	instance.cooldown.cooldown_finished.connect(_on_skill_cooldown_finished.bind(instance))

## 添加多个技能
func add_skills(skill_list: Array[SkillBase]) -> void:
	for i in range(skill_list.size()):
		var slot = SkillConfig.SkillSlot.SECONDARY if i < 3 else SkillConfig.SkillSlot.PASSIVE_SLOT
		add_skill(skill_list[i], slot)

## 移除技能
func remove_skill(skill_id: String) -> void:
	for skill in skills:
		if skill.skill_id == skill_id:
			_remove_skill_from_lists(skill)
			skills.erase(skill)
			break

## 清空所有技能
func clear_skills() -> void:
	skills.clear()
	active_skills.clear()
	passive_skills.clear()
	triggered_skills.clear()
	toggle_skills.clear()
	skill_slots.clear()
#endregion

#region 公共 API - 技能使用
## 使用主动技能（按 ID）
func use_skill(skill_id: String, context: GameplayFlowContext = null) -> bool:
	for skill in active_skills:
		if skill.skill_id == skill_id:
			return _use_skill_internal(skill, context)

	for skill in toggle_skills:
		if skill.skill_id == skill_id:
			return _use_skill_internal(skill, context)

	return false

## 使用槽位技能
func use_slot_skill(slot: SkillConfig.SkillSlot, context: GameplayFlowContext = null) -> bool:
	var skill = skill_slots.get(slot)
	if skill:
		return _use_skill_internal(skill, context)
	return false

## 内部使用技能
func _use_skill_internal(skill: SkillBase, context: GameplayFlowContext) -> bool:
	if skill.use(context):
		skill_used.emit(skill)
		return true
	return false

## 检查技能是否可用
func can_use_skill(skill_id: String) -> bool:
	for skill in skills:
		if skill.skill_id == skill_id:
			return skill.can_use()
	return false

## 检查槽位技能是否可用
func can_use_slot(slot: SkillConfig.SkillSlot) -> bool:
	var skill = skill_slots.get(slot)
	if skill:
		return skill.can_use()
	return false
#endregion

#region 公共 API - 触发技能处理
## 处理触发事件（由 BattleActor 调用）
func handle_trigger_event(trigger_moment: SkillConfig.TriggerMoment, context: GameplayFlowContext) -> void:
	for skill in triggered_skills:
		if skill.check_trigger(trigger_moment, context):
			# 触发技能自动使用
			if skill.use(context):
				skill_triggered.emit(skill, trigger_moment)
#endregion

#region 公共 API - 技能查询
## 根据 ID 获取技能
func get_skill(skill_id: String) -> SkillBase:
	for skill in skills:
		if skill.skill_id == skill_id:
			return skill
	return null

## 获取槽位技能
func get_slot_skill(slot: SkillConfig.SkillSlot) -> SkillBase:
	return skill_slots.get(slot)

## 获取所有可用技能
func get_available_skills() -> Array[SkillBase]:
	var available: Array[SkillBase] = []
	for skill in active_skills + toggle_skills:
		if skill.can_use():
			available.append(skill)
	return available

## 获取技能数量
func get_skill_count() -> int:
	return skills.size()
#endregion

#region 公共 API - 技能信息
## 获取技能冷却进度
func get_skill_cooldown_progress(skill_id: String) -> float:
	var skill = get_skill(skill_id)
	if skill:
		return skill.get_cooldown_progress()
	return 1.0

## 获取槽位技能冷却进度
func get_slot_cooldown_progress(slot: SkillConfig.SkillSlot) -> float:
	var skill = skill_slots.get(slot)
	if skill:
		return skill.get_cooldown_progress()
	return 1.0
#endregion

#region 内部方法
## 从分类列表中移除技能
func _remove_skill_from_lists(skill: SkillBase) -> void:
	active_skills.erase(skill)
	passive_skills.erase(skill)
	triggered_skills.erase(skill)
	toggle_skills.erase(skill)

	# 从槽位移除
	for slot in skill_slots.keys():
		if skill_slots[slot] == skill:
			skill_slots.erase(slot)

## 技能冷却完成回调
func _on_skill_cooldown_finished(skill: SkillBase) -> void:
	skill_cooldown_finished.emit(skill)
#endregion