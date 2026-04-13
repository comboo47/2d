class_name UIPanel extends Control

## 面板类型
enum PanelType {
	HUD,      # 战斗 HUD
	MENU,     # 菜单
	DIALOG,   # 对话框
	POPUP     # 弹出窗口
}

## 信号
signal panel_closed
signal panel_action(action_name: String)

## 配置
@export var panel_type: PanelType = PanelType.MENU
@export var close_on_escape: bool = true
@export var pause_game: bool = false

## 状态
var _is_open: bool = false

func _ready() -> void:
	# 菜单类型面板在暂停时也能处理输入
	if pause_game:
		process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	else:
		# 非暂停面板也需要处理输入（如主菜单）
		process_mode = Node.PROCESS_MODE_ALWAYS

	# 初始隐藏（除非是作为主场景运行）
	# 检查是否是场景树的根节点（表示场景独立运行）
	var tree = get_tree()
	if tree and tree.current_scene != self:
		hide()

func _input(event: InputEvent) -> void:
	# 当面板打开时，只消费面板外部的输入事件防止穿透到游戏逻辑
	if _is_open and event is InputEventMouseButton:
		# 检查点击是否在面板矩形内
		var local_pos = get_global_rect()
		if not local_pos.has_point(event.global_position):
			# 点击在面板外部，消费它防止穿透
			get_viewport().set_input_as_handled()

	# ESC 处理
	if _is_open and close_on_escape and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func open() -> void:
	_is_open = true
	show()
	if pause_game:
		get_tree().paused = true

func close() -> void:
	_is_open = false
	hide()
	panel_closed.emit()

	if pause_game and get_tree().paused:
		get_tree().paused = false

func perform_action(action: String) -> void:
	panel_action.emit(action)

## 是否已打开
func is_open() -> bool:
	return _is_open