@tool
extends Window

class_name MultiInspector

# 当前打开的资源栈（支持导航历史）
var resource_stack: Array[Resource] = []
# 资源->面板的映射
var resource_panels: Dictionary = {}
# 当前活动的检查器面板
var active_panels: Array[Control] = []

@onready var nav_label: Label = $VBoxContainer/NavBar/PathLabel
@onready var tab_container: TabContainer = $VBoxContainer/HSplitContainer/TabContainer
@onready var resource_list: VBoxContainer = $VBoxContainer/HSplitContainer/ScrollContainer/ResourceList

# 打开主资源（入口点）
func open_resource(resource: Resource):
	resource_stack.clear()
	resource_stack.append(resource)
	_update_navigation()
	_refresh_ui()

# 打开嵌套资源（从父资源中点击打开）
func open_nested_resource(parent: Resource, property_name: String):
	# 获取父资源中的嵌套资源
	var nested_resource = parent.get(property_name)
	if nested_resource and nested_resource is Resource:
		# 添加到栈中
		resource_stack.append(nested_resource)
		_update_navigation()
		_refresh_ui()
		return true
	return false

# 更新导航显示
func _update_navigation():
	var path_text = ""
	for i in range(resource_stack.size()):
		var res = resource_stack[i]
		var name = _get_resource_display_name(res)
		if i > 0:
			path_text += " ▶ "
		path_text += name
	
	nav_label.text = "路径: " + path_text

# 创建或更新检查器面板
func _refresh_ui():
	# 清空现有面板（保留第一个作为参考）
	_clear_panels()
	
	# 为栈中的每个资源创建检查器
	for i in range(resource_stack.size()):
		var resource = resource_stack[i]
		_create_inspector_panel(resource, i == resource_stack.size() - 1)

# 为单个资源创建检查器面板
func _create_inspector_panel(resource: Resource, is_active: bool = true):
	# 检查是否已有面板
	if resource_panels.has(resource):
		var existing_panel = resource_panels[resource]
		tab_container.add_child(existing_panel)
		tab_container.set_tab_title(tab_container.get_tab_count() - 1, _get_resource_display_name(resource))
		if is_active:
			tab_container.current_tab = tab_container.get_tab_count() - 1
		return existing_panel
	
	# 创建新面板
	var panel = ScrollContainer.new()
	panel.name = "InspectorPanel_" + str(resource.get_instance_id())
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var content = VBoxContainer.new()
	content.name = "Content"
	panel.add_child(content)
	
	# 添加标题
	var header = PanelContainer.new()
	var header_label = Label.new()
	header_label.text = "🔍 " + _get_resource_display_name(resource)
	header_label.add_theme_font_size_override("font_size", 16)
	header.add_child(header_label)
	content.add_child(header)
	
	# 🔥 核心：递归创建属性编辑器
	_create_property_editors(resource, content)
	
	# 添加到UI
	tab_container.add_child(panel)
	tab_container.set_tab_title(tab_container.get_tab_count() - 1, _get_resource_display_name(resource))
	
	# 保存引用
	resource_panels[resource] = panel
	
	if is_active:
		tab_container.current_tab = tab_container.get_tab_count() - 1
	
	return panel

# 递归创建属性编辑器
func _create_property_editors(resource: Resource, parent: Control):
	# 获取资源的所有属性
	var property_list = resource.get_property_list()
	
	for property in property_list:
		var name = property["name"]
		var type = property["type"]
		
		# 跳过内部属性
		if name.begins_with("_"):
			continue
		
		# 创建属性行
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.custom_minimum_size.y = 30
		
		# 属性标签
		var label = Label.new()
		label.text = _format_property_name(name)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = 0.4
		row.add_child(label)
		
		# 根据属性类型创建编辑器
		var editor = _create_editor_for_type(resource, name, type)
		if editor:
			editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			editor.size_flags_stretch_ratio = 0.6
			row.add_child(editor)
		
		parent.add_child(row)
		
		# 如果是Resource类型，添加"打开"按钮
		if type == TYPE_OBJECT:
			var value = resource.get(name)
			if value is Resource and value != resource:  # 避免自引用
				var open_btn = Button.new()
				open_btn.text = "打开"
				open_btn.pressed.connect(_on_open_nested_resource.bind(resource, name))
				row.add_child(open_btn)

