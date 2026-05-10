@tool
extends ConfirmationDialog
## Buff 编辑对话框
## 用于编辑 AttributeBuff 资源的属性

## 当前编辑的 Buff 资源
var _current_buff: AttributeBuff = null

## Buff 资源路径
var _buff_path: String = ""

## 属性编辑控件
var _id_edit: LineEdit = null
var _name_edit: LineEdit = null
var _duration_spin: SpinBox = null
var _period_spin: SpinBox = null
var _leave_reset_check: CheckBox = null
var _merging_option: OptionButton = null

func _ready() -> void:
	title = "编辑 Buff"
	min_size = Vector2i(400, 300)

	_build_ui()

	get_ok_button().text = "保存"
	confirmed.connect(_on_confirmed)

## 构建编辑界面
func _build_ui() -> void:
	var vbox = VBoxContainer.new()
	add_child(vbox)

	# Buff ID
	_id_edit = _add_line_edit(vbox, "Buff ID:")

	# Buff 名称
	_name_edit = _add_line_edit(vbox, "Buff 名称:")

	# 持续时间
	_duration_spin = _add_spin_box(vbox, "持续时间 (秒):", 0, 3600, 0)

	# 周期
	_period_spin = _add_spin_box(vbox, "执行周期 (秒):", 0, 3600, 0)

	# 是否离开重置
	_leave_reset_check = _add_check_box(vbox, "离开时重置:")

	# Duration 合并策略
	_merging_option = _add_option_button(vbox, "合并策略:",
		["Restart", "Addtion", "NoEffect"])

## 添加行编辑框
func _add_line_edit(container: Container, label_text: String) -> LineEdit:
	var hbox = HBoxContainer.new()
	container.add_child(hbox)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(label)

	var edit = LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(edit)

	return edit

## 添加数值编辑框
func _add_spin_box(container: Container, label_text: String, min_val: float, max_val: float, default: float) -> SpinBox:
	var hbox = HBoxContainer.new()
	container.add_child(hbox)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(label)

	var spin = SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.value = default
	spin.step = 1.0
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spin)

	return spin

## 添加复选框
func _add_check_box(container: Container, label_text: String) -> CheckBox:
	var hbox = HBoxContainer.new()
	container.add_child(hbox)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(label)

	var check = CheckBox.new()
	hbox.add_child(check)

	return check

## 添加下拉选择框
func _add_option_button(container: Container, label_text: String, options: Array) -> OptionButton:
	var hbox = HBoxContainer.new()
	container.add_child(hbox)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(label)

	var option = OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for opt in options:
		option.add_item(opt)
	hbox.add_child(option)

	return option

## 设置编辑的 Buff
func set_buff(buff: AttributeBuff, path: String) -> void:
	_current_buff = buff
	_buff_path = path

	if buff == null:
		return

	_id_edit.text = buff.buff_id
	_name_edit.text = buff.buff_name
	_duration_spin.value = buff.duration
	_period_spin.value = buff.buffPeriod
	_leave_reset_check.button_pressed = buff.isLeaveReset
	_merging_option.selected = buff.merging

## 确认保存
func _on_confirmed() -> void:
	if _current_buff == null or _buff_path.is_empty():
		return

	_current_buff.buff_id = _id_edit.text
	_current_buff.buff_name = _name_edit.text
	_current_buff.duration = _duration_spin.value
	_current_buff.buffPeriod = int(_period_spin.value)
	_current_buff.isLeaveReset = _leave_reset_check.button_pressed
	_current_buff.merging = _merging_option.selected

	var error = ResourceSaver.save(_current_buff, _buff_path)
	if error != OK:
		push_error("BuffEditDialog: 保存 Buff 失败 %s (错误: %d)" % [_buff_path, error])
	else:
		print("BuffEditDialog: Buff 已保存 %s" % _buff_path)