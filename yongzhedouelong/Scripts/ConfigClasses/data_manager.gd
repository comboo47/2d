@tool
extends Node

# 自动生成的数据管理器

static var BuffInfo: Dictionary[String, TableClasses.Dt_BuffInfo] = {}

# 获取BuffInfo表中指定key的数据
static func get_BuffInfo(key) -> TableClasses.Dt_BuffInfo:
	var _key = str(key)
	if BuffInfo.has(_key):
		return BuffInfo[_key]
	return null

# 使用通用加载器加载所有数据
static func load_all_data() -> bool:
	return JsonLoader.load_all_json_data(ProjectSettings.get_setting("config_manager/json_export_path", "res://Configs/Json/"))

func _ready() -> void:
	load_all_data()
