class_name LevelSelectPanel extends UIPanel

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

## 每次展示时重建按钮，反映最新解锁状态（通关返回后能看到新解锁的关卡）。
func on_focus() -> void:
	super.on_focus()
	_build_level_buttons()

func _input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _build_level_buttons() -> void:
	if not level_list:
		return
	# 清空旧按钮（重建）
	for child in level_list.get_children():
		child.queue_free()

	var reg = get_tree().root.get_node_or_null("LevelRegistry")
	if reg == null:
		return
	var defs: Array = reg.get_all_definitions()
	if defs.is_empty():
		return

	# 读解锁状态；首关默认解锁（兜底，避免空存档时无关可选）。
	var unlocked: Array = []
	var save = get_tree().root.get_node_or_null("SaveManager")
	if save:
		unlocked = save.get_progress().get("unlocked_levels", [])
	var first_id: String = defs[0].level_id

	for def in defs:
		var level_id: String = def.level_id
		var label: String = def.level_name if not def.level_name.is_empty() else level_id
		var is_unlocked: bool = unlocked.has(level_id) or level_id == first_id
		var button := Button.new()
		button.text = label if is_unlocked else "%s 🔒" % label
		button.custom_minimum_size = Vector2(180, 28)
		button.disabled = not is_unlocked
		if is_unlocked:
			button.pressed.connect(_on_level_pressed.bind(level_id))
		level_list.add_child(button)

func _on_level_pressed(level_id: String) -> void:
	get_viewport().set_input_as_handled()
	perform_action("start_level", {"level_id": level_id})

func _on_back_pressed() -> void:
	get_viewport().set_input_as_handled()
	perform_action("back")
