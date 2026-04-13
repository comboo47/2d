class_name PauseMenuPanel extends UIPanel

## 按钮引用
var resume_button: Button
var settings_button: Button
var main_menu_button: Button
var quit_button: Button

## 是否通过按钮关闭（需要锁定输入）
var _closed_by_button: bool = false

func _ready() -> void:
	super._ready()
	panel_type = PanelType.MENU
	pause_game = true
	close_on_escape = true

	# 暂停菜单需要始终处理输入
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 获取按钮引用
	resume_button = get_node_or_null("VBoxContainer/ResumeButton")
	settings_button = get_node_or_null("VBoxContainer/SettingsButton")
	main_menu_button = get_node_or_null("VBoxContainer/MainMenuButton")
	quit_button = get_node_or_null("VBoxContainer/QuitButton")

	# 连接按钮信号
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func close() -> void:
	if not _is_open:
		return

	# 暂停菜单关闭时，通知 GameManager 恢复游戏
	if GameManager.is_paused():
		# 无论 ESC 还是按钮关闭，都需要锁定输入防止 fire release 触发
		# ESC 关闭锁定时间短（无鼠标点击穿透风险）
		# 按钮关闭锁定时间长（有鼠标点击穿透风险）
		var lock_duration = 0.15 if not _closed_by_button else 0.3
		InputManager.lock_inputs(lock_duration)
		GameManager.change_state(GameManager.GameState.PLAYING)
		GameManager.game_resumed.emit()

	_closed_by_button = false
	super.close()

func _on_resume_pressed() -> void:
	# 消费按钮点击事件，防止穿透
	get_viewport().set_input_as_handled()
	# 标记为按钮关闭
	_closed_by_button = true
	# 直接关闭面板（close() 会处理状态切换）
	close()

func _on_settings_pressed() -> void:
	get_viewport().set_input_as_handled()
	UIManager.instance.open_menu(UIConfig.MENU_SETTINGS)

func _on_main_menu_pressed() -> void:
	get_viewport().set_input_as_handled()
	GameManager.return_to_main_menu()

func _on_quit_pressed() -> void:
	get_viewport().set_input_as_handled()
	GameManager.quit_game()