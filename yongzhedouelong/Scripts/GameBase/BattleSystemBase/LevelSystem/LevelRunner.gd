class_name LevelRunner extends Node

@export var level_definition: LevelDefinition
@export var actor_parent: NodePath

var spawned_actors: Array[BattleActor] = []
var runtime_context: GameplayFlowContext = GameplayFlowContext.new()

func start_level() -> void:
	spawned_actors.clear()
	runtime_context = GameplayFlowContext.new()
	runtime_context.level = self
	runtime_context.event_data["order"] = []

	if level_definition == null:
		return

	_spawn_initial_actors()
	_apply_initial_buffs()
	_emit_level_event(GameplayEvent.EventType.LEVEL_START)

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
	for flow in level_definition.get_event_flows(event_type):
		if flow is GameplayFlowBase:
			flow.execute(context)

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
