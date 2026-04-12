class_name MainMenuPanel extends UIPanel

## 按钮引用
var start_button: Button
var settings_button: Button
var quit_button: Button

func _ready() -> void:
	super._ready()
	panel_type = PanelType.MENU
	# 主菜单需要暂停游戏，防止 Player autoload 的输入处理
	pause_game = true
	close_on_escape = false  # 主菜单不能通过 ESC 关闭

	# 立即暂停游戏
	get_tree().paused = true

	# 获取按钮引用
	start_button = get_node_or_null("VBoxContainer/StartButton")
	settings_button = get_node_or_null("VBoxContainer/SettingsButton")
	quit_button = get_node_or_null("VBoxContainer/QuitButton")

	# 连接按钮信号
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	# 恢复游戏暂停状态
	get_tree().paused = false
	# 加载游戏场景
	get_tree().change_scene_to_file("res://Scene/TestScene.tscn")

func _on_settings_pressed() -> void:
	UIManager.instance.open_menu(UIConfig.MENU_SETTINGS)

func _on_quit_pressed() -> void:
	get_tree().quit()