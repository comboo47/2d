class_name GameplayFlowContext extends RefCounted
## GameplayFlow 执行上下文
## 包含触发源、目标和事件数据

## 触发源（谁触发了这个 Flow）
var source: BattleActor = null

## 目标（Flow 作用的对象）
var target: BattleActor = null

## 事件数据字典（伤害值、位置、技能 ID 等）
var event_data: Dictionary = {}

## 获取伤害值
func get_damage() -> float:
	return event_data.get("damage", 0.0)

## 获取位置
func get_position() -> Vector2:
	if event_data.has("position"):
		return event_data["position"]
	if target:
		return target.global_position
	return Vector2.ZERO

## 获取技能 ID
func get_skill_id() -> String:
	return event_data.get("skill_id", "")

## 获取 Buff ID
func get_buff_id() -> String:
	return event_data.get("buff_id", "")

## 设置伤害值
func set_damage(value: float) -> void:
	event_data["damage"] = value

## 设置位置
func set_position(pos: Vector2) -> void:
	event_data["position"] = pos

## 创建简单上下文（仅 source）
static func create_simple(source_actor: BattleActor) -> GameplayFlowContext:
	var ctx = GameplayFlowContext.new()
	ctx.source = source_actor
	ctx.target = source_actor
	return ctx

## 创建攻击上下文（source 攻击 target）
static func create_attack(source_actor: BattleActor, target_actor: BattleActor, damage: float = 0.0) -> GameplayFlowContext:
	var ctx = GameplayFlowContext.new()
	ctx.source = source_actor
	ctx.target = target_actor
	ctx.event_data["damage"] = damage
	return ctx

## 创建位置上下文（带位置信息）
static func create_at_position(pos: Vector2, source_actor: BattleActor = null) -> GameplayFlowContext:
	var ctx = GameplayFlowContext.new()
	ctx.source = source_actor
	ctx.event_data["position"] = pos
	return ctx