# 根据类型创建对应的编辑器控件
func _create_editor_for_type(resource: Resource, property_name: String, type: int) -> Control:
	var current_value = resource.get(property_name)
	
	match type:
		TYPE_STRING:
			var edit = LineEdit.new()
			edit.text = str(current_value)
			edit.text_changed.connect(_on_string_changed.bind(resource, property_name))
			return edit
		
		TYPE_INT:
			var edit = SpinBox.new()
			edit.min_value = -999999
			edit.max_value = 999999
			edit.value = current_value
			edit.value_changed.connect(_on_int_changed.bind(resource, property_name))
			return edit
		
		TYPE_FLOAT:
			var edit = EditorSpinSlider.new() if ClassDB.class_exists("EditorSpinSlider") else SpinBox.new()
			edit.min_value = -999999.0
			edit.max_value = 999999.0
			edit.step = 0.01
			edit.value = current_value
			edit.value_changed.connect(_on_float_changed.bind(resource, property_name))
			return edit
		
		TYPE_BOOL:
			var edit = CheckBox.new()
			edit.button_pressed = current_value
			edit.toggled.connect(_on_bool_changed.bind(resource, property_name))
			return edit
		
		TYPE_COLOR:
			var edit = ColorPickerButton.new()
			edit.color = current_value
			edit.color_changed.connect(_on_color_changed.bind(resource, property_name))
			return edit
		
		TYPE_OBJECT:
			# 对于嵌套Resource，显示其名称和类型
			var hbox = HBoxContainer.new()
			var label = Label.new()
			if current_value is Resource:
				label.text = current_value.resource_path.get_file() if current_value.resource_path else "未保存的资源"
			else:
				label.text = "无"
			hbox.add_child(label)
			return hbox
		
		_:
			# 默认文本显示
			var label = Label.new()
			label.text = str(current_value)
			return label

# 属性变更回调
func _on_string_changed(new_text: String, resource: Resource, property_name: String):
	resource.set(property_name, new_text)
	_mark_resource_dirty(resource)

func _on_int_changed(new_value: float, resource: Resource, property_name: String):
	resource.set(property_name, int(new_value))
	_mark_resource_dirty(resource)

func _on_float_changed(new_value: float, resource: Resource, property_name: String):
	resource.set(property_name, new_value)
	_mark_resource_dirty(resource)

func _on_bool_changed(new_value: bool, resource: Resource, property_name: String):
	resource.set(property_name, new_value)
	_mark_resource_dirty(resource)

func _on_color_changed(new_color: Color, resource: Resource, property_name: String):
	resource.set(property_name, new_color)
	_mark_resource_dirty(resource)

# 打开嵌套资源
func _on_open_nested_resource(parent: Resource, property_name: String):
	open_nested_resource(parent, property_name)

# 标记资源需要保存
func _mark_resource_dirty(resource: Resource):
	# 更新UI指示器
	var tab_idx = _find_tab_for_resource(resource)
	if tab_idx >= 0:
		var title = tab_container.get_tab_title(tab_idx)
		if not title.ends_with(" *"):
			tab_container.set_tab_title(tab_idx, title + " *")

# 保存所有资源
func _save_all():
	for resource in resource_panels.keys():
		if resource.resource_path:
			var error = ResourceSaver.save(resource, resource.resource_path)
			if error == OK:
				print("已保存: ", resource.resource_path)
				# 移除脏标记
				var tab_idx = _find_tab_for_resource(resource)
				if tab_idx >= 0:
					var title = tab_container.get_tab_title(tab_idx)
					if title.ends_with(" *"):
						tab_container.set_tab_title(tab_idx, title.trim_suffix(" *"))

# 工具函数
func _get_resource_display_name(resource: Resource) -> String:
	if resource.resource_path:
		return resource.resource_path.get_file()
	elif resource.has_method("get_display_name"):
		return resource.get_display_name()
	else:
		return resource.get_class() + " #" + str(resource.get_instance_id())

func _format_property_name(name: String) -> String:
	return name.capitalize().replace("_", " ")

func _find_tab_for_resource(resource: Resource) -> int:
	for i in range(tab_container.get_tab_count()):
		if tab_container.get_child(i) == resource_panels.get(resource):
			return i
	return -1

func _clear_panels():
	# 从tab_container移除子节点，但不销毁
	for child in tab_container.get_children():
		tab_container.remove_child(child)


func _on_close_requested() -> void:
	hide()
	pass # Replace with function body.
