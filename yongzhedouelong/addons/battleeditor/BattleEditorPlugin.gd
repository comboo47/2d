@tool
extends EditorPlugin
## 战斗资源编辑器插件入口
## 提供 Skills、Buffs、Enemies 的创建和管理功能

## 编辑器窗口实例
var _editor_window: Window = null

## 编辑器面板实例
var _editor_panel: Control = null

func _enter_tree() -> void:
	# 添加菜单项
	add_tool_menu_item("Battle Editor", _on_open_editor)

	# 预加载编辑器面板
	_editor_panel = preload("res://addons/battleeditor/UI/BattleEditorPanel.tscn").instantiate()

	# 设置 EditorInterface 引用（用于 Inspector）
	if _editor_panel.has_method("set_editor_interface"):
		_editor_panel.call("set_editor_interface", get_editor_interface())

	# 创建窗口
	_editor_window = Window.new()
	_editor_window.title = "Battle Editor"
	_editor_window.min_size = Vector2i(900, 600)
	_editor_window.wrap_controls = true
	_editor_window.unresizable = false
	_editor_window.borderless = false
	_editor_window.transient = true
	_editor_window.exclusive = false

	# 添加面板到窗口
	_editor_window.add_child(_editor_panel)

	# 添加窗口到编辑器基础控件（初始隐藏）
	get_editor_interface().get_base_control().add_child(_editor_window)
	_editor_window.hide()

	# 窗口关闭时隐藏而非销毁
	_editor_window.close_requested.connect(_on_close_requested)

func _exit_tree() -> void:
	# 移除菜单项
	remove_tool_menu_item("Battle Editor")

	# 清理窗口
	if _editor_window:
		_editor_window.queue_free()
		_editor_window = null
		_editor_panel = null

## 打开编辑器窗口
func _on_open_editor() -> void:
	if _editor_window:
		_editor_window.popup_centered(Vector2i(900, 600))

## 窗口关闭请求处理
func _on_close_requested() -> void:
	if _editor_window:
		_editor_window.hide()

## 快捷键处理（Ctrl+G）
func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_G and event.ctrl_pressed and event.pressed:
			_on_open_editor()
			get_editor_interface().get_base_control().get_viewport().set_input_as_handled()