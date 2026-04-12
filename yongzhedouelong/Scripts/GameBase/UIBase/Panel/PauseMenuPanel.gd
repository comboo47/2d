class_name PauseMenuPanel extends UIPanel

## 按钮引用
var resume_button: Button
var settings_button: Button
var main_menu_button: Button
var quit_button: Button

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

func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_settings_pressed() -> void:
	UIManager.instance.open_menu(UIConfig.MENU_SETTINGS)

func _on_main_menu_pressed() -> void:
	GameManager.return_to_main_menu()

func _on_quit_pressed() -> void:
	GameManager.quit_game()