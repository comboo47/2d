extends CharacterBody2D
class_name BattleActor

@export var Eattribute:AttributeComponent
var attribute
var buffManager:BuffManager = BuffManager.new()

#region Flow 系统
## SkillManager（可选，由子类添加）
var skill_manager: SkillManager = null

## 生命周期 Flow ID（可选）
var spawn_flow_id: String = ""
var death_flow_id: String = ""
var hit_flow_id: String = ""
var kill_flow_id: String = ""

## Flow 系统信号
signal actor_spawned(actor: BattleActor)
signal actor_died(actor: BattleActor)
signal actor_hit(actor: BattleActor, damage: float, source: BattleActor)
signal actor_kill(actor: BattleActor, target: BattleActor)
#endregion

func _enter_tree() -> void:
	self.add_child(buffManager)

func SetAttributes(atc:AttributeComponent) -> void:
	attribute = atc
	self.set_meta("Attribute",attribute)

func GetAttributes() -> AttributeComponent:
	if attribute != null:
		return attribute
	else:
		attribute = Eattribute
		return attribute

#region Flow 系统接口
## 触发生成 Flow
func trigger_spawn_flow() -> void:
	var registry = _get_flow_registry()
	if spawn_flow_id.is_empty() or registry == null:
		return

	var flow = registry.get_flow(spawn_flow_id)
	if flow:
		var context = GameplayFlowContext.create_simple(self)
		flow.execute(context)

	actor_spawned.emit(self)

## 触发死亡 Flow
func trigger_death_flow() -> void:
	var registry = _get_flow_registry()
	if death_flow_id.is_empty() or registry == null:
		return

	var flow = registry.get_flow(death_flow_id)
	if flow:
		var context = GameplayFlowContext.new()
		context.source = self
		context.target = self
		context.event_data["position"] = global_position
		flow.execute(context)

	actor_died.emit(self)

## 触发受伤 Flow
func trigger_hit_flow(damage: float, source: BattleActor = null) -> void:
	var registry = _get_flow_registry()
	if hit_flow_id.is_empty() or registry == null:
		return

	var flow = registry.get_flow(hit_flow_id)
	if flow:
		var context = GameplayFlowContext.new()
		context.source = source
		context.target = self
		context.event_data["damage"] = damage
		context.event_data["position"] = global_position
		flow.execute(context)

	actor_hit.emit(self, damage, source)

## 触发击杀 Flow
func trigger_kill_flow(target: BattleActor) -> void:
	var registry = _get_flow_registry()
	if kill_flow_id.is_empty() or registry == null:
		return

	var flow = registry.get_flow(kill_flow_id)
	if flow:
		var context = GameplayFlowContext.new()
		context.source = self
		context.target = target
		context.event_data["position"] = target.global_position
		flow.execute(context)

	actor_kill.emit(self, target)

## 处理触发技能事件（由 SkillManager 调用）
func handle_skill_trigger(trigger_moment: SkillConfig.TriggerMoment, context: GameplayFlowContext) -> void:
	if skill_manager:
		skill_manager.handle_trigger_event(trigger_moment, context)
#endregion

#region SkillManager 接口
## 添加技能管理器
func add_skill_manager() -> SkillManager:
	if skill_manager == null:
		skill_manager = SkillManager.new()
		add_child(skill_manager)
	return skill_manager

## 获取技能管理器
func get_skill_manager() -> SkillManager:
	return skill_manager

## 添加技能
func add_skill(skill: SkillBase, slot: SkillConfig.SkillSlot = SkillConfig.SkillSlot.SECONDARY) -> void:
	if skill_manager:
		skill_manager.add_skill(skill, slot)
	else:
		push_warning("BattleActor: 无 SkillManager，无法添加技能")

## 使用技能
func use_skill(skill_id: String, context: GameplayFlowContext = null) -> bool:
	if skill_manager:
		return skill_manager.use_skill(skill_id, context)
	return false
#endregion

#region Vfx 系统接口
## 播放特效（便捷方法）
func play_vfx(vfx_type: VfxConfig.VfxType, offset: Vector2 = Vector2.ZERO) -> void:
	var vfx_manager = get_tree().root.get_node_or_null("VfxManager") if is_inside_tree() else null
	if vfx_manager and vfx_manager.has_method("play_vfx"):
		vfx_manager.play_vfx(vfx_type, global_position + offset)
#endregion

func _get_flow_registry() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("FlowRegistry")
