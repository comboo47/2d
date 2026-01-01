class_name DataRegistry extends Node

# 单例实例
static var instance: DataRegistry

# 存储所有已注册的Buff资源
var _buff_resources: Dictionary = {}

func _init():
	instance = self

# 注册单个Buff资源
func register_buff(buff: AttributeBuff) -> void:
	if buff.buff_id.is_empty():
		push_error("Buff资源缺少ID: %s" % buff.resource_path)
		return
	
	if _buff_resources.has(buff.buff_id):
		push_warning("BuffID重复: %s" % buff.buff_id)
	
	_buff_resources[buff.buff_id] = buff


# 获取Buff资源
func get_buff(buff_id: String) -> AttributeBuff:
	if _buff_resources.has(buff_id):
		return _buff_resources[buff_id].duplicate()
	else:
		push_error("未找到BuffID: %s" % buff_id)
		return null

# 获取所有注册的Buff
func get_all_buffs() -> Array:
	return _buff_resources.values()

# 清空注册表（用于热重载）
func clear() -> void:
	_buff_resources.clear()
