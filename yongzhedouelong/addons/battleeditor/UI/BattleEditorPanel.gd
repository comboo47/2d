@tool
extends Control
## 战斗编辑器主面板
## 左侧：JSON 数值配置编辑
## 右侧：自动 Inspector（Resource 属性）

## EditorInterface 引用
var _editor_interface: EditorInterface = null

## 树控件
@onready var _tree: Tree = $VBoxContainer/HSplitContainer/TreePanel/VBoxContainer/Tree

## JSON 编辑区域
@onready var _json_edit_container: VBoxContainer = $VBoxContainer/HSplitContainer/EditSplitContainer/JsonEditPanel/VBoxContainer/ScrollContainer/JsonEditContainer

## Inspector 区域
@onready var _inspector_container: VBoxContainer = $VBoxContainer/HSplitContainer/EditSplitContainer/InspectorPanel/VBoxContainer/ScrollContainer/InspectorContainer

## 按钮
@onready var _new_btn: Button = $VBoxContainer/HSplitContainer/TreePanel/VBoxContainer/ButtonBox/NewBtn
@onready var _edit_btn: Button = $VBoxContainer/HSplitContainer/TreePanel/VBoxContainer/ButtonBox/EditBtn
@onready var _delete_btn: Button = $VBoxContainer/HSplitContainer/TreePanel/VBoxContainer/ButtonBox/DeleteBtn
@onready var _refresh_btn: Button = $VBoxContainer/HSplitContainer/TreePanel/VBoxContainer/ButtonBox/RefreshBtn
@onready var _save_btn: Button = $VBoxContainer/HSplitContainer/EditSplitContainer/InspectorPanel/VBoxContainer/ButtonBox/SaveBtn
@onready var _locate_btn: Button = $VBoxContainer/HSplitContainer/EditSplitContainer/InspectorPanel/VBoxContainer/ButtonBox/LocateBtn

## 当前选中类型
var _current_type: String = ""

## 当前选中的 Enemy ID
var _selected_enemy_id: String = ""

## 当前选中的 Skill/Buff ID
var _selected_skill_id: String = ""
var _selected_buff_id: String = ""

## 资源缓存
var _skill_resource_cache: Dictionary = {}  # skill_id -> {path, resource}
var _buff_resource_cache: Dictionary = {}   # buff_id -> {path, resource}
var _enemy_config_data: Dictionary = {}     # enemy_id -> config

## JSON 配置缓存
var _skill_json_config: Dictionary = {}     # skill_id -> json_data
var _buff_json_config: Dictionary = {}      # buff_id -> json_data

## 树节点元数据键名
const META_TYPE = "type"
const META_ENEMY_ID = "enemy_id"
const META_ID = "id"

## 设置 EditorInterface
func set_editor_interface(interface: EditorInterface) -> void:
	_editor_interface = interface

func _ready() -> void:
	_setup_tree()
	_setup_buttons()
	_refresh_all()

## 设置树控件
func _setup_tree() -> void:
	if _tree == null:
		return

	_tree.set_column_title(0, "名称")
	_tree.set_column_title(1, "ID")
	_tree.set_column_expand(0, true)
	_tree.set_column_expand(1, false)
	_tree.set_column_custom_minimum_width(1, 80)
	_tree.hide_root = true

	if not _tree.item_selected.is_connected(_on_tree_item_selected):
		_tree.item_selected.connect(_on_tree_item_selected)

## 设置按钮
func _setup_buttons() -> void:
	if _new_btn and not _new_btn.pressed.is_connected(_on_new_pressed):
		_new_btn.pressed.connect(_on_new_pressed)
	if _delete_btn and not _delete_btn.pressed.is_connected(_on_delete_pressed):
		_delete_btn.pressed.connect(_on_delete_pressed)
	if _refresh_btn and not _refresh_btn.pressed.is_connected(_on_refresh_pressed):
		_refresh_btn.pressed.connect(_on_refresh_pressed)
	if _save_btn and not _save_btn.pressed.is_connected(_on_save_pressed):
		_save_btn.pressed.connect(_on_save_pressed)
	if _locate_btn and not _locate_btn.pressed.is_connected(_on_locate_pressed):
		_locate_btn.pressed.connect(_on_locate_pressed)

