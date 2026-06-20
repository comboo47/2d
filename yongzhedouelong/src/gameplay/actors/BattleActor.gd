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

## 死亡守卫（通用层，防止重复死亡）。受击/击杀/死亡事件统一由 DamageResolver 经
## GameplayEventBus 广播（ACTOR_HIT / ACTOR_DIED / ACTOR_KILL），不再用 Godot signal。
var is_dead: bool = false

## 实例初始化数据（第十一期，由生成方经 setup_init_data 注入，可空）。
var init_data: ActorInitData = null
## SpawnFlow / DeathFlow 解释器实例（第十三期：per-instance FlowInterpreter，actor 自喂帧）。
var _spawn_interp: FlowInterpreter = null
var _death_interp: FlowInterpreter = null
## DeathFlow 是否已 finish（死亡门控）。
var _death_flow_done: bool = false
#endregion

func _physics_process(delta: float) -> void:
	# 第十三期：actor 自喂帧给 spawn/death 解释器（取代 FlowRuntime._process 转发）。
	if _spawn_interp != null and not _spawn_interp.is_finished():
		_spawn_interp.advance(delta)
	if _death_interp != null and not _death_flow_done:
		if not _death_interp.is_finished():
			_death_interp.advance(delta)
		# 死亡门控：DeathFlow 跑完（含 SECONDS 延时 Duration）→ 通知 actor 可销毁。
		if _death_interp.is_finished():
			_on_death_flow_finished()

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

#region Flow 系统接口（旧 string-id 路径：经 FlowRegistry 取 FlowGraph，解释器一次性跑完）
## 触发生成 Flow
func trigger_spawn_flow() -> void:
	var registry = _get_flow_registry()
	if spawn_flow_id.is_empty() or registry == null:
		return
	var graph = registry.get_flow(spawn_flow_id)
	if graph:
		FlowInterpreter.run_oneshot(graph, GameplayFlowContext.create_simple(self), self)

## 触发死亡 Flow
func trigger_death_flow() -> void:
	var registry = _get_flow_registry()
	if death_flow_id.is_empty() or registry == null:
		return
	var graph = registry.get_flow(death_flow_id)
	if graph:
		var context = GameplayFlowContext.new()
		context.source = self
		context.target = self
		context.event_data["position"] = global_position
		FlowInterpreter.run_oneshot(graph, context, self)

## 触发受伤 Flow
func trigger_hit_flow(damage: float, source: BattleActor = null) -> void:
	var registry = _get_flow_registry()
	if hit_flow_id.is_empty() or registry == null:
		return
	var graph = registry.get_flow(hit_flow_id)
	if graph:
		var context = GameplayFlowContext.new()
		context.source = source
		context.target = self
		context.event_data["damage"] = damage
		context.event_data["position"] = global_position
		FlowInterpreter.run_oneshot(graph, context, self)

## 触发击杀 Flow
func trigger_kill_flow(target: BattleActor) -> void:
	var registry = _get_flow_registry()
	if kill_flow_id.is_empty() or registry == null:
		return
	var graph = registry.get_flow(kill_flow_id)
	if graph:
		var context = GameplayFlowContext.new()
		context.source = self
		context.target = target
		context.event_data["position"] = target.global_position
		FlowInterpreter.run_oneshot(graph, context, self)

## 通用死亡入口（由 DamageResolver 在判定 HP≤0 时调用）。
## 防重入：每个 actor 只会死一次。子类通过 override _on_death(killer) 实现死亡表现。
## 第十一期：若 init_data 有 death_flow，启动它（FlowRuntime 托管）；最终销毁由门控
## （表现完成 + death_flow finish）触发，见子类 _try_final_destroy。
func kill(killer: BattleActor = null) -> void:
	if is_dead:
		return
	is_dead = true
	trigger_death_flow()  # 旧 string-id 路径（默认空，零害）
	_start_death_flow()
	_on_death(killer)

## 死亡表现钩子（子类 override）。基类默认无表现。
func _on_death(_killer: BattleActor = null) -> void:
	pass

#region 第十一期：Actor 作为 SpawnFlow / DeathFlow 宿主（第十三期：FlowGraph + FlowInterpreter）
## 注入实例初始化数据（生成方在 add_child 之后调用）。启动 SpawnFlow（若有）。
func setup_init_data(data: ActorInitData) -> void:
	init_data = data
	if data != null and data.spawn_flow != null:
		var ctx := GameplayFlowContext.create_simple(self)
		_spawn_interp = _start_flow_graph(data.spawn_flow, ctx)

## 是否配了 DeathFlow（供子类死亡门控判断走延迟销毁还是立即销毁）。
func has_death_flow() -> bool:
	return init_data != null and init_data.death_flow != null

## 启动 DeathFlow（若有）。ctx 塞 on_finish 回调作兜底（finish action 触发）；
## 主门控走解释器 is_finished()（见 _physics_process）。
func _start_death_flow() -> void:
	if not has_death_flow():
		return
	var ctx := GameplayFlowContext.new()
	ctx.source = self
	ctx.target = self
	ctx.event_data["position"] = global_position
	ctx.event_data["on_finish"] = Callable(self, "_on_death_flow_finished")
	_death_interp = _start_flow_graph(init_data.death_flow, ctx)
	# 同步即结束的 DeathFlow（全 INSTANT，无延时 Duration）：立即门控完成。
	if _death_interp != null and _death_interp.is_finished():
		_on_death_flow_finished()

## DeathFlow finish 回调（兜底）/门控完成：标记完成 + cancel 实例 + 通知子类最终销毁。
func _on_death_flow_finished() -> void:
	if _death_flow_done:
		return
	_death_flow_done = true
	if _death_interp != null:
		_death_interp.cancel()
		_death_interp = null
	_finish_death()

## 死亡门控完成钩子（子类 override 决定最终销毁；基类默认 queue_free）。
func _finish_death() -> void:
	if is_inside_tree():
		queue_free()

## 启动一个 flow 节点树解释器（deep_duplicate，self 作 host）。返回解释器或 null。
func _start_flow_graph(graph: FlowGraph, ctx: GameplayFlowContext) -> FlowInterpreter:
	if graph == null:
		return null
	var interp := FlowInterpreter.new()
	interp.start(graph.deep_duplicate(), ctx, self)
	return interp

func _exit_tree() -> void:
	# cancel 残留解释器（确定性同步清理，无泄漏）。
	if _spawn_interp != null:
		_spawn_interp.cancel()
		_spawn_interp = null
	if _death_interp != null:
		_death_interp.cancel()
		_death_interp = null
#endregion

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
