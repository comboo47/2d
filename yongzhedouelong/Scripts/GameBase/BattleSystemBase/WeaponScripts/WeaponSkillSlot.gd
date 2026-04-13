class_name WeaponSkillSlot extends Resource
## 武器技能槽
## 定义武器与技能的关联关系

## 关联技能
@export var skill: SkillBase

## 触发时机
enum TriggerType {
	ON_FIRE,        # 发射时触发
	ON_HIT,         # 命中时触发
	ON_KILL,        # 击杀时触发
	ON_CHARGE_MAX,  # 蓄力满时触发
	ON_ENERGY_EMPTY, # 能量耗尽时触发
}

@export var trigger_type: TriggerType = TriggerType.ON_FIRE

## 触发概率（0.0 - 1.0）
@export var trigger_chance: float = 1.0

## 检查是否满足触发条件
func can_trigger(context: GameplayFlowContext, trigger: TriggerType) -> bool:
	if trigger_type != trigger:
		return false

	if skill == null or not skill.can_use():
		return false

	if trigger_chance < 1.0 and randf() > trigger_chance:
		return false

	return true

## 触发技能
func trigger(skill_manager: SkillManager, context: GameplayFlowContext) -> bool:
	if not can_trigger(context, trigger_type):
		return false

	return skill_manager.use_skill(skill.skill_id, context)

## 获取触发时机名称（调试用）
func get_trigger_type_name() -> String:
	match trigger_type:
		TriggerType.ON_FIRE: return "ON_FIRE"
		TriggerType.ON_HIT: return "ON_HIT"
		TriggerType.ON_KILL: return "ON_KILL"
		TriggerType.ON_CHARGE_MAX: return "ON_CHARGE_MAX"
		TriggerType.ON_ENERGY_EMPTY: return "ON_ENERGY_EMPTY"
		_: return "UNKNOWN"