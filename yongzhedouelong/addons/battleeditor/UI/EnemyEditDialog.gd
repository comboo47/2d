@tool
extends ConfirmationDialog
## 怪物编辑对话框
## 用于编辑 EnemyConfig.json 中的怪物配置

## 当前编辑的怪物 ID
var _current_enemy_id: String = ""

## 当前编辑的怪物数据
var _current_enemy_data: Dictionary = {}

## 属性编辑控件
var _id_label: Label = null
var _name_edit: LineEdit = null
var _prefab_edit: LineEdit = null
var _spawn_flow_edit: LineEdit = null
var _death_flow_edit: LineEdit = null

## 属性配置区域
var _attributes_container: VBoxContainer = null

## 怪物配置数据（引用）
var _enemy_config_data: Dictionary = {}

## 配置文件路径
const CONFIG_PATH = "res://Tables/Json/Enemy/EnemyConfig.json"

func _ready() -> void:
	title = "编辑怪物配置"
	min_size = Vector2i(500, 500)

	_build_ui()

	get_ok_button().text = "保存"
	confirmed.connect(_on_confirmed)

## 构建编辑界面
func _build_ui() -> void:
	var vbox = VBoxContainer.new()
	add_child(vbox)

	# 怪物 ID（显示，不可编辑）
	var id_hbox = HBoxContainer.new()
	vbox.add_child(id_hbox)

	var id_label_text = Label.new()
	id_label_text.text = "怪物 ID:"
	id_label_text.custom_minimum_size = Vector2(120, 0)
	id_hbox.add_child(id_label_text)

	_id_label = Label.new()
	_id_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	id_hbox.add_child(_id_label)

	# 显示名称
	_name_edit = _add_line_edit(vbox, "显示名称:")

	# 预制体路径
	_prefab_edit = _add_line_edit(vbox, "预制体路径:")

	# 生成 Flow ID
	_spawn_flow_edit = _add_line_edit(vbox, "生成 Flow ID:")

	# 死亡 Flow ID
	_death_flow_edit = _add_line_edit(vbox, "死亡 Flow ID:")

	# 属性配置区域
	var attr_label = Label.new()
	attr_label.text = "属性配置:"
	vbox.add_child(attr_label)

	_attributes_container = VBoxContainer.new()
	vbox.add_child(_attributes_container)

	# 添加属性按钮
	var add_attr_btn = Button.new()
	add_attr_btn.text = "添加属性"
	add_attr_btn.pressed.connect(_on_add_attribute)
	vbox.add_child(add_attr_btn)

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

## 设置编辑的怪物
func set_enemy(enemy_id: String, enemy_data: Dictionary) -> void:
	_current_enemy_id = enemy_id
	_current_enemy_data = enemy_data.duplicate()

	_id_label.text = enemy_id
	_name_edit.text = enemy_data.get("display_name", "")
	_prefab_edit.text = enemy_data.get("prefab_path", "")
	_spawn_flow_edit.text = enemy_data.get("spawn_flow_id", "")
	_death_flow_edit.text = enemy_data.get("death_flow_id", "")

	# 清空并重建属性区域
	for child in _attributes_container.get_children():
		child.queue_free()

	var attributes = enemy_data.get("attributes", {})
	for attr_key in attributes.keys():
		_add_attribute_row(attr_key, str(attributes[attr_key]))

## 添加属性行
func _add_attribute_row(key: String = "", value: String = "0") -> void:
	var hbox = HBoxContainer.new()
	_attributes_container.add_child(hbox)

	var key_edit = LineEdit.new()
	key_edit.placeholder_text = "属性名"
	key_edit.text = key
	key_edit.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(key_edit)

	var value_spin = SpinBox.new()
	value_spin.min_value = 0
	value_spin.max_value = 10000
	value_spin.step = 1
	value_spin.value = float(value)
	hbox.add_child(value_spin)

	var delete_btn = Button.new()
	delete_btn.text = "删除"
	delete_btn.pressed.connect(func():
		hbox.queue_free()
	)
	hbox.add_child(delete_btn)

## 添加新属性按钮处理
func _on_add_attribute() -> void:
	_add_attribute_row()

## 确认保存
func _on_confirmed() -> void:
	if _current_enemy_id.is_empty():
		return

	# 更新怪物数据
	_current_enemy_data["display_name"] = _name_edit.text
	_current_enemy_data["prefab_path"] = _prefab_edit.text
	_current_enemy_data["spawn_flow_id"] = _spawn_flow_edit.text
	_current_enemy_data["death_flow_id"] = _death_flow_edit.text

	# 收集属性配置
	var new_attributes = {}
	for child in _attributes_container.get_children():
		if child is HBoxContainer:
			var children = child.get_children()
			if children.size() >= 2:
				var key_edit = children[0] as LineEdit
				var value_spin = children[1] as SpinBox

				if key_edit and value_spin and not key_edit.text.is_empty():
					new_attributes[key_edit.text] = int(value_spin.value)

	_current_enemy_data["attributes"] = new_attributes

	# 保存到配置文件
	_save_enemy_config()

## 保存怪物配置文件
func _save_enemy_config() -> void:
	# 加载当前配置
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("无法读取怪物配置文件")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("怪物配置 JSON 解析失败")
		return

	var config_data = json.data
	config_data[_current_enemy_id] = _current_enemy_data

	# 保存
	var new_json_text = JSON.stringify(config_data, "\t")
	file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法写入怪物配置文件")
		return

	file.store_string(new_json_text)
	file.close()

	print("EnemyEditDialog: 怪物配置已保存 %s" % _current_enemy_id)