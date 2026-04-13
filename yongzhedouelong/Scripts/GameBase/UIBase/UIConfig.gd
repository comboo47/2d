class_name UIConfig

## UI 场景类型枚举
enum SceneType {
	POP_DAMAGE,
	BATTLE_HUD,
	HP_BAR,
	ENERGY_BAR,
	MAIN_MENU,
	PAUSE_MENU,
	SETTINGS
}

## 菜单名称常量
const MENU_MAIN := "MainMenu"
const MENU_PAUSE := "PauseMenu"
const MENU_SETTINGS := "Settings"

## 场景路径配置
## 注意：优先使用 UID，若没有则使用相对路径
const SCENE_PATHS := {
	SceneType.POP_DAMAGE: "res://art/UIResource/UI/DamageNumber/PopDamage.tscn",
	SceneType.BATTLE_HUD: "res://art/UIResource/UI/HUD/BattleHUD.tscn",
	SceneType.HP_BAR: "res://art/UIResource/UI/HUD/HPBar.tscn",
	SceneType.ENERGY_BAR: "res://art/UIResource/UI/HUD/EnergyBar.tscn",
	SceneType.MAIN_MENU: "res://art/UIResource/UI/Menu/MainMenu.tscn",
	SceneType.PAUSE_MENU: "res://art/UIResource/UI/Menu/PauseMenu.tscn",
	SceneType.SETTINGS: "res://art/UIResource/UI/Menu/Settings.tscn"
}

## 场景缓存（避免重复加载）
static var _scene_cache: Dictionary = {}

## 获取场景
static func get_scene(type: SceneType) -> PackedScene:
	if not _scene_cache.has(type):
		var path = SCENE_PATHS.get(type, "")
		if path == "":
			push_error("UIConfig: 未配置场景路径 type=%d" % type)
			return null
		var scene = load(path)
		if scene == null:
			push_error("UIConfig: 无法加载场景 %s" % path)
			return null
		_scene_cache[type] = scene
	return _scene_cache[type]

## 获取菜单场景路径
static func get_menu_scene_path(menu_name: String) -> String:
	match menu_name:
		MENU_MAIN: return SCENE_PATHS[SceneType.MAIN_MENU]
		MENU_PAUSE: return SCENE_PATHS[SceneType.PAUSE_MENU]
		MENU_SETTINGS: return SCENE_PATHS[SceneType.SETTINGS]
		_: return ""

## 预加载所有 UI 场景（可选，用于减少运行时加载延迟）
static func preload_all() -> void:
	for type in SceneType.values():
		var path = SCENE_PATHS.get(type, "")
		if path != "" and ResourceLoader.exists(path):
			get_scene(type)

## 清空缓存（用于热重载）
static func clear_cache() -> void:
	_scene_cache.clear()