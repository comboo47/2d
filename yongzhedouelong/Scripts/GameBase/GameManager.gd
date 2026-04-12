extends Node
## Autoload: GameManager
## 游戏状态管理器 - 管理游戏生命周期和状态切换

## 游戏状态枚举
enum GameState {
	NONE,           # 启动前/未初始化
	MAIN_MENU,      # 主菜单
	LOADING,        # 加载场景中
	PLAYING,        # 游戏进行中
	PAUSED,         # 游戏暂停
	CUTSCENE,       # 过场动画（可选）
}

## 当前状态
var current_state: GameState = GameState.NONE
var previous_state: GameState = GameState.NONE

## 信号
signal state_changed(from: GameState, to: GameState)
signal game_started()
signal game_paused()
signal game_resumed()
signal game_quit()

## 配置
const MAIN_MENU_SCENE := "res://art/UIResource/UI/Menu/MainMenu.tscn"
const DEFAULT_GAME_SCENE := "res://Scene/TestScene.tscn"

## 当前游戏场景路径（用于重启）
var _current_game_scene: String = DEFAULT_GAME_SCENE

func _ready() -> void:
	# 设置为在暂停时也能处理
	process_mode = Node.PROCESS_MODE_ALWAYS

#region 公共 API - 状态管理
## 切换游戏状态
func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	previous_state = current_state
	current_state = new_state

	_apply_state(new_state)
	state_changed.emit(previous_state, current_state)

## 应用状态效果
func _apply_state(state: GameState) -> void:
	match state:
		GameState.MAIN_MENU:
			get_tree().paused = true
			UIManager.instance.show_main_menu()
		GameState.PLAYING:
			get_tree().paused = false
			UIManager.instance.hide_all_menus()
		GameState.PAUSED:
			get_tree().paused = true
			UIManager.instance.show_pause_menu()
		GameState.LOADING:
			# 加载状态可以显示加载界面
			pass
#endregion

#region 公共 API - 游戏流程
## 启动游戏（从主菜单进入）
func start_game(scene_path: String = DEFAULT_GAME_SCENE) -> void:
	_current_game_scene = scene_path
	change_state(GameState.LOADING)
	get_tree().change_scene_to_file(scene_path)
	# 状态会在新场景的 _ready 中切换为 PLAYING

## 进入游戏场景后调用（由场景初始化）
func enter_game() -> void:
	change_state(GameState.PLAYING)
	game_started.emit()

## 切换暂停
func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		game_paused.emit()
	elif current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		game_resumed.emit()

## 返回主菜单
func return_to_main_menu() -> void:
	change_state(GameState.LOADING)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	change_state(GameState.MAIN_MENU)

## 退出游戏
func quit_game() -> void:
	game_quit.emit()
	get_tree().quit()

## 重启当前游戏
func restart_game() -> void:
	change_state(GameState.LOADING)
	get_tree().change_scene_to_file(_current_game_scene)
	change_state(GameState.PLAYING)
#endregion

#region 公共 API - 状态查询
## 是否在游戏中（包括暂停）
func is_in_game() -> bool:
	return current_state == GameState.PLAYING or current_state == GameState.PAUSED

## 是否暂停
func is_paused() -> bool:
	return current_state == GameState.PAUSED

## 是否可以接收游戏输入
func can_receive_game_input() -> bool:
	return current_state == GameState.PLAYING

## 获取当前状态名称（调试用）
func get_state_name() -> String:
	match current_state:
		GameState.NONE: return "NONE"
		GameState.MAIN_MENU: return "MAIN_MENU"
		GameState.LOADING: return "LOADING"
		GameState.PLAYING: return "PLAYING"
		GameState.PAUSED: return "PAUSED"
		GameState.CUTSCENE: return "CUTSCENE"
		_: return "UNKNOWN"
#endregion