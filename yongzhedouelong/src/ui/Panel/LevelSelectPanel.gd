class_name LevelSelectPanel extends UIPanel

const LEVELS: Array[Dictionary] = [
	{"name": "Level 1", "scene": "res://scenes/app/TestScene.tscn"},
]

var level_list: VBoxContainer
var back_button: Button

func _ready() -> void:
	super._ready()
	panel_type = PanelType.MENU
	close_on_escape = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	level_list = get_node_or_null("Panel/VBoxContainer/LevelList")
	back_button = get_node_or_null("Panel/VBoxContainer/BackButton")

	_build_level_buttons()
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _build_level_buttons() -> void:
	if not level_list:
		return

	for level in LEVELS:
		var level_name: String = str(level["name"])
		var scene_path: String = str(level["scene"])
		var button := Button.new()
		button.text = level_name
		button.custom_minimum_size = Vector2(180, 28)
		button.pressed.connect(_on_level_pressed.bind(scene_path))
		level_list.add_child(button)

func _on_level_pressed(scene_path: String) -> void:
	get_viewport().set_input_as_handled()
	perform_action("start_game", {"scene_path": scene_path})

func _on_back_pressed() -> void:
	get_viewport().set_input_as_handled()
	perform_action("back")
