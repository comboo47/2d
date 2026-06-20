extends Node
## Autoload: ActorRegistry
## 角色定义注册表。启动时扫描 res://resources/gameplay/actors/ 下的 .tres，
## 缓存 ActorDefinition 模板，按 actor_id 提供深拷贝实例。
## 结构对标 WeaponRegistry / BulletRegistry。

## 单例实例（autoload，不加类型声明）。
static var instance

const ActorDefinitionClass = preload("res://src/gameplay/actors/ActorDefinition.gd")

const SCAN_DIR := "res://resources/gameplay/actors/"

## 定义缓存 {actor_id(int): ActorDefinition}
var _cache: Dictionary = {}

signal actor_registry_initialized

func _init():
	instance = self

func _ready():
	_scan_and_register()
	actor_registry_initialized.emit()

#region 公共 API
## 按 ID 获取角色定义模板（返回深拷贝，避免污染共享 .tres）。
func get_definition(actor_id: int) -> ActorDefinition:
	if not _cache.has(actor_id):
		push_warning("ActorRegistry: 未找到 ActorDefinition ID=%d" % actor_id)
		return null
	return _cache[actor_id].duplicate(true)

## 是否存在指定 ID。
func has(actor_id: int) -> bool:
	return _cache.has(actor_id)

## 所有已注册 ID。
func get_all_ids() -> Array[int]:
	var ids: Array[int] = []
	for id in _cache.keys():
		ids.append(id)
	return ids

## 手动注册一个定义（按 actor_id 入缓存）。
func register(def: ActorDefinition) -> void:
	if def == null or def.actor_id <= 0:
		push_warning("ActorRegistry: 无法注册空定义或无效 ID 的定义")
		return
	_cache[def.actor_id] = def
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
	if resource is ActorDefinition:
		register(resource)
	else:
		push_warning("ActorRegistry: %s 不是 ActorDefinition 类型" % path)
#endregion
