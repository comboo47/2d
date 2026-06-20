extends Node2D

var player: BattleActor

func _ready() -> void:
	player = _find_player()
	if player:
		player.position = $PlayerStart.position
		UIManager.instance.show_hud(player)

	# 关卡内容数据化加载：取暂存 level_id → LevelDefinition → 交 LevelRunner 动态生成。
	GameplayEventBus.clear_history()
	_load_level()

	# 监听关卡结束 → 结算 + 存档解锁。
	GameplayEventBus.subscribe(_on_level_end)

	GameManager.enter_game()

func _exit_tree() -> void:
	GameplayEventBus.unsubscribe(_on_level_end)

## 关卡结束：胜利则存档+解锁下一关，弹结算面板（胜/负）。
func _on_level_end(event: GameplayEvent) -> void:
	if event == null or event.event_type != GameplayEvent.EventType.LEVEL_END:
		return
	var victory: bool = bool(event.event_data.get("victory", false))
	var level_id: String = str(event.event_data.get("level_id", ""))
	var next_level_id: String = str(event.event_data.get("next_level_id", ""))

	if victory:
		var save = get_tree().root.get_node_or_null("SaveManager")
		if save:
			save.mark_level_completed(level_id)
			if not next_level_id.is_empty():
				save.unlock_level(next_level_id)

	# 冻结战斗但不进 PAUSED 态（避免弹出暂停菜单）；结算面板 process_mode=ALWAYS 仍可交互。
	get_tree().paused = true
	if UIManager.instance:
		UIManager.instance.push_screen(UIConfig.MENU_LEVEL_RESULT, {"victory": victory, "level_id": level_id})

## 按 GameManager.pending_level_id 加载关卡，赋给场景里的 LevelRunner 并启动。
## pending 为空时 fallback 到 level_01（直接运行战斗场景调试用）。
func _load_level() -> void:
	var runner := get_node_or_null("LevelRunner") as LevelRunner
	if runner == null:
		return
	var level_id: String = GameManager.pending_level_id
	if level_id.is_empty():
		level_id = "level_01"
	var level_reg = get_tree().root.get_node_or_null("LevelRegistry")
	if level_reg == null:
		return
	var def = level_reg.get_definition(level_id)
	if def == null:
		return
	runner.level_definition = def
	if player:
		runner.set_player(player)
	runner.start_level()

func _find_player() -> BattleActor:
	for child in get_children():
		if child is BattleActor and child.has_method("GetAttributes"):
			return child

	var found := get_node_or_null("Player")
	if found and found is BattleActor:
		return found
	return null

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("testButton"):
		var num := randf() * 100
		if player:
			UIManager.instance.show_damage(player, num)
