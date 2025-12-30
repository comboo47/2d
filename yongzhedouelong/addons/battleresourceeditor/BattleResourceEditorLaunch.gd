@tool
extends EditorPlugin

var multi_inspector

func _enter_tree():
	# 创建多检查器实例
	multi_inspector = preload("res://addons/battleresourceeditor/EditorCanvas.tscn").instantiate()
	get_editor_interface().get_base_control().add_child(multi_inspector)
	#multi_inspector.hide()
	
	# 添加快捷键
	_setup_shortcuts()
	
	# 添加编辑器菜单项
	_add_menu_items()

func _setup_shortcuts():
	var shortcut = Shortcut.new()
	var event = InputEventKey.new()
	event.keycode = KEY_T
	event.ctrl_pressed = true
	event.shift_pressed = true
	shortcut.events = [event]
	
	# 使用_shortcut_input处理
	# 或使用InputMap（注意不要与已有冲突）

func _add_menu_items():
	# 在编辑器中添加菜单
	add_tool_menu_item("打开多资源检查器", _on_open_multi_inspector_menu)

func _on_open_multi_inspector_menu():
	# 获取当前选中的资源
	var selected = get_editor_interface().get_selection().get_selected_nodes()
	if selected.size() > 0:
		var script = selected[0].get_script()
		if script is Resource:
			multi_inspector.open_resource(script)
			multi_inspector.popup_centered(Vector2i(1200, 800))

# 在检查器中添加按钮，用于打开多检查器
func _forward_canvas_gui_input(event):
	# 可以在这里检测是否在检查器中点击了某个特殊按钮
	pass

func _shortcut_input(event):
	if (event is InputEventKey and 
		event.keycode == KEY_T and 
		event.ctrl_pressed and 
		event.shift_pressed and
		not event.pressed):
		
		# 获取当前检查器中的资源
		var inspected = get_editor_interface().get_inspected_object()
		if inspected is Resource:
			multi_inspector.open_resource(inspected)
			multi_inspector.popup_centered(Vector2i(1200, 800))
			return true
	return false