## 刷新所有资源
func _refresh_all() -> void:
	if not is_inside_tree():
		return

	_refresh_skills()
	_refresh_buffs()
	_refresh_enemies()
	_rebuild_tree()

## 刷新 Skill 资源和 JSON 配置
func _refresh_skills() -> void:
	_skill_resource_cache.clear()
	_skill_json_config.clear()

	# 加载 Skill 资源文件
	var skills_dir = "res://prefab/Skills/"
	var dir = DirAccess.open(skills_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = skills_dir + file_name
				var resource = load(full_path)
				if resource and resource is SkillBase:
					_skill_resource_cache[resource.skill_id] = {
						"path": full_path,
						"resource": resource
					}
			file_name = dir.get_next()
		dir.list_dir_end()

	# 加载 Skill JSON 配置
	var json_path = "res://Tables/Json/Skill/SkillConfig.json"
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_text) == OK:
				_skill_json_config = json.data

## 刷新 Buff 资源和 JSON 配置
func _refresh_buffs() -> void:
	_buff_resource_cache.clear()
	_buff_json_config.clear()

	# 加载 Buff 资源文件
	var buffs_dir = "res://prefab/Buffs/"
	var dir = DirAccess.open(buffs_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = buffs_dir + file_name
				var resource = load(full_path)
				if resource and resource is AttributeBuff:
					_buff_resource_cache[resource.buff_id] = {
						"path": full_path,
						"resource": resource
					}
			file_name = dir.get_next()
		dir.list_dir_end()

	# 加载 Buff JSON 配置
	var json_path = "res://Tables/Json/Buff/BuffConfig.json"
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_text) == OK:
				_buff_json_config = json.data

## 刷新 Enemy 配置
func _refresh_enemies() -> void:
	_enemy_config_data.clear()

	var config_path = "res://Tables/Json/Enemy/EnemyConfig.json"
	if not FileAccess.file_exists(config_path):
		return

	var file = FileAccess.open(config_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_text) == OK:
			_enemy_config_data = json.data

## 重建树结构
func _rebuild_tree() -> void:
	if _tree == null or not is_inside_tree():
		return

	_tree.clear()
	var root = _tree.create_item()

	# Enemy 节点
	for enemy_id in _enemy_config_data.keys():
		var enemy_data = _enemy_config_data[enemy_id]
		var display_name = enemy_data.get("display_name", str(enemy_id))

		var enemy_item = _tree.create_item(root)
		enemy_item.set_text(0, display_name)
		enemy_item.set_text(1, str(enemy_id))
		enemy_item.set_metadata(0, {META_TYPE: "enemy", META_ENEMY_ID: str(enemy_id), META_ID: str(enemy_id)})
		enemy_item.collapsed = false

		# Skills 子节点
		var skills_container = _tree.create_item(enemy_item)
		skills_container.set_text(0, "Skills")
		skills_container.set_text(1, "")
		skills_container.set_metadata(0, {META_TYPE: "enemy_skills", META_ENEMY_ID: str(enemy_id)})
		skills_container.collapsed = false

		var skill_ids = enemy_data.get("skills", [])
		for skill_id in skill_ids:
			var skill_id_str = str(skill_id)
			var skill_name = skill_id_str
			if _skill_resource_cache.has(skill_id_str):
				skill_name = _skill_resource_cache[skill_id_str]["resource"].skill_name
			var skill_item = _tree.create_item(skills_container)
			skill_item.set_text(0, skill_name if skill_name else skill_id_str)
			skill_item.set_text(1, skill_id_str)
			skill_item.set_metadata(0, {
				META_TYPE: "skill",
				META_ENEMY_ID: str(enemy_id),
				META_ID: skill_id_str
			})

		# Buffs 子节点
		var buffs_container = _tree.create_item(enemy_item)
		buffs_container.set_text(0, "Buffs")
		buffs_container.set_text(1, "")
		buffs_container.set_metadata(0, {META_TYPE: "enemy_buffs", META_ENEMY_ID: str(enemy_id)})
		buffs_container.collapsed = false

		var buff_ids = enemy_data.get("buffs", [])
		for buff_id in buff_ids:
			var buff_id_str = str(buff_id)
			var buff_name = buff_id_str
			if _buff_resource_cache.has(buff_id_str):
				buff_name = _buff_resource_cache[buff_id_str]["resource"].buff_name
			var buff_item = _tree.create_item(buffs_container)
			buff_item.set_text(0, buff_name if buff_name else buff_id_str)
			buff_item.set_text(1, buff_id_str)
			buff_item.set_metadata(0, {
				META_TYPE: "buff",
				META_ENEMY_ID: str(enemy_id),
				META_ID: buff_id_str
			})

