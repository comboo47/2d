class_name SkillConfig
## 技能配置常量
## 定义技能类型、目标类型、消耗类型等枚举

## 技能类型枚举
enum SkillType {
	ACTIVE,          # 主动技能（玩家手动触发）
	PASSIVE,         # 被动技能（自动生效，如属性加成）
	TRIGGERED,       # 触发技能（条件触发，如暴击触发、受伤触发）
	TOGGLE,          # 开关技能（持续效果，可开关）
}

## 目标类型枚举
enum TargetType {
	SELF,            # 自身
	ENEMY_SINGLE,    # 单个敌人
	ENEMY_AREA,      # 区域内的敌人
	ALLY_SINGLE,     # 单个友方
	ALLY_AREA,       # 区域内的友方
	DIRECTION,       # 指定方向
	POSITION,        # 指定位置
	NONEAREST_ENEMY, # 最近敌人
}

## 消耗类型枚举
enum CostType {
	MANA,            # 法力值
	ENERGY,          # 武器能量（弩枪系统）
	HP,              # 生命值（血祭类技能）
	COOLDOWN_ONLY,   # 仅冷却时间消耗
	NONE,            # 无消耗
}

## 触发时机枚举（用于 TRIGGERED 类型）
enum TriggerMoment {
	ON_HIT,          # 受伤时
	ON_KILL,         # 击杀时
	ON_ATTACK,       # 攻击时
	ON_CRIT,         # 暴击时
	ON_BUFF_APPLY,   # Buff 应用时
	ON_BUFF_REMOVE,  # Buff 移除时
	ON_SKILL_USE,    # 使用技能时
	ON_TIMER,        # 定时触发
	ON_SPAWN,        # 生成时
	ON_DEATH,        # 死亡时
}

## 技能槽位枚举
enum SkillSlot {
	PRIMARY,         # 主技能槽（通常绑定武器）
	SECONDARY,       # 副技能槽
	ULTIMATE,        # 终极技能槽
	PASSIVE_SLOT,    # 被动技能槽（可多个）
}

## 默认冷却时间（秒）
const DEFAULT_COOLDOWN := {
	SkillType.ACTIVE: 5.0,
	SkillType.TRIGGERED: 0.0,
	SkillType.PASSIVE: 0.0,
	SkillType.TOGGLE: 10.0,
}

## 默认消耗值
const DEFAULT_COST := {
	CostType.MANA: 20.0,
	CostType.ENERGY: 30.0,
	CostType.HP: 0.0,
	CostType.COOLDOWN_ONLY: 0.0,
	CostType.NONE: 0.0,
}

## 获取技能类型名称（调试用）
static func get_skill_type_name(skill_type: SkillType) -> String:
	match skill_type:
		SkillType.ACTIVE: return "ACTIVE"
		SkillType.PASSIVE: return "PASSIVE"
		SkillType.TRIGGERED: return "TRIGGERED"
		SkillType.TOGGLE: return "TOGGLE"
		_: return "UNKNOWN"

## 获取目标类型名称（调试用）
static func get_target_type_name(target_type: TargetType) -> String:
	match target_type:
		TargetType.SELF: return "SELF"
		TargetType.ENEMY_SINGLE: return "ENEMY_SINGLE"
		TargetType.ENEMY_AREA: return "ENEMY_AREA"
		TargetType.ALLY_SINGLE: return "ALLY_SINGLE"
		TargetType.ALLY_AREA: return "ALLY_AREA"
		TargetType.DIRECTION: return "DIRECTION"
		TargetType.POSITION: return "POSITION"
		TargetType.NONEAREST_ENEMY: return "NONEAREST_ENEMY"
		_: return "UNKNOWN"

## 获取消耗类型名称（调试用）
static func get_cost_type_name(cost_type: CostType) -> String:
	match cost_type:
		CostType.MANA: return "MANA"
		CostType.ENERGY: return "ENERGY"
		CostType.HP: return "HP"
		CostType.COOLDOWN_ONLY: return "COOLDOWN_ONLY"
		CostType.NONE: return "NONE"
		_: return "UNKNOWN"
