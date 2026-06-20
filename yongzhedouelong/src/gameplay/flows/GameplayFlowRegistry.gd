extends Node
## Autoload: FlowRegistry
## FlowGraph 资源注册表（第十三期：从 GameplayFlowBase 改为 FlowGraph 节点树）。
## 扫描 res://resources/gameplay/flows/*.tres，按 flow_id 缓存模板，get_flow 返回 deep_duplicate 副本。

## 单例实例（不使用类型声明，因为是 autoload）
static var instance

## Flow 缓存字典 {flow_id: FlowGraph}
var _flow_cache: Dictionary = {}

## 初始化完成信号
signal flow_registry_initialized

func _init():
	instance = self

func _ready():
	_scan_flow_resources()
	flow_registry_initialized.emit()

#region 公共 API - Flow 获取
## 根据 flow_id 获取 FlowGraph（返回深拷贝副本）。
func get_flow(flow_id: String) -> FlowGraph:
	if _flow_cache.has(flow_id):
		var template: FlowGraph = _flow_cache[flow_id]
		return template.deep_duplicate()
	push_warning("FlowRegistry: 未找到 Flow ID='%s'" % flow_id)
	return null

## 检查 Flow 是否存在
func has_flow(flow_id: String) -> bool:
	return _flow_cache.has(flow_id)

## 获取所有已注册的 flow_id
func get_all_flow_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _flow_cache.keys():
		ids.append(id)
	return ids
#endregion

#region 公共 API - Flow 注册
## 注册 Flow 模板（手动添加）
func register_flow(flow: FlowGraph) -> void:
	if flow == null or flow.flow_id.is_empty():
		push_warning("FlowRegistry: 无法注册空 Flow 或无 flow_id 的 Flow")
		return
	_flow_cache[flow.flow_id] = flow

## 扫描 res://resources/gameplay/flows/ 下的 FlowGraph .tres
func _scan_flow_resources() -> void:
	var flow_dir = "res://resources/gameplay/flows/"
	var dir = DirAccess.open(flow_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			_load_and_register_flow(flow_dir + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func _load_and_register_flow(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var resource = load(path)
	if resource is FlowGraph:
		register_flow(resource)
	else:
		push_warning("FlowRegistry: %s 不是 FlowGraph 类型" % path)
#endregion