## 树节点选中事件
func _on_tree_item_selected() -> void:
	var selected = _tree.get_selected()
	if selected == null:
		return

	var meta = selected.get_metadata(0)
	if meta == null:
		return

	_current_type = meta.get(META_TYPE, "")
	_selected_enemy_id = meta.get(META_ENEMY_ID, "")
	_selected_skill_id = ""
	_selected_buff_id = ""

	if _current_type == "skill":
		_selected_skill_id = meta.get(META_ID, "")
	elif _current_type == "buff":
		_selected_buff_id = meta.get(META_ID, "")

	_update_edit_panels()

## 更新编辑面板（左侧 JSON + 右侧 Inspector）
func _update_edit_panels() -> void:
	# 清空左侧 JSON 编辑区
	if _json_edit_container:
		for child in _json_edit_container.get_children():
			child.queue_free()

	# 清空右侧 Inspector 区
	if _inspector_container:
		for child in _inspector_container.get_children():
			child.queue_free()

	# 根据类型显示不同内容
	match _current_type:
		"", "enemy_skills", "enemy_buffs":
			_show_empty_panels()
		"enemy":
			_show_enemy_panels()
		"skill":
			_show_skill_panels()
		"buff":
			_show_buff_panels()

## 显示空面板
func _show_empty_panels() -> void:
	if _json_edit_container:
		var label = Label.new()
		label.text = "请选择资源"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_json_edit_container.add_child(label)

	if _inspector_container:
		var label = Label.new()
		label.text = "请选择资源"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_inspector_container.add_child(label)

## 显示 Enemy 编辑面板
func _show_enemy_panels() -> void:
	# 左侧：Enemy JSON 配置
	if _json_edit_container:
		var title = Label.new()
		title.text = "Enemy: " + _selected_enemy_id
		title.add_theme_font_size_override("font_size", 16)
		_json_edit_container.add_child(title)

		if _enemy_config_data.has(_selected_enemy_id):
			var enemy_data = _enemy_config_data[_selected_enemy_id]

			# 基础配置
			_add_json_field("display_name", enemy_data.get("display_name", ""))
			_add_json_field("prefab_path", enemy_data.get("prefab_path", ""))
			_add_json_field("spawn_flow_id", enemy_data.get("spawn_flow_id", ""))
			_add_json_field("death_flow_id", enemy_data.get("death_flow_id", ""))

			# 属性配置
			var attr_title = Label.new()
			attr_title.text = "属性配置"
			_json_edit_container.add_child(attr_title)

			var attr_data = enemy_data.get("attributes", {})
			for attr_key in attr_data.keys():
				_add_json_field(attr_key, str(attr_data[attr_key]), "attr_")

			# 添加属性按钮
			var add_btn = Button.new()
			add_btn.text = "添加属性"
			add_btn.pressed.connect(_on_add_enemy_attribute)
			_json_edit_container.add_child(add_btn)

	# 右侧：Enemy 无 Resource 文件，显示提示
	if _inspector_container:
		var label = Label.new()
		label.text = "Enemy 配置无 Resource 文件\n预制体编辑请使用场景编辑器"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_inspector_container.add_child(label)

