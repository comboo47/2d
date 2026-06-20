class_name UIConfig

enum UILayerType {
	SCREEN,
	POPUP,
	OVERLAY,
	HUD,
	WIDGET,
}

enum SceneType {
	POP_DAMAGE,
	BATTLE_HUD,
	HP_BAR,
	ENERGY_BAR,
	MAIN_MENU,
	PAUSE_MENU,
	SETTINGS,
	LEVEL_SELECT,
	LOADING,
}

const MENU_MAIN := "MainMenu"
const MENU_PAUSE := "PauseMenu"
const MENU_SETTINGS := "Settings"
const MENU_LEVEL_SELECT := "LevelSelect"
const MENU_LEVEL_RESULT := "LevelResult"
const MENU_LOADING := "Loading"

const HUD_BATTLE := "BattleHUD"
const OVERLAY_LOADING := MENU_LOADING
const WIDGET_POP_DAMAGE := "PopDamage"

const KEY_PATH := "path"
const KEY_LAYER := "layer"
const KEY_CACHE := "cache"
const KEY_EXCLUSIVE := "exclusive"

const WINDOWS := {
	WIDGET_POP_DAMAGE: {
		KEY_PATH: "res://scenes/ui/damage_number/PopDamage.tscn",
		KEY_LAYER: UILayerType.WIDGET,
		KEY_CACHE: true,
		KEY_EXCLUSIVE: false,
	},
	HUD_BATTLE: {
		KEY_PATH: "res://scenes/ui/hud/BattleHUD.tscn",
		KEY_LAYER: UILayerType.HUD,
		KEY_CACHE: true,
		KEY_EXCLUSIVE: true,
	},
	MENU_MAIN: {
		KEY_PATH: "res://scenes/ui/menu/MainMenu.tscn",
		KEY_LAYER: UILayerType.SCREEN,
		KEY_CACHE: true,
		KEY_EXCLUSIVE: true,
	},
	MENU_PAUSE: {
		KEY_PATH: "res://scenes/ui/menu/PauseMenu.tscn",
		KEY_LAYER: UILayerType.SCREEN,
		KEY_CACHE: true,
		KEY_EXCLUSIVE: true,
	},
	MENU_SETTINGS: {
		KEY_PATH: "res://scenes/ui/menu/Settings.tscn",
		KEY_LAYER: UILayerType.SCREEN,
		KEY_CACHE: true,
		KEY_EXCLUSIVE: true,
	},
	MENU_LEVEL_SELECT: {
		KEY_PATH: "res://scenes/ui/menu/LevelSelect.tscn",
		KEY_LAYER: UILayerType.SCREEN,
		KEY_CACHE: true,
		KEY_EXCLUSIVE: true,
	},
	MENU_LEVEL_RESULT: {
		KEY_PATH: "res://scenes/ui/menu/LevelResult.tscn",
		KEY_LAYER: UILayerType.SCREEN,
		KEY_CACHE: true,
		KEY_EXCLUSIVE: true,
	},
	OVERLAY_LOADING: {
		KEY_PATH: "res://scenes/ui/menu/Loading.tscn",
		KEY_LAYER: UILayerType.OVERLAY,
		KEY_CACHE: true,
		KEY_EXCLUSIVE: false,
	},
}

const SCENE_TYPE_TO_ID := {
	SceneType.POP_DAMAGE: WIDGET_POP_DAMAGE,
	SceneType.BATTLE_HUD: HUD_BATTLE,
	SceneType.MAIN_MENU: MENU_MAIN,
	SceneType.PAUSE_MENU: MENU_PAUSE,
	SceneType.SETTINGS: MENU_SETTINGS,
	SceneType.LEVEL_SELECT: MENU_LEVEL_SELECT,
	SceneType.LOADING: OVERLAY_LOADING,
}

const SCENE_PATHS := {
	SceneType.POP_DAMAGE: "res://scenes/ui/damage_number/PopDamage.tscn",
	SceneType.BATTLE_HUD: "res://scenes/ui/hud/BattleHUD.tscn",
	SceneType.HP_BAR: "res://scenes/ui/hud/HPBar.tscn",
	SceneType.ENERGY_BAR: "res://scenes/ui/hud/EnergyBar.tscn",
	SceneType.MAIN_MENU: "res://scenes/ui/menu/MainMenu.tscn",
	SceneType.PAUSE_MENU: "res://scenes/ui/menu/PauseMenu.tscn",
	SceneType.SETTINGS: "res://scenes/ui/menu/Settings.tscn",
	SceneType.LEVEL_SELECT: "res://scenes/ui/menu/LevelSelect.tscn",
	SceneType.LOADING: "res://scenes/ui/menu/Loading.tscn",
}

static var _scene_cache: Dictionary = {}

static func has_window(id: String) -> bool:
	return WINDOWS.has(id)

static func get_window_config(id: String) -> Dictionary:
	return WINDOWS.get(id, {})

static func get_window_path(id: String) -> String:
	var config: Dictionary = get_window_config(id)
	return str(config.get(KEY_PATH, ""))

static func get_window_layer(id: String):
	var config: Dictionary = get_window_config(id)
	return int(config.get(KEY_LAYER, UILayerType.SCREEN))

static func should_cache(id: String) -> bool:
	var config: Dictionary = get_window_config(id)
	return bool(config.get(KEY_CACHE, false))

static func is_exclusive(id: String) -> bool:
	var config: Dictionary = get_window_config(id)
	return bool(config.get(KEY_EXCLUSIVE, true))

static func get_scene_by_id(id: String) -> PackedScene:
	if not has_window(id):
		push_error("UIConfig: window is not registered: %s" % id)
		return null

	if should_cache(id) and _scene_cache.has(id):
		return _scene_cache[id] as PackedScene

	var path: String = get_window_path(id)
	if path == "":
		push_error("UIConfig: scene path is empty: %s" % id)
		return null

	var scene := load(path) as PackedScene
	if scene == null:
		push_error("UIConfig: failed to load scene: %s" % path)
		return null

	if should_cache(id):
		_scene_cache[id] = scene
	return scene

static func get_scene(type: SceneType) -> PackedScene:
	var id: String = str(SCENE_TYPE_TO_ID.get(type, ""))
	if id != "":
		return get_scene_by_id(id)

	var path: String = SCENE_PATHS.get(type, "")
	if path == "":
		push_error("UIConfig: scene path is not configured. type=%d" % type)
		return null

	var scene := load(path) as PackedScene
	if scene == null:
		push_error("UIConfig: failed to load scene: %s" % path)
	return scene

static func get_menu_scene_path(menu_name: String) -> String:
	return get_window_path(menu_name)

static func preload_all() -> void:
	for id in WINDOWS.keys():
		var path: String = get_window_path(str(id))
		if path != "" and ResourceLoader.exists(path):
			get_scene_by_id(str(id))

static func clear_cache() -> void:
	_scene_cache.clear()
