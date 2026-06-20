extends Node
## Autoload: LevelRegistry
## 关卡定义注册表。启动时扫描 res://resources/gameplay/levels/ 下的 .tres，
## 缓存 LevelDefinition 模板，按 level_id 提供深拷贝实例 + 枚举全部关卡（供选关界面）。
## 结构对标 BulletRegistry。

## 单例实例（autoload，不加类型声明）。
static var instance

const LevelDefinitionClass = preload("res://src/gameplay/levels/LevelDefinition.gd")

const SCAN_DIR := "res://resources/gameplay/levels/"

## 定义缓存 {level_id: LevelDefinition}
var _cache: Dictionary = {}

signal level_registry_initialized

func _init():
	instance = self

func _ready():
	_scan_and_register()
	level_registry_initialized.emit()

#region 公共 API
## 按 level_id 获取关卡定义模板（深拷贝，避免污染共享 .tres）。
func get_definition(level_id: String) -> LevelDefinition:
	if not _cache.has(level_id):
		push_warning("LevelRegistry: 未找到 LevelDefinition ID='%s'" % level_id)
		return null
	return _cache[level_id].duplicate(true)

func has(level_id: String) -> bool:
	return _cache.has(level_id)

## 所有已注册 level_id。
func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _cache.keys():
		ids.append(id)
	return ids

## 选关界面用的关卡列表（仅 show_in_select=true，按 level_order 升序）。返回缓存模板引用，仅只读展示。
func get_all_definitions() -> Array:
	var defs: Array = []
	for d in _cache.values():
		if d.show_in_select:
			defs.append(d)
	defs.sort_custom(func(a, b): return a.level_order < b.level_order)
	return defs

func register(def: LevelDefinition) -> void:
	if def == null or def.level_id.is_empty():
		push_warning("LevelRegistry: 无法注册空定义或无 level_id 的定义")
		return
	_cache[def.level_id] = def
#endregion

#region 内部
func _scan_and_register() -> void:
	var dir = DirAccess.open(SCAN_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			_load_and_register(SCAN_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func _load_and_register(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var resource = load(path)
	if resource is LevelDefinition:
		register(resource)
	else:
		push_warning("LevelRegistry: %s 不是 LevelDefinition 类型" % path)
#endregion
