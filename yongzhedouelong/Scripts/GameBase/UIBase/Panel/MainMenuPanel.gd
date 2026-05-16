class_name MainMenuPanel extends UIPanel

var start_button: Button
var settings_button: Button
var quit_button: Button

func _ready() -> void:
	super._ready()
	panel_type = PanelType.MENU
	close_on_escape = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GameManager.current_state != GameManager.GameState.MAIN_MENU:
		GameManager.change_state(GameManager.GameState.MAIN_MENU)

	start_button = get_node_or_null("VBoxContainer/StartButton")
	settings_button = get_node_or_null("VBoxContainer/SettingsButton")
	quit_button = get_node_or_null("VBoxContainer/QuitButton")

	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_viewport().set_input_as_handled()
	_dispatch_action("open_level_select")

func _on_settings_pressed() -> void:
	get_viewport().set_input_as_handled()
	_dispatch_action("open_settings")

func _on_quit_pressed() -> void:
	get_viewport().set_input_as_handled()
	_dispatch_action("quit_game")

func _dispatch_action(action_name: String, payload: Dictionary = {}) -> void:
	if get_tree().current_scene == self and UIManager.instance:
		UIManager.instance.handle_panel_action(action_name, payload, UIConfig.MENU_MAIN)
	else:
		perform_action(action_name, payload)
