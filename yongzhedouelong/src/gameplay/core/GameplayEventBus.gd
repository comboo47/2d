class_name GameplayEventBus extends Node

signal event_emitted(event: GameplayEvent)

static var _listeners: Array[Callable] = []
static var emitted_events: Array[GameplayEvent] = []

static func subscribe(listener: Callable) -> void:
	if not _listeners.has(listener):
		_listeners.append(listener)

static func unsubscribe(listener: Callable) -> void:
	_listeners.erase(listener)

static func emit_event(event: GameplayEvent) -> void:
	if event == null:
		return
	emitted_events.append(event)
	for listener in _listeners.duplicate():
		listener.call(event)

static func clear_history() -> void:
	emitted_events.clear()

static func emit_simple(type: GameplayEvent.EventType, source: BattleActor = null, target: BattleActor = null, event_data: Dictionary = {}) -> GameplayEvent:
	var event := GameplayEvent.create(type, source, target)
	event.event_data = event_data
	emit_event(event)
	return event

func emit_instance_event(event: GameplayEvent) -> void:
	GameplayEventBus.emit_event(event)
	event_emitted.emit(event)
