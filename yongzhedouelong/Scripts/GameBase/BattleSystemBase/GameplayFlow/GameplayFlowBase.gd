class_name GameplayFlowBase extends Resource
## GameplayFlow 流程脚本基类
## Flow 是流程编排脚本，负责：触发时机、执行条件、流程顺序、分支逻辑
## Flow 调用 Action（如 BattleManager.ApplyBuff）来触发 Effect

## 生命周期事件枚举
enum FlowEvent {
	NONE,            # 无触发事件（直接触发模式）
	ON_LEVEL_START,  # 关卡开始时
	ON_WAVE_START,   # 波次开始时
	ON_WAVE_END,     # 波次结束时
	ON_LEVEL_END,    # 关卡结束时
	ON_TIMER,        # 定时触发
	ON_SPAWN,        # 实体生成时
	ON_DEATH,        # 实体死亡时
	ON_HIT,          # 受到伤害时
	ON_KILL,         # 造成击杀时
	ON_SKILL_USE,    # 使用技能时
	ON_BUFF_APPLY,   # Buff 应用时
	ON_BUFF_REMOVE,  # Buff 移除时
}

## 流程 ID（唯一标识）
@export var flow_id: String = ""

## 流程名称（显示用）
@export var flow_name: String = ""

## 触发事件类型（事件触发模式使用）
@export var trigger_event: FlowEvent = FlowEvent.NONE

## 条件表达式（可选，使用 Godot Expression）
## 可用变量: source, target, damage, position, event_data
@export var condition_expression: String = ""

## 缓存的表达式对象
var _cached_expression: Expression = null

## 是否已编译条件
var _condition_compiled: bool = false

## 执行流程入口（子类重写此方法定义流程逻辑）
## 子类在此方法中调用 Action（如 BattleManager.ApplyBuff）
func start(context: GameplayFlowContext) -> void:
	# 检查条件
	if not _check_condition(context):
		return

	# 子类重写此方法，调用 Action
	# 例如：BattleManager.ApplyBuff(context.source, context.target, "buff_fire_damage")
	_execute_flow(context)

## 执行具体流程逻辑（子类重写）
func _execute_flow(context: GameplayFlowContext) -> void:
	# 基类空实现，子类重写
	pass

## 检查条件表达式
func _check_condition(context: GameplayFlowContext) -> bool:
	# 无条件则直接通过
	if condition_expression.is_empty():
		return true

	# 编译表达式（首次）
	if not _condition_compiled:
		_compile_condition()

	# 编译失败则跳过
	if _cached_expression == null:
		push_warning("GameplayFlow '%s' 条件表达式编译失败: %s" % [flow_id, condition_expression])
		return false

	# 执行表达式
	var result = _execute_condition(context)
	if result is bool:
		return result

	push_warning("GameplayFlow '%s' 条件表达式返回非布尔值" % flow_id)
	return false

## 编译条件表达式
func _compile_condition() -> void:
	_cached_expression = Expression.new()
	var parse_result = _cached_expression.parse(condition_expression, ["source", "target", "damage", "position", "event_data"])

	if parse_result != OK:
		push_error("GameplayFlow '%s' 表达式解析错误: %s" % [flow_id, _cached_expression.get_error_text()])
		_cached_expression = null

	_condition_compiled = true

## 执行条件表达式
func _execute_condition(context: GameplayFlowContext) -> Variant:
	var source_ref = context.source
	var target_ref = context.target
	var damage_val = context.get_damage()
	var position_val = context.get_position()
	var event_data_ref = context.event_data

	return _cached_expression.execute([source_ref, target_ref, damage_val, position_val, event_data_ref])

## execute() 是 start() 的别名（兼容旧代码）
func execute(context: GameplayFlowContext) -> void:
	start(context)

## 获取事件名称（调试用）
func get_event_name() -> String:
	match trigger_event:
		FlowEvent.NONE: return "NONE"
		FlowEvent.ON_LEVEL_START: return "ON_LEVEL_START"
		FlowEvent.ON_WAVE_START: return "ON_WAVE_START"
		FlowEvent.ON_WAVE_END: return "ON_WAVE_END"
		FlowEvent.ON_LEVEL_END: return "ON_LEVEL_END"
		FlowEvent.ON_TIMER: return "ON_TIMER"
		FlowEvent.ON_SPAWN: return "ON_SPAWN"
		FlowEvent.ON_DEATH: return "ON_DEATH"
		FlowEvent.ON_HIT: return "ON_HIT"
		FlowEvent.ON_KILL: return "ON_KILL"
		FlowEvent.ON_SKILL_USE: return "ON_SKILL_USE"
		FlowEvent.ON_BUFF_APPLY: return "ON_BUFF_APPLY"
		FlowEvent.ON_BUFF_REMOVE: return "ON_BUFF_REMOVE"
		_: return "UNKNOWN"

## 深度复制（用于实例化）
func deep_duplicate() -> GameplayFlowBase:
	var copy = duplicate(true)
	copy._cached_expression = null
	copy._condition_compiled = false
	return copy