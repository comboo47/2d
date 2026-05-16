class_name GameplayEvent extends RefCounted

enum EventType {
	LEVEL_START,
	LEVEL_END,
	ACTOR_SPAWNED,
	ACTOR_DIED,
	ACTOR_HIT,
	ACTOR_KILL,
	SKILL_USED,
	BUFF_APPLIED,
	BUFF_REMOVED,
	BUFF_TICK,
	BUFF_STACK_CHANGED,
	DAMAGE_REQUESTED,
	DAMAGE_APPLIED,
}

var event_type: EventType = EventType.LEVEL_START
var source: BattleActor = null
var target: BattleActor = null
var skill: SkillBase = null
var buff: AttributeBuff = null
var damage_request: DamageRequest = null
var event_data: Dictionary = {}

static func create(type: EventType, source_actor: BattleActor = null, target_actor: BattleActor = null) -> GameplayEvent:
	var event := GameplayEvent.new()
	event.event_type = type
	event.source = source_actor
	event.target = target_actor
	return event

func to_context() -> GameplayFlowContext:
	return GameplayFlowContext.create_from_event(self)
