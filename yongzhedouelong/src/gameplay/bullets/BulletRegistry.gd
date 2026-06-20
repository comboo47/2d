extends Node
## Autoload: BulletRegistry
## 子弹定义注册表。启动时扫描 res://resources/gameplay/bullets/ 下的 .tres，
## 缓存 BulletDefinition 模板，按 bullet_id 提供深拷贝实例。
## 结构对标 SkillRegistry。

## 单例实例（autoload，不加类型声明）。
static var instance

const BulletDefinitionClass = preload("res://src/gameplay/bullets/BulletDefinition.gd")

const SCAN_DIR := "res://resources/gameplay/bullets/"

## 定义缓存 {bullet_id: BulletDefinition}
var _cache: Dictionary = {}

signal bullet_registry_initialized

func _init():
	instance = self

func _ready():
	_scan_and_register()
	bullet_registry_initialized.emit()

#region 公共 API
## 按 ID 获取子弹定义模板（返回深拷贝，避免污染共享 .tres）。
func get_definition(bullet_id: String) -> BulletDefinition:
	if not _cache.has(bullet_id):
		push_warning("BulletRegistry: 未找到 BulletDefinition ID='%s'" % bullet_id)
		return null
	return _cache[bullet_id].duplicate(true)

## 是否存在指定 ID。
func has(bullet_id: String) -> bool:
	return _cache.has(bullet_id)

## 所有已注册 ID。
func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _cache.keys():
		ids.append(id)
	return ids

## 手动注册一个定义（按 bullet_id 入缓存）。
func register(def: BulletDefinition) -> void:
	if def == null or def.bullet_id.is_empty():
		push_warning("BulletRegistry: 无法注册空定义或无 ID 的定义")
		return
	_cache[def.bullet_id] = def
#endregion

#region 内部
func _scan_and_register() -> void:
	var dir = DirAccess.open(SCAN_DIR)
	if dir == null:
		# 目录尚未创建时静默跳过（首次接入时正常）。
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
	if resource is BulletDefinition:
		register(resource)
	else:
		push_warning("BulletRegistry: %s 不是 BulletDefinition 类型" % path)
#endregion
