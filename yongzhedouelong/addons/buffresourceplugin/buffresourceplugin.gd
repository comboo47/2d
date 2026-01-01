@tool
extends EditorPlugin

var btn:Button
func _enter_tree():
	# 使用正确的常量名
	btn = _make_button()
	add_control_to_container(EditorPlugin.CONTAINER_INSPECTOR_BOTTOM, btn)

func _make_button() -> Button:
	var btn = Button.new()
	btn.text = "应用并写入子资源数据"
	btn.pressed.connect(_on_button_pressed)
	return btn

func _on_button_pressed():
	var inspected = get_editor_interface().get_inspector().get_edited_object()
	
	if inspected and inspected is AttributeBuff: # 请确保这里是你自定义资源的实际类名
		inspected.write_all_children_data()
		print("已在编辑器界面中触发了数据处理。")
	else:
		print("请先选中一个 MyParentResource 资源。")

func _exit_tree():
	# 清理时也需要使用相同的常量
	remove_control_from_container(EditorPlugin.CONTAINER_INSPECTOR_BOTTOM, btn)
