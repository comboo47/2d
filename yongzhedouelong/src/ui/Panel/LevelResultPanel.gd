class_name LevelResultPanel extends UIPanel
## 关卡结算面板（胜利/失败）。由 Main 在收到 LEVEL_END 时 push_screen 弹出。
## data: {victory:bool, level_id:String}。胜利显示「通关」+返回；失败显示「失败」+重试/返回。

var _title: Label
var _return_button: Button
var _retry_button: Button
var _level_id: String = ""

func _ready() -> void:
	super._ready()
	panel_type = PanelType.MENU
	close_on_escape = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	_title = get_node_or_null("Panel/VBoxContainer/Title")
	_return_button = get_node_or_null("Panel/VBoxContainer/ReturnButton")
	_retry_button = get_node_or_null("Panel/VBoxContainer/RetryButton")
	if _return_button:
		_return_button.pressed.connect(_on_return_pressed)
	if _retry_button:
		_retry_button.pressed.connect(_on_retry_pressed)

func open(data: Dictionary = {}) -> void:
	super.open(data)
	var victory: bool = bool(data.get("victory", true))
	_level_id = str(data.get("level_id", ""))
	if _title:
		_title.text = "通关！" if victory else "失败"
	# 重试按钮仅失败时显示
	if _retry_button:
		_retry_button.visible = not victory

func _on_return_pressed() -> void:
	get_viewport().set_input_as_handled()
	perform_action("to_level_select")

func _on_retry_pressed() -> void:
	get_viewport().set_input_as_handled()
	perform_action("retry_level", {"level_id": _level_id})