## 显示 Skill 编辑面板
func _show_skill_panels() -> void:
	# 左侧：Skill JSON 数值配置
	if _json_edit_container:
		var title = Label.new()
		title.text = "Skill JSON: " + _selected_skill_id
		title.add_theme_font_size_override("font_size", 16)
		_json_edit_container.add_child(title)

		if _skill_json_config.has(_selected_skill_id):
			var skill_json = _skill_json_config[_selected_skill_id]
			for key in skill_json.keys():
				_add_json_field(key, str(skill_json[key]), "skill_json_", _selected_skill_id)
		else:
			var label = Label.new()
			label.text = "无 JSON 配置数据"
			_json_edit_container.add_child(label)

			var create_btn = Button.new()
			create_btn.text = "创建 JSON 配置"
			create_btn.pressed.connect(_on_create_skill_json_config)
			_json_edit_container.add_child(create_btn)

	# 右侧：Skill Resource Inspector（自动扫描属性）
	if _inspector_container:
		if _skill_resource_cache.has(_selected_skill_id):
			var skill = _skill_resource_cache[_selected_skill_id]["resource"]
			_show_auto_inspector(skill)
		else:
			var label = Label.new()
			label.text = "无 Skill Resource 文件"
			_inspector_container.add_child(label)

## 显示 Buff 编辑面板
func _show_buff_panels() -> void:
	# 左侧：Buff JSON 数值配置
	if _json_edit_container:
		var title = Label.new()
		title.text = "Buff JSON: " + _selected_buff_id
		title.add_theme_font_size_override("font_size", 16)
		_json_edit_container.add_child(title)

		if _buff_json_config.has(_selected_buff_id):
			var buff_json = _buff_json_config[_selected_buff_id]
			for key in buff_json.keys():
				_add_json_field(key, str(buff_json[key]), "buff_json_", _selected_buff_id)
		else:
			var label = Label.new()
			label.text = "无 JSON 配置数据"
			_json_edit_container.add_child(label)

			var create_btn = Button.new()
			create_btn.text = "创建 JSON 配置"
			create_btn.pressed.connect(_on_create_buff_json_config)
			_json_edit_container.add_child(create_btn)

	# 右侧：Buff Resource Inspector（自动扫描属性）
	if _inspector_container:
		if _buff_resource_cache.has(_selected_buff_id):
			var buff = _buff_resource_cache[_selected_buff_id]["resource"]
			_show_auto_inspector(buff)
		else:
			var label = Label.new()
			label.text = "无 Buff Resource 文件"
			_inspector_container.add_child(label)

## 自动显示 Inspector（扫描 Resource 属性）
func _show_auto_inspector(resource: Resource) -> void:
	var title = Label.new()
	title.text = "Resource: " + resource.resource_path
	title.add_theme_font_size_override("font_size", 14)
	_inspector_container.add_child(title)

	var prop_list = resource.get_property_list()
	for prop in prop_list:
		# 只显示存储属性（@export）
		if prop.usage & PROPERTY_USAGE_STORAGE:
			var prop_name = prop.name
			if prop_name == "script":
				continue  # 跳过 script 属性

			var prop_value = resource.get(prop_name)
			var prop_type = prop.type

			# 根据类型创建编辑控件
			_add_inspector_field(prop_name, prop_value, prop_type, resource)

