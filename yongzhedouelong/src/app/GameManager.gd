extends Node

enum GameState {
	NONE,
	MAIN_MENU,
	LOADING,
	PLAYING,
	PAUSED,
	CUTSCENE,
}

signal state_changed(from: GameState, to: GameState)
signal game_started()
signal game_paused()
signal game_resumed()
signal game_quit()

const MAIN_MENU_SCENE := "res://scenes/ui/menu/MainMenu.tscn"
const DEFAULT_GAME_SCENE := "res://scenes/app/TestScene.tscn"
## 战斗场景底板（关卡内容由 LevelDefinition 经 LevelRunner 动态生成）。
const BATTLE_SCENE := "res://scenes/app/TestScene.tscn"
const MIN_LOADING_TIME := 0.45

var current_state: GameState = GameState.NONE
var previous_state: GameState = GameState.NONE
var _current_game_scene: String = DEFAULT_GAME_SCENE
## 待加载关卡 id：选关时设置，战斗场景 Main._ready 取出 → 加载对应 LevelDefinition。
var pending_level_id: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	previous_state = current_state
	current_state = new_state
	_apply_state(new_state)
	state_changed.emit(previous_state, current_state)

func _apply_state(state: GameState) -> void:
	match state:
		GameState.MAIN_MENU:
			get_tree().paused = true
			if UIManager.instance:
				UIManager.instance.hide_loading()
				UIManager.instance.show_main_menu()
		GameState.PLAYING:
			get_tree().paused = false
			if UIManager.instance:
				UIManager.instance.hide_loading()
				UIManager.instance.hide_all_menus()
		GameState.PAUSED:
			get_tree().paused = true
			if UIManager.instance:
				UIManager.instance.show_pause_menu()
		GameState.LOADING:
			get_tree().paused = false
			if UIManager.instance:
				UIManager.instance.show_loading("Loading", "Preparing scene...")
				UIManager.instance.set_loading_progress(0.15)

func start_game(scene_path: String = DEFAULT_GAME_SCENE) -> void:
	InputManager.lock_inputs(0.3)
	_current_game_scene = scene_path
	change_state(GameState.LOADING)
	await _change_scene_with_loading(scene_path)

## 按 level_id 进入战斗：暂存 level_id，切到战斗底板场景，由 Main._ready 取出加载关卡。
func start_level(level_id: String) -> void:
	pending_level_id = level_id
	InputManager.lock_inputs(0.3)
	_current_game_scene = BATTLE_SCENE
	change_state(GameState.LOADING)
	await _change_scene_with_loading(BATTLE_SCENE)

## 关卡结束后返回选关界面：切回主菜单场景并推出关卡选择屏（重读解锁状态）。
func return_to_level_select() -> void:
	InputManager.lock_inputs(0.3)
	if UIManager.instance:
		UIManager.instance.hide_hud()
	change_state(GameState.LOADING)
	await _change_scene_with_loading(MAIN_MENU_SCENE)
	change_state(GameState.MAIN_MENU)
	if UIManager.instance:
		UIManager.instance.push_screen(UIConfig.MENU_LEVEL_SELECT)

func enter_game() -> void:
	InputManager.lock_inputs(0.2)
	change_state(GameState.PLAYING)
	game_started.emit()

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		InputManager.lock_inputs(0.2)
		change_state(GameState.PAUSED)
		game_paused.emit()

func return_to_main_menu() -> void:
	InputManager.lock_inputs(0.3)
	if UIManager.instance:
		UIManager.instance.hide_hud()
	change_state(GameState.LOADING)
	await _change_scene_with_loading(MAIN_MENU_SCENE)
	change_state(GameState.MAIN_MENU)

func quit_game() -> void:
	game_quit.emit()
	get_tree().quit()

func restart_game() -> void:
	InputManager.lock_inputs(0.3)
	change_state(GameState.LOADING)
	await _change_scene_with_loading(_current_game_scene)

func is_in_game() -> bool:
	return current_state == GameState.PLAYING or current_state == GameState.PAUSED

func is_paused() -> bool:
	return current_state == GameState.PAUSED

func can_receive_game_input() -> bool:
	return current_state == GameState.PLAYING

func get_state_name() -> String:
	match current_state:
		GameState.NONE: return "NONE"
		GameState.MAIN_MENU: return "MAIN_MENU"
		GameState.LOADING: return "LOADING"
		GameState.PLAYING: return "PLAYING"
		GameState.PAUSED: return "PAUSED"
		GameState.CUTSCENE: return "CUTSCENE"
		_: return "UNKNOWN"

func _change_scene_with_loading(scene_path: String) -> void:
	if UIManager.instance:
		UIManager.instance.set_loading_progress(0.45)

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Failed to change scene: %s" % scene_path)
		if UIManager.instance:
			UIManager.instance.hide_loading()
		return

	if UIManager.instance:
		UIManager.instance.set_loading_progress(0.8)
	await get_tree().create_timer(MIN_LOADING_TIME).timeout
	if UIManager.instance:
		UIManager.instance.set_loading_progress(1.0)
