class_name BuffManager extends Node

var buffList: Array[AttributeBuff] = []
var waitToRemove: Array[AttributeBuff] = []

func _ready() -> void:
	GameplayEventBus.subscribe(_on_gameplay_event)

func _exit_tree() -> void:
	GameplayEventBus.unsubscribe(_on_gameplay_event)

func apply_buff(buff: AttributeBuff, source: BattleActor, target: BattleActor) -> AttributeBuff:
	if buff == null or target == null:
		return null

	var existing := find_buff(buff.get_runtime_id())
	if existing:
		match existing.merging:
			AttributeBuff.DurationMerging.Restart:
				existing.restart_duration()
			AttributeBuff.DurationMerging.Addtion:
				existing.extend_duration(buff.get_runtime_duration())
			AttributeBuff.DurationMerging.NoEffect:
				pass
		existing.add_stack(buff.stack)
		return existing

	var runtime_buff := buff.deep_duplicate(source, target)
	buffList.append(runtime_buff)
	runtime_buff.emit_lifecycle_event(GameplayEvent.EventType.BUFF_APPLIED)
	return runtime_buff

func remove_buff(buff: AttributeBuff) -> void:
	if buff == null:
		return
	if buffList.has(buff):
		buff.emit_lifecycle_event(GameplayEvent.EventType.BUFF_REMOVED)
		buffList.erase(buff)

func find_buff(buff_id: String) -> AttributeBuff:
	for buff in buffList:
		if buff.get_runtime_id() == buff_id:
			return buff
	return null

func _physics_process(delta: float) -> void:
	for buff in buffList:
		for event in buff.run_process(delta):
			GameplayEventBus.emit_event(event)
			buff.handle_gameplay_event(event)
		if buff.is_pending_remove:
			waitToRemove.append(buff)

	for buff in waitToRemove:
		remove_buff(buff)
	waitToRemove.clear()

func _on_gameplay_event(event: GameplayEvent) -> void:
	for buff in buffList:
		if _should_buff_receive_event(buff, event):
			buff.handle_gameplay_event(event)

func _should_buff_receive_event(buff: AttributeBuff, event: GameplayEvent) -> bool:
	if buff == null or event == null:
		return false
	if event.buff == buff:
		return false
	return event.target == buff.BuffTarget or event.source == buff.BuffTarget or event.source == buff.BuffSource

func _OnBuffApply() -> void:
	pass

func _OnBuffRemove() -> void:
	pass
