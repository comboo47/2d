class_name EnemyConfigLoader extends RefCounted
## 敌人配置加载器
## 从 JSON 文件加载敌人配置和掉落配置

## 配置文件路径
const ENEMY_CONFIG_PATH := "res://data/tables/Json/Enemy/EnemyConfig.json"
const DROP_CONFIG_PATH := "res://data/tables/Json/Enemy/DropConfig.json"

## 配置缓存
var _enemy_configs: Dictionary = {}
var _drop_configs: Dictionary = {}
var _global_drop_config: Dictionary = {}

## 是否已加载
var _loaded: bool = false

## 加载所有配置
func load_configs() -> bool:
	_enemy_configs = _load_json_file(ENEMY_CONFIG_PATH)
	_drop_configs = _load_json_file(DROP_CONFIG_PATH)

	# 提取全局掉落配置
	if _drop_configs.has("global_config"):
		_global_drop_config = _drop_configs["global_config"]
		_drop_configs.erase("global_config")

	_loaded = not _enemy_configs.is_empty() or not _drop_configs.is_empty()

	if not _loaded:
		push_warning("EnemyConfigLoader: 配置加载失败")

	return _loaded

## 加载 JSON 文件
func _load_json_file(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		push_warning("EnemyConfigLoader: 配置文件不存在 %s" % path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("EnemyConfigLoader: 无法打开文件 %s" % path)
		return {}

	var text = file.get_as_text()
	file.close()

	var result = JSON.parse_string(text)
	if result == null:
		push_warning("EnemyConfigLoader: JSON 解析失败 %s" % path)
		return {}

	return result as Dictionary

#region 公共 API - 敌人配置
## 获取敌人配置
func get_enemy_config(enemy_id: int) -> Dictionary:
	var id_str = str(enemy_id)
	if not _enemy_configs.has(id_str):
		push_warning("EnemyConfigLoader: 未找到敌人配置 ID=%d" % enemy_id)
		return {}
	return _enemy_configs[id_str]

## 获取敌人属性配置
func get_enemy_attributes(enemy_id: int) -> Dictionary:
	var config = get_enemy_config(enemy_id)
	return config.get("attributes", {})

## 获取敌人预制体路径
func get_enemy_prefab_path(enemy_id: int) -> String:
	var config = get_enemy_config(enemy_id)
	return config.get("prefab_path", "")

## 获取敌人 BehaviorTree 路径
func get_enemy_behavior_tree(enemy_id: int) -> String:
	var config = get_enemy_config(enemy_id)
	return config.get("behavior_tree", "")

## 获取敌人掉落表 ID
func get_enemy_drop_table_id(enemy_id: int) -> String:
	var config = get_enemy_config(enemy_id)
	return config.get("drop_table_id", "")

## 获取敌人生成 Flow ID
func get_enemy_spawn_flow_id(enemy_id: int) -> String:
	var config = get_enemy_config(enemy_id)
	return config.get("spawn_flow_id", "")

## 获取敌人死亡 Flow ID
func get_enemy_death_flow_id(enemy_id: int) -> String:
	var config = get_enemy_config(enemy_id)
	return config.get("death_flow_id", "")

## 获取所有敌人 ID 列表
func get_all_enemy_ids() -> Array[int]:
	var ids: Array[int] = []
	for id_str in _enemy_configs.keys():
		ids.append(int(id_str))
	return ids

## 检查敌人配置是否存在
func has_enemy_config(enemy_id: int) -> bool:
	return _enemy_configs.has(str(enemy_id))
#endregion

#region 公共 API - 掉落配置
## 获取掉落配置
func get_drop_config(drop_table_id: String) -> Dictionary:
	if not _drop_configs.has(drop_table_id):
		push_warning("EnemyConfigLoader: 未找到掉落配置 ID=%s" % drop_table_id)
		return {}
	return _drop_configs[drop_table_id]

## 获取掉落列表
func get_drop_entries(drop_table_id: String) -> Array:
	var config = get_drop_config(drop_table_id)
	return config.get("drops", [])

## 获取保底掉落
func get_guaranteed_drop(drop_table_id: String) -> Dictionary:
	var config = get_drop_config(drop_table_id)
	return config.get("guaranteed_drop", {})

## 获取最大掉落数量
func get_max_drops(drop_table_id: String) -> int:
	var config = get_drop_config(drop_table_id)
	var max_drops = config.get("max_drops", -1)
	if max_drops < 0:
		max_drops = _global_drop_config.get("default_max_drops", 3)
	return max_drops

## 获取全局掉落配置
func get_global_drop_config() -> Dictionary:
	return _global_drop_config
#endregion

#region 公共 API - 状态查询
## 是否已加载
func is_loaded() -> bool:
	return _loaded

## 重新加载配置
func reload() -> bool:
	return load_configs()
#endregion