class_name PauseMenuPanel extends UIPanel

var resume_button: Button
var settings_button: Button
var main_menu_button: Button
var quit_button: Button

var _closed_by_button: bool = false

func _ready() -> void:
	super._ready()
	panel_type = PanelType.MENU
	close_on_escape = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	resume_button = get_node_or_null("VBoxContainer/ResumeButton")
	settings_button = get_node_or_null("VBoxContainer/SettingsButton")
	main_menu_button = get_node_or_null("VBoxContainer/MainMenuButton")
	quit_button = get_node_or_null("VBoxContainer/QuitButton")

	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_resume_pressed() -> void:
	get_viewport().set_input_as_handled()
	_closed_by_button = true
	var lock_duration: float = 0.3
	perform_action("resume_game", {"lock_duration": lock_duration})
	_closed_by_button = false

func _on_settings_pressed() -> void:
	get_viewport().set_input_as_handled()
	perform_action("open_settings")

func _on_main_menu_pressed() -> void:
	get_viewport().set_input_as_handled()
	perform_action("return_to_main_menu")

func _on_quit_pressed() -> void:
	get_viewport().set_input_as_handled()
	perform_action("quit_game")
