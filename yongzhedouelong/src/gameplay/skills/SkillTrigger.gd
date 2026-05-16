class_name SkillTrigger extends Resource
## 技能触发条件
## 定义触发技能的条件（用于 TRIGGERED 类型技能）

## 触发时机
@export var trigger_moment: SkillConfig.TriggerMoment = SkillConfig.TriggerMoment.ON_ATTACK

## 触发概率（0.0 - 1.0）
@export var trigger_chance: float = 1.0

## 条件表达式（可选）
## 可用变量: source, target, damage, is_crit
@export var condition_expression: String = ""

## 触发间隔（秒，防止频繁触发）
@export var trigger_interval: float = 0.0

## 上次触发时间
var _last_trigger_time: float = 0.0

## 缓存的表达式
var _cached_expression: Expression = null
var _expression_compiled: bool = false

## 检查是否满足触发条件
func check_trigger(context: GameplayFlowContext, current_time: float) -> bool:
	# 检查触发间隔
	if trigger_interval > 0.0 and current_time - _last_trigger_time < trigger_interval:
		return false

	# 检查触发概率
	if trigger_chance < 1.0 and randf() > trigger_chance:
		return false

	# 检查条件表达式
	if not condition_expression.is_empty():
		if not _check_expression(context):
			return false

	# 触发成功，记录时间
	_last_trigger_time = current_time
	return true

## 编译并检查条件表达式
func _check_expression(context: GameplayFlowContext) -> bool:
	if not _expression_compiled:
		_compile_expression()

	if _cached_expression == null:
		return false

	var is_crit = context.event_data.get("is_crit", false)
	var result = _cached_expression.execute([context.source, context.target, context.get_damage(), is_crit])

	if result is bool:
		return result

	return false

## 编译表达式
func _compile_expression() -> void:
	_cached_expression = Expression.new()
	var parse_result = _cached_expression.parse(condition_expression, ["source", "target", "damage", "is_crit"])

	if parse_result != OK:
		push_error("SkillTrigger 表达式解析失败: %s" % _cached_expression.get_error_text())
		_cached_expression = null

	_expression_compiled = true

## 重置触发间隔计时
func reset_interval() -> void:
	_last_trigger_time = 0.0

## 获取触发时机名称（调试用）
func get_trigger_moment_name() -> String:
	match trigger_moment:
		SkillConfig.TriggerMoment.ON_HIT: return "ON_HIT"
		SkillConfig.TriggerMoment.ON_KILL: return "ON_KILL"
		SkillConfig.TriggerMoment.ON_ATTACK: return "ON_ATTACK"
		SkillConfig.TriggerMoment.ON_CRIT: return "ON_CRIT"
		SkillConfig.TriggerMoment.ON_BUFF_APPLY: return "ON_BUFF_APPLY"
		SkillConfig.TriggerMoment.ON_BUFF_REMOVE: return "ON_BUFF_REMOVE"
		SkillConfig.TriggerMoment.ON_SKILL_USE: return "ON_SKILL_USE"
		SkillConfig.TriggerMoment.ON_TIMER: return "ON_TIMER"
		SkillConfig.TriggerMoment.ON_SPAWN: return "ON_SPAWN"
		SkillConfig.TriggerMoment.ON_DEATH: return "ON_DEATH"
		_: return "UNKNOWN"