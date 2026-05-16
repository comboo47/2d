class_name LevelDefinition extends Resource

@export var level_id: String = ""
@export var level_name: String = ""
@export var initial_actors: Array[LevelActorDefinition] = []
@export var initial_buffs: Array[LevelBuffDefinition] = []
@export var event_flows: Dictionary = {}

func get_event_flows(event_type: GameplayEvent.EventType) -> Array:
	return event_flows.get(event_type, [])
