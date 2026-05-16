class_name UIPanel extends Control

enum PanelType {
	HUD,
	MENU,
	DIALOG,
	POPUP,
}

signal request_close
signal panel_closed
signal panel_action(action_name: String, payload: Dictionary)

@export var panel_type: PanelType = PanelType.MENU
@export var close_on_escape: bool = true
@export var pause_game: bool = false

var _is_open: bool = false
var _open_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tree := get_tree()
	if tree and tree.current_scene != self:
		hide()

func _input(event: InputEvent) -> void:
	if _is_open and close_on_escape and event.is_action_pressed("ui_cancel"):
		request_close.emit()
		get_viewport().set_input_as_handled()

func open(data: Dictionary = {}) -> void:
	_open_data = data.duplicate(true)
	_is_open = true
	show()
	on_focus()

func close() -> void:
	if not _is_open:
		return

	on_blur()
	_is_open = false
	hide()
	panel_closed.emit()

func on_focus() -> void:
	pass

func on_blur() -> void:
	pass

func perform_action(action: String, payload: Dictionary = {}) -> void:
	panel_action.emit(action, payload)

func is_open() -> bool:
	return _is_open

func get_open_data() -> Dictionary:
	return _open_data.duplicate(true)
