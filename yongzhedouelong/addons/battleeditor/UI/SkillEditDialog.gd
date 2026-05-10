@tool
extends ConfirmationDialog
## 技能编辑对话框
## 用于编辑 SkillBase 资源的属性

## 当前编辑的技能资源
var _current_skill: SkillBase = null

## 技能资源路径
var _skill_path: String = ""

## 属性编辑控件
var _id_edit: LineEdit = null
var _name_edit: LineEdit = null
var _desc_edit: TextEdit = null
var _type_option: OptionButton = null
var _target_option: OptionButton = null
var _range_spin: SpinBox = null
var _cost_type_option: OptionButton = null
var _cost_value_spin: SpinBox = null
var _cooldown_spin: SpinBox = null
var _flow_edit: LineEdit = null
var _icon_edit: LineEdit = null

## 流程 ID 列表（供选择）
var _available_flows: Array[String] = []

func _ready() -> void:
	title = "编辑技能"
	min_size = Vector2i(500, 400)

	# 构建编辑界面
	_build_ui()

	# 连接确认按钮
	get_ok_button().text = "保存"
	confirmed.connect(_on_confirmed)

	# 加载可用的 Flow ID
	_load_available_flows()

## 构建编辑界面
func _build_ui() -> void:
	var vbox = VBoxContainer.new()
	add_child(vbox)

	# 技能 ID
	_id_edit = _add_line_edit(vbox, "技能 ID:")

	# 技能名称
	_name_edit = _add_line_edit(vbox, "技能名称:")

	# 技能描述
	var desc_label = Label.new()
	desc_label.text = "技能描述:"
	vbox.add_child(desc_label)

	_desc_edit = TextEdit.new()
	_desc_edit.custom_minimum_size = Vector2(0, 80)
	_desc_edit.wrap_mode = TextEdit.LINE_WRAP
	vbox.add_child(_desc_edit)

	# 技能类型
	_type_option = _add_option_button(vbox, "技能类型:",
		["ACTIVE", "PASSIVE", "TRIGGERED", "TOGGLE"])

	# 目标类型
	_target_option = _add_option_button(vbox, "目标类型:",
		["SELF", "ENEMY_SINGLE", "ENEMY_AREA", "ALLY_SINGLE",
		 "ALLY_AREA", "DIRECTION", "POSITION", "NONEAREST_ENEMY"])

	# 目标范围
	_range_spin = _add_spin_box(vbox, "目标范围:", 0, 1000, 100)

	# 消耗类型
	_cost_type_option = _add_option_button(vbox, "消耗类型:",
		["MANA", "ENERGY", "HP", "COOLDOWN_ONLY", "NONE"])

	# 消耗值
	_cost_value_spin = _add_spin_box(vbox, "消耗值:", 0, 1000, 20)

	# 冷却时间
	_cooldown_spin = _add_spin_box(vbox, "冷却时间 (秒):", 0, 300, 5)

	# 关联 Flow ID
	_flow_edit = _add_line_edit(vbox, "关联 Flow ID:")

	# 技能图标路径
	_icon_edit = _add_line_edit(vbox, "图标路径:")

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

## 加载可用的 Flow ID
func _load_available_flows() -> void:
	_available_flows.clear()

	if FlowRegistry.instance:
		for flow_id in FlowRegistry.instance._flow_registry.keys():
			_available_flows.append(flow_id)

## 设置编辑的技能
func set_skill(skill: SkillBase, path: String) -> void:
	_current_skill = skill
	_skill_path = path

	if skill == null:
		return

	# 填充控件值
	_id_edit.text = skill.skill_id
	_name_edit.text = skill.skill_name
	_desc_edit.text = skill.skill_description

	_type_option.selected = skill.skill_type
	_target_option.selected = skill.target_type
	_range_spin.value = skill.target_range
	_cost_type_option.selected = skill.cost_type
	_cost_value_spin.value = skill.cost_value
	_cooldown_spin.value = skill.cooldown_time
	_flow_edit.text = skill.on_use_flow_id
	_icon_edit.text = skill.icon_path

## 确认保存
func _on_confirmed() -> void:
	if _current_skill == null or _skill_path.is_empty():
		return

	# 更新技能属性
	_current_skill.skill_id = _id_edit.text
	_current_skill.skill_name = _name_edit.text
	_current_skill.skill_description = _desc_edit.text
	_current_skill.skill_type = _type_option.selected
	_current_skill.target_type = _target_option.selected
	_current_skill.target_range = _range_spin.value
	_current_skill.cost_type = _cost_type_option.selected
	_current_skill.cost_value = _cost_value_spin.value
	_current_skill.cooldown_time = _cooldown_spin.value
	_current_skill.on_use_flow_id = _flow_edit.text
	_current_skill.icon_path = _icon_edit.text

	# 保存资源
	var error = ResourceSaver.save(_current_skill, _skill_path)
	if error != OK:
		push_error("SkillEditDialog: 保存技能失败 %s (错误: %d)" % [_skill_path, error])
	else:
		print("SkillEditDialog: 技能已保存 %s" % _skill_path)