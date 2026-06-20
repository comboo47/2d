extends Node
## Autoload: TraitRegistry
## 特质定义注册表。启动时扫描 res://resources/gameplay/traits/ 下的 .tres，
## 缓存 TraitDefinition 模板，按 trait_id 提供深拷贝实例。
## 各系统（子弹/角色/武器/技能）按 trait_id 引用同一批特质。
## 结构对标 BulletRegistry。

## 单例实例（autoload，不加类型声明）。
static var instance

const TraitDefinitionClass = preload("res://src/gameplay/traits/TraitDefinition.gd")

const SCAN_DIR := "res://resources/gameplay/traits/"

## 定义缓存 {trait_id: TraitDefinition}
var _cache: Dictionary = {}

signal trait_registry_initialized

func _init():
	instance = self

func _ready():
	_scan_and_register()
	trait_registry_initialized.emit()

#region 公共 API
## 按 ID 获取特质定义模板（返回深拷贝，避免污染共享 .tres）。
func get_trait(trait_id: String) -> TraitDefinition:
	if not _cache.has(trait_id):
		push_warning("TraitRegistry: 未找到 TraitDefinition ID='%s'" % trait_id)
		return null
	return _cache[trait_id].duplicate(true)

## 是否存在指定 ID。
func has(trait_id: String) -> bool:
	return _cache.has(trait_id)

## 所有已注册 ID。
func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _cache.keys():
		ids.append(id)
	return ids

## 手动注册一个定义（按 trait_id 入缓存）。
func register(def: TraitDefinition) -> void:
	if def == null or def.trait_id.is_empty():
		push_warning("TraitRegistry: 无法注册空定义或无 ID 的定义")
		return
	_cache[def.trait_id] = def
#endregion

#region 内部
func _scan_and_register() -> void:
	var dir = DirAccess.open(SCAN_DIR)
	if dir == null:
		# 目录尚未创建时静默跳过。
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
	if resource is TraitDefinition:
		register(resource)
	else:
		push_warning("TraitRegistry: %s 不是 TraitDefinition 类型" % path)
#endregion