## 添加 Inspector 字段（根据类型自动选择控件）
func _add_inspector_field(prop_name: String, prop_value: Variant, prop_type: int, resource: Resource) -> void:
	var hbox = HBoxContainer.new()
	_inspector_container.add_child(hbox)

	var label = Label.new()
	label.text = prop_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Label 自动扩展填充左侧
	hbox.add_child(label)

	# 根据类型创建控件（固定宽度，吸附右侧）
	match prop_type:
		TYPE_STRING:
			var edit = LineEdit.new()
			edit.text = str(prop_value)
			edit.custom_minimum_size = Vector2(150, 0)  # 固定宽度 150
			edit.size_flags_horizontal = Control.SIZE_SHRINK_END  # 吸附右侧
			edit.set_meta("prop_name", prop_name)
			edit.set_meta("resource", resource)
			edit.text_changed.connect(_on_inspector_string_changed.bind(edit))
			hbox.add_child(edit)
		TYPE_FLOAT, TYPE_INT:
			var spin = SpinBox.new()
			spin.value = float(prop_value)
			spin.min_value = -999999
			spin.max_value = 999999
			spin.step = 1.0 if prop_type == TYPE_INT else 0.1
			spin.custom_minimum_size = Vector2(150, 0)  # 固定宽度 150
			spin.size_flags_horizontal = Control.SIZE_SHRINK_END  # 吸附右侧
			spin.set_meta("prop_name", prop_name)
			spin.set_meta("resource", resource)
			spin.value_changed.connect(_on_inspector_number_changed.bind(spin))
			hbox.add_child(spin)
		TYPE_BOOL:
			var check = CheckBox.new()
			check.size_flags_horizontal = Control.SIZE_SHRINK_END  # 吸附右侧
			check.set_meta("prop_name", prop_name)
			check.set_meta("resource", resource)
			check.toggled.connect(_on_inspector_bool_changed.bind(check))
			hbox.add_child(check)
		TYPE_OBJECT:
			# 资源引用类型，显示路径
			var obj_label = Label.new()
			if prop_value and prop_value is Resource:
				obj_label.text = prop_value.resource_path
			else:
				obj_label.text = "null"
			obj_label.custom_minimum_size = Vector2(150, 0)  # 固定宽度 150
			obj_label.size_flags_horizontal = Control.SIZE_SHRINK_END  # 吸附右侧
			hbox.add_child(obj_label)
		_:
			# 其他类型，显示文本
			var edit = LineEdit.new()
			edit.text = str(prop_value)
			edit.custom_minimum_size = Vector2(150, 0)  # 固定宽度 150
			edit.size_flags_horizontal = Control.SIZE_SHRINK_END  # 吸附右侧
			edit.editable = false
			hbox.add_child(edit)

## 添加 JSON 字段
func _add_json_field(key: String, value: String, prefix: String = "", config_id: String = "") -> void:
	var hbox = HBoxContainer.new()
	_json_edit_container.add_child(hbox)

	var label = Label.new()
	label.text = key
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Label 自动扩展填充左侧
	hbox.add_child(label)

	var edit = LineEdit.new()
	edit.text = value
	edit.custom_minimum_size = Vector2(150, 0)  # 固定宽度 150
	edit.size_flags_horizontal = Control.SIZE_SHRINK_END  # 吸附右侧
	edit.set_meta("json_key", key)
	edit.set_meta("json_prefix", prefix)
	edit.set_meta("config_id", config_id)
	edit.text_changed.connect(_on_json_field_changed.bind(edit))
	hbox.add_child(edit)

## Inspector 字段变更处理
func _on_inspector_string_changed(new_text: String, edit: LineEdit) -> void:
	var resource = edit.get_meta("resource")
	var prop_name = edit.get_meta("prop_name")
	if resource:
		resource.set(prop_name, new_text)

func _on_inspector_number_changed(value: float, spin: SpinBox) -> void:
	var resource = spin.get_meta("resource")
	var prop_name = spin.get_meta("prop_name")
	if resource:
		resource.set(prop_name, value)

func _on_inspector_bool_changed(pressed: bool, check: CheckBox) -> void:
	var resource = check.get_meta("resource")
	var prop_name = check.get_meta("prop_name")
	if resource:
		resource.set(prop_name, pressed)

## JSON 字段变更处理
func _on_json_field_changed(new_text: String, edit: LineEdit) -> void:
	var key = edit.get_meta("json_key")
	var prefix = edit.get_meta("json_prefix")
	var config_id = edit.get_meta("config_id")

	if prefix.begins_with("attr_"):
		# Enemy 属性
		if _enemy_config_data.has(config_id):
			var attr_key = key
			var attr_data = _enemy_config_data[config_id].get("attributes", {})
			attr_data[attr_key] = float(new_text)
			_enemy_config_data[config_id]["attributes"] = attr_data
	elif prefix.begins_with("skill_json_"):
		# Skill JSON
		if _skill_json_config.has(config_id):
			var old_value = _skill_json_config[config_id].get(key)
			if old_value is float or old_value is int:
				_skill_json_config[config_id][key] = float(new_text)
			else:
				_skill_json_config[config_id][key] = new_text
	elif prefix.begins_with("buff_json_"):
		# Buff JSON
		if _buff_json_config.has(config_id):
			var old_value = _buff_json_config[config_id].get(key)
			if old_value is float or old_value is int:
				_buff_json_config[config_id][key] = float(new_text)
			else:
				_buff_json_config[config_id][key] = new_text
	else:
		# Enemy 基础字段
		if _enemy_config_data.has(config_id):
			_enemy_config_data[config_id][key] = new_text

