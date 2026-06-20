@tool
extends EditorPlugin
## GPManager —— Gameplay 内容管理器插件入口（独立插件，不依赖 BattleEditor）。
## 管理 Actor / Weapon / Bullet / Skill / Buff / Trait 六类 .tres。
## 以 Dock 形式呈现（左下停靠），另提供 Tools 菜单项兜底打开为窗口。
## 编辑采用「方案 B」：选中资源后路由到 Godot 主 Inspector 编辑，
## 本插件只负责内容管理（浏览/新建/复制/模板/删除/校验）。

const PanelScript = preload("res://addons/gpmanager/GPManagerPanel.gd")

var _dock: Control = null

func _enter_tree() -> void:
	_dock = PanelScript.new()
	_dock.name = "Gameplay"
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, _dock)
	add_tool_menu_item("GPManager (Focus Dock)", _on_focus_dock)

func _exit_tree() -> void:
	remove_tool_menu_item("GPManager (Focus Dock)")
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null

## 菜单项：把 Dock 所在的 tab 切到前台（兜底入口）。
func _on_focus_dock() -> void:
	if _dock and is_instance_valid(_dock):
		_dock.show()
		if _dock.has_method("refresh"):
			_dock.refresh()
