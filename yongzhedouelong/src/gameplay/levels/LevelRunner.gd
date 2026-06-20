class_name LevelRunner extends Node

@export var level_definition: LevelDefinition
@export var actor_parent: NodePath

var spawned_actors: Array[BattleActor] = []
var runtime_context: GameplayFlowContext = GameplayFlowContext.new()

## 玩家引用（由战斗场景注入，供失败判定用）。
var _player: BattleActor = null
## 存活敌人列表（仅 is_enemy 的 spawned actor）；清空=胜利。
var _alive_enemies: Array[BattleActor] = []
## 结束守卫：胜负只结算一次。
var _level_ended: bool = false

func set_player(p: BattleActor) -> void:
	_player = p

func start_level() -> void:
	spawned_actors.clear()
	_alive_enemies.clear()
	_level_ended = false
	runtime_context = GameplayFlowContext.new()
	runtime_context.level = self
	runtime_context.event_data["order"] = []

	if level_definition == null:
		return

	_spawn_initial_actors()
	_apply_initial_buffs()
	_emit_level_event(GameplayEvent.EventType.LEVEL_START)

	# 订阅总线监听死亡 → 关卡结束判定。无敌人则不自动判胜（避免空关卡秒胜）。
	GameplayEventBus.subscribe(_on_bus_event)

func _exit_tree() -> void:
	GameplayEventBus.unsubscribe(_on_bus_event)

## 总线监听：敌人全灭=胜利；玩家死亡=失败（阶段⑤接入 _player 后生效）。
func _on_bus_event(event: GameplayEvent) -> void:
	if _level_ended or event == null:
		return
	if event.event_type == GameplayEvent.EventType.ACTOR_DIED:
		var dead := event.target
		if dead != null and _alive_enemies.has(dead):
			_alive_enemies.erase(dead)
			if _alive_enemies.is_empty():
				_finish_level(true)
		elif _player != null and dead == _player:
			_finish_level(false)

## 结束关卡：广播 LEVEL_END(victory) 并退订。
func _finish_level(victory: bool) -> void:
	if _level_ended:
		return
	_level_ended = true
	GameplayEventBus.unsubscribe(_on_bus_event)
	GameplayEventBus.emit_simple(GameplayEvent.EventType.LEVEL_END, null, null, {
		"victory": victory,
		"level_id": level_definition.level_id if level_definition else "",
		"next_level_id": level_definition.next_level_id if level_definition else "",
	})

func is_level_ended() -> bool:
	return _level_ended

func get_alive_enemy_count() -> int:
	return _alive_enemies.size()

func _spawn_initial_actors() -> void:
	for actor_definition in level_definition.initial_actors:
		if actor_definition == null or actor_definition.actor_scene == null:
			continue
		var actor := actor_definition.actor_scene.instantiate() as BattleActor
		if actor == null:
			continue
		_get_actor_parent().add_child(actor)
		actor.global_position = actor_definition.position
		spawned_actors.append(actor)
		if actor_definition.is_enemy:
			_alive_enemies.append(actor)

		# 第十一期：注入实例初始化数据（启动 SpawnFlow 等）。在 add_child 之后，actor 已 in_tree。
		if actor_definition.init_data != null:
			actor.setup_init_data(actor_definition.init_data)

		if actor_definition.initial_skills.size() > 0:
			var manager := actor.add_skill_manager()
			for skill in actor_definition.initial_skills:
				if skill:
					manager.add_skill(skill)

		for buff in actor_definition.initial_buffs:
			if buff and actor.buffManager:
				actor.buffManager.apply_buff(buff, actor, actor)

		var event := GameplayEvent.create(GameplayEvent.EventType.ACTOR_SPAWNED, actor, actor)
		event.event_data["position"] = actor.global_position
		GameplayEventBus.emit_event(event)

func _apply_initial_buffs() -> void:
	for buff_definition in level_definition.initial_buffs:
		if buff_definition == null or buff_definition.buff == null:
			continue
		var source := _actor_at(buff_definition.source_actor_index)
		var target := _actor_at(buff_definition.target_actor_index)
		if target and target.buffManager:
			target.buffManager.apply_buff(buff_definition.buff, source, target)

func _emit_level_event(event_type: GameplayEvent.EventType) -> void:
	var event := GameplayEvent.create(event_type)
	event.event_data = runtime_context.event_data
	GameplayEventBus.emit_event(event)

	var context := GameplayFlowContext.create_from_event(event)
	context.level = self
	context.event_data = runtime_context.event_data
	# 第十三期：level event_flows 元素改为 FlowGraph，经解释器一次性跑完。
	for flow in level_definition.get_event_flows(event_type):
		if flow is FlowGraph:
			FlowInterpreter.run_oneshot(flow, context, self)

func _actor_at(index: int) -> BattleActor:
	if index < 0 or index >= spawned_actors.size():
		return null
	return spawned_actors[index]

func _get_actor_parent() -> Node:
	if not actor_parent.is_empty():
		var parent := get_node_or_null(actor_parent)
		if parent:
			return parent
	return self