## 创建 Skill JSON 配置
func _on_create_skill_json_config() -> void:
	if _selected_skill_id.is_empty():
		return
	_skill_json_config[_selected_skill_id] = {
		"damage": 10.0,
		"level": 1,
		"cooldown": 3.0
	}
	_save_skill_json()
	call_deferred("_update_edit_panels")

## 创建 Buff JSON 配置
func _on_create_buff_json_config() -> void:
	if _selected_buff_id.is_empty():
		return
	_buff_json_config[_selected_buff_id] = {
		"duration": 5.0,
		"tick_interval": 1.0
	}
	_save_buff_json()
	call_deferred("_update_edit_panels")

## 添加 Enemy 属性
func _on_add_enemy_attribute() -> void:
	if _selected_enemy_id.is_empty() or not _enemy_config_data.has(_selected_enemy_id):
		return
	var attr_data = _enemy_config_data[_selected_enemy_id].get("attributes", {})
	attr_data["new_attr"] = 0
	_enemy_config_data[_selected_enemy_id]["attributes"] = attr_data
	call_deferred("_update_edit_panels")

## 保存按钮
func _on_save_pressed() -> void:
	match _current_type:
		"enemy":
			_save_enemy_config()
		"skill":
			_save_skill_resource()
			_save_skill_json()
		"buff":
			_save_buff_resource()
			_save_buff_json()

