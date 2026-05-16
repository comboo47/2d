extends Node
## Autoload: InputManager
## 输入管理器 - 集中管理游戏输入，支持输入锁定和冷却机制

## 信号
signal inputs_locked(duration: float)
signal inputs_unlocked()

## 输入锁定状态
var _is_locked: bool = false
var _lock_timer: float = 0.0
var _default_lock_duration: float = 0.2  # 默认冷却时间

## 被锁定的动作列表（可选，用于部分锁定）
var _locked_actions: Array[String] = []

func _ready() -> void:
	# 设置为在暂停时也能处理，确保锁定计时器正常工作
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	# 更新锁定计时器
	if _is_locked and _lock_timer > 0.0:
		_lock_timer -= delta
		if _lock_timer <= 0.0:
			unlock_inputs()

#region 公共 API - 输入锁定
## 锁定所有输入一段时间
func lock_inputs(duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = _default_lock_duration

	_is_locked = true
	_lock_timer = duration
	_locked_actions.clear()  # 全局锁定

	# 强制释放当前按下的游戏输入动作
	_force_release_game_actions()

	inputs_locked.emit(duration)

## 锁定特定动作
func lock_actions(actions: Array[String], duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = _default_lock_duration

	_is_locked = true
	_lock_timer = duration
	_locked_actions = actions

	# 释放被锁定的动作
	for action in actions:
		Input.action_release(action)

	inputs_locked.emit(duration)

## 解除输入锁定
func unlock_inputs() -> void:
	_is_locked = false
	_lock_timer = 0.0
	_locked_actions.clear()
	inputs_unlocked.emit()

## 设置默认锁定时长
func set_default_lock_duration(duration: float) -> void:
	_default_lock_duration = duration
#endregion

#region 公共 API - 输入查询
## 检查是否可以接收游戏输入（供游戏逻辑调用）
func can_receive_game_input() -> bool:
	if _is_locked:
		return false
	return GameManager.can_receive_game_input()

## 检查特定动作是否允许（考虑锁定和游戏状态）
func is_action_allowed(action_name: String) -> bool:
	# 输入锁定检查
	if _is_locked:
		# 如果是特定动作锁定，检查是否在锁定列表中
		if _locked_actions.is_empty():
			return false  # 全局锁定
		if action_name in _locked_actions:
			return false

	# 游戏状态检查
	return GameManager.can_receive_game_input()

## 安全的输入检查方法（替代 Input.is_action_pressed）
func is_action_pressed(action_name: String) -> bool:
	if not is_action_allowed(action_name):
		return false
	return Input.is_action_pressed(action_name)

## 安全的输入检查方法（替代 Input.is_action_just_pressed）
func is_action_just_pressed(action_name: String) -> bool:
	if not is_action_allowed(action_name):
		return false
	return Input.is_action_just_pressed(action_name)

## 安全的输入检查方法（替代 Input.is_action_just_released）
func is_action_just_released(action_name: String) -> bool:
	if not is_action_allowed(action_name):
		return false
	return Input.is_action_just_released(action_name)
#endregion

#region 公共 API - 强制释放
## 强制释放游戏相关输入动作（公共方法）
func force_release_game_actions() -> void:
	_force_release_game_actions()
#endregion

#region 内部方法
## 强制释放游戏相关输入动作
func _force_release_game_actions() -> void:
	Input.action_release("fire")
	Input.action_release("jump")
	Input.action_release("interaction")
	Input.action_release("left")
	Input.action_release("right")
#endregion

#region 预定义锁定配置
## 获取游戏动作列表（用于批量锁定）
func get_game_actions() -> Array[String]:
	return ["fire", "jump", "interaction", "left", "right", "test"]
#endregion