## 保存 Enemy 配置
func _save_enemy_config() -> void:
	var path = "res://Tables/Json/Enemy/EnemyConfig.json"
	var json_text = JSON.stringify(_enemy_config_data, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()
		print("Enemy 配置已保存")

## 保存 Skill Resource
func _save_skill_resource() -> void:
	if _skill_resource_cache.has(_selected_skill_id):
		var data = _skill_resource_cache[_selected_skill_id]
		ResourceSaver.save(data["resource"], data["path"])
		print("Skill Resource 已保存")

## 保存 Skill JSON
func _save_skill_json() -> void:
	var path = "res://Tables/Json/Skill/SkillConfig.json"
	var json_text = JSON.stringify(_skill_json_config, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()
		print("Skill JSON 已保存")

## 保存 Buff Resource
func _save_buff_resource() -> void:
	if _buff_resource_cache.has(_selected_buff_id):
		var data = _buff_resource_cache[_selected_buff_id]
		ResourceSaver.save(data["resource"], data["path"])
		print("Buff Resource 已保存")

## 保存 Buff JSON
func _save_buff_json() -> void:
	var path = "res://Tables/Json/Buff/BuffConfig.json"
	var json_text = JSON.stringify(_buff_json_config, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()
		print("Buff JSON 已保存")

## 定位按钮
func _on_locate_pressed() -> void:
	match _current_type:
		"enemy":
			_locate_file("res://Tables/Json/Enemy/EnemyConfig.json")
		"skill":
			if _skill_resource_cache.has(_selected_skill_id):
				_locate_file(_skill_resource_cache[_selected_skill_id]["path"])
		"buff":
			if _buff_resource_cache.has(_selected_buff_id):
				_locate_file(_buff_resource_cache[_selected_buff_id]["path"])

## 定位文件
func _locate_file(file_path: String) -> void:
	if _editor_interface:
		_editor_interface.get_file_system_dock().navigate_to_path(file_path)
	else:
		OS.shell_open(ProjectSettings.globalize_path(file_path).get_base_dir())

## 新建按钮
func _on_new_pressed() -> void:
	print("_on_new_pressed: _current_type=%s, _selected_enemy_id=%s, _selected_skill_id=%s, _selected_buff_id=%s" % [_current_type, _selected_enemy_id, _selected_skill_id, _selected_buff_id])

	match _current_type:
		"", "enemy":
			# 未选中或选中 Enemy 根节点 -> 新建 Enemy
			_show_new_enemy_dialog()
		"enemy_skills":
			# 选中 Skills 容器 -> 新建 Skill（已有正确的 Enemy ID）
			if _selected_enemy_id.is_empty():
				push_warning("请先选择一个 Enemy")
				return
			_create_new_skill_for_enemy()
		"enemy_buffs":
			# 选中 Buffs 容器 -> 新建 Buff（已有正确的 Enemy ID）
			if _selected_enemy_id.is_empty():
				push_warning("请先选择一个 Enemy")
				return
			_create_new_buff_for_enemy()
		"skill":
			# 选中具体 Skill -> 在同一 Enemy 下新建 Skill
			if _selected_enemy_id.is_empty():
				push_warning("请先选择一个 Enemy")
				return
			_create_new_skill_for_enemy()
		"buff":
			# 选中具体 Buff -> 在同一 Enemy 下新建 Buff
			if _selected_enemy_id.is_empty():
				push_warning("请先选择一个 Enemy")
				return
			_create_new_buff_for_enemy()

## 显示新建 Enemy 对话框
func _show_new_enemy_dialog() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "新建 Enemy"
	dialog.min_size = Vector2i(300, 150)

	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)

	var id_edit = _add_dialog_field(vbox, "Enemy ID:", "例如: 1000")
	var name_edit = _add_dialog_field(vbox, "显示名称:", "例如: 测试怪物")

	dialog.confirmed.connect(func():
		_create_new_enemy(id_edit.text, name_edit.text)
		dialog.queue_free()
	)

	add_child(dialog)
	dialog.popup_centered()

## 显示新建子资源对话框
func _show_new_child_dialog() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "新建子资源"
	dialog.min_size = Vector2i(250, 100)

	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)

	var type_option = OptionButton.new()
	type_option.add_item("Skill")
	type_option.add_item("Buff")
	vbox.add_child(type_option)

	dialog.confirmed.connect(func():
		if type_option.selected == 0:
			_create_new_skill_for_enemy()
		else:
			_create_new_buff_for_enemy()
		dialog.queue_free()
	)

	add_child(dialog)
	dialog.popup_centered()

## 添加对话框字段
func _add_dialog_field(container: Container, label_text: String, placeholder: String) -> LineEdit:
	var hbox = HBoxContainer.new()
	container.add_child(hbox)
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(label)
	var edit = LineEdit.new()
	edit.placeholder_text = placeholder
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(edit)
	return edit

## 创建新 Enemy
func _create_new_enemy(enemy_id: String, display_name: String) -> void:
	if enemy_id.is_empty():
		return

	_enemy_config_data[enemy_id] = {
		"display_name": display_name,
		"prefab_path": "",
		"attributes": {},
		"skills": [],
		"buffs": [],
		"spawn_flow_id": "",
		"death_flow_id": ""
	}
	_save_enemy_config()
	call_deferred("_refresh_all")

## 创建新 Skill
func _create_new_skill_for_enemy() -> void:
	if _selected_enemy_id.is_empty() or not _enemy_config_data.has(_selected_enemy_id):
		return

	var skill_ids = _enemy_config_data[_selected_enemy_id].get("skills", [])
	var skill_index = skill_ids.size() + 1
	var skill_id = "10" + str(skill_index) + _selected_enemy_id

	# 创建 Resource
	var skill = SkillBase.new()
	skill.skill_id = skill_id
	skill.skill_name = "Skill_" + skill_id

	var path = "res://prefab/Skills/%s_Skill.tres" % skill_id
	ResourceSaver.save(skill, path)

	# 创建 JSON 配置
	_skill_json_config[skill_id] = {
		"damage": 10.0,
		"level": 1,
		"cooldown": 3.0
	}
	_save_skill_json()

	# 更新 Enemy
	skill_ids.append(skill_id)
	_enemy_config_data[_selected_enemy_id]["skills"] = skill_ids
	_save_enemy_config()

	call_deferred("_refresh_all")

## 创建新 Buff
func _create_new_buff_for_enemy() -> void:
	if _selected_enemy_id.is_empty() or not _enemy_config_data.has(_selected_enemy_id):
		return

	var buff_ids = _enemy_config_data[_selected_enemy_id].get("buffs", [])
	var buff_index = buff_ids.size() + 1
	var buff_id = "20" + str(buff_index) + _selected_enemy_id

	# 创建 Resource
	var buff = AttributeBuff.new()
	buff.buff_id = buff_id
	buff.buff_name = "Buff_" + buff_id

	var path = "res://prefab/Buffs/%s.tres" % buff_id
	ResourceSaver.save(buff, path)

	# 创建 JSON 配置
	_buff_json_config[buff_id] = {
		"duration": 5.0,
		"tick_interval": 1.0
	}
	_save_buff_json()

	# 更新 Enemy
	buff_ids.append(buff_id)
	_enemy_config_data[_selected_enemy_id]["buffs"] = buff_ids
	_save_enemy_config()

	call_deferred("_refresh_all")

## 删除按钮
func _on_delete_pressed() -> void:
	match _current_type:
		"enemy":
			_show_delete_confirm("Enemy", _selected_enemy_id, _execute_delete_enemy)
		"skill":
			_show_delete_confirm("Skill", _selected_skill_id, _execute_delete_skill)
		"buff":
			_show_delete_confirm("Buff", _selected_buff_id, _execute_delete_buff)

## 显示删除确认对话框
func _show_delete_confirm(type_name: String, item_id: String, callback: Callable) -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "确认删除"
	dialog.dialog_text = "确定要删除 %s \"%s\" 吗？" % [type_name, item_id]
	dialog.get_ok_button().text = "确定"
	dialog.get_cancel_button().text = "取消"
	dialog.confirmed.connect(callback)
	add_child(dialog)
	dialog.popup_centered()

## 执行删除 Enemy
func _execute_delete_enemy() -> void:
	if _selected_enemy_id.is_empty():
		return

	# 删除关联 Skills
	var skill_ids = _enemy_config_data[_selected_enemy_id].get("skills", [])
	for skill_id in skill_ids:
		if _skill_resource_cache.has(str(skill_id)):
			DirAccess.remove_absolute(_skill_resource_cache[str(skill_id)]["path"].replace("res://", ""))
		_skill_json_config.erase(str(skill_id))

	# 删除关联 Buffs
	var buff_ids = _enemy_config_data[_selected_enemy_id].get("buffs", [])
	for buff_id in buff_ids:
		if _buff_resource_cache.has(str(buff_id)):
			DirAccess.remove_absolute(_buff_resource_cache[str(buff_id)]["path"].replace("res://", ""))
		_buff_json_config.erase(str(buff_id))

	_enemy_config_data.erase(_selected_enemy_id)
	_save_enemy_config()
	_save_skill_json()
	_save_buff_json()

	_selected_enemy_id = ""
	call_deferred("_refresh_all")

## 执行删除 Skill
func _execute_delete_skill() -> void:
	if _selected_skill_id.is_empty():
		return

	if _skill_resource_cache.has(_selected_skill_id):
		DirAccess.remove_absolute(_skill_resource_cache[_selected_skill_id]["path"].replace("res://", ""))

	_skill_json_config.erase(_selected_skill_id)

	if _enemy_config_data.has(_selected_enemy_id):
		var skill_ids = _enemy_config_data[_selected_enemy_id].get("skills", [])
		skill_ids.erase(_selected_skill_id)
		_enemy_config_data[_selected_enemy_id]["skills"] = skill_ids
		_save_enemy_config()

	_save_skill_json()
	call_deferred("_refresh_all")

## 执行删除 Buff
func _execute_delete_buff() -> void:
	if _selected_buff_id.is_empty():
		return

	if _buff_resource_cache.has(_selected_buff_id):
		DirAccess.remove_absolute(_buff_resource_cache[_selected_buff_id]["path"].replace("res://", ""))

	_buff_json_config.erase(_selected_buff_id)

	if _enemy_config_data.has(_selected_enemy_id):
		var buff_ids = _enemy_config_data[_selected_enemy_id].get("buffs", [])
		buff_ids.erase(_selected_buff_id)
		_enemy_config_data[_selected_enemy_id]["buffs"] = buff_ids
		_save_enemy_config()

	_save_buff_json()
	call_deferred("_refresh_all")

## 刷新按钮
func _on_refresh_pressed() -> void:
	_refresh_all()
