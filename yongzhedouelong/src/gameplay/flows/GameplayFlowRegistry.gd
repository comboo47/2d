extends Node
## Autoload: FlowRegistry
## GameplayFlow 资源注册表
## 管理 Flow 资源的加载、缓存和获取
## 支持脚本类型的 Flow（Scripts/Gameplay/Flows/ 目录）

## 单例实例（不使用类型声明，因为是 autoload）
static var instance

## 显式加载依赖类（避免 GDScript 方法冲突）
const GameplayFlowBaseClass = preload("res://src/gameplay/flows/GameplayFlowBase.gd")

## Flow 缓存字典 {flow_id: GameplayFlowBase}
## flow_id 可以是类名（如 "Flow_CrossBowFire"）或自定义 flow_id
var _flow_cache: Dictionary = {}

## 按事件类型分类 {FlowEvent: Array[GameplayFlowBase]}
var _flows_by_event: Dictionary = {}

## 初始化完成信号
signal flow_registry_initialized

func _init():
	instance = self

func _ready():
	# 初始化事件分类字典
	for event in GameplayFlowBaseClass.FlowEvent.values():
		_flows_by_event[event] = []

	# 扫描并注册所有 Flow
	_scan_and_register_flows()

	flow_registry_initialized.emit()

#region 公共 API - Flow 获取
## 根据 ID 获取 Flow（返回新实例）
## flow_id 可以是：
## - 类名（如 "Flow_CrossBowFire"）
## - 自定义 flow_id（如 "crossbow_fire_001"）
func get_flow(flow_id: String) -> GameplayFlowBase:
	# 1. 尝试从缓存获取（自定义 flow_id）
	if _flow_cache.has(flow_id):
		var flow_template = _flow_cache[flow_id]
		return flow_template.deep_duplicate()

	# 2. 尝试通过类名创建（脚本类）
	var flow_script = _get_flow_script_by_class_name(flow_id)
	if flow_script != null:
		var flow_instance = flow_script.new()
		# 设置 flow_id（如果未设置）
		if flow_instance.flow_id.is_empty():
			flow_instance.flow_id = flow_id
		return flow_instance

	push_warning("FlowRegistry: 未找到 Flow ID='%s'" % flow_id)
	return null

## 通过类名查找 Flow 脚本
func _get_flow_script_by_class_name(class_name_str: String) -> GDScript:
	# 使用 ScriptClassDB 查找脚本类
	var scripts = _get_all_flow_scripts()
	for script_path in scripts:
		var script = load(script_path)
		if script and script.get_global_name() == class_name_str:
			return script
	return null

## 获取所有 Flow 脚本路径
func _get_all_flow_scripts() -> Array[String]:
	var scripts: Array[String] = []
	var flow_dir = "res://src/gameplay/flows/legacy/"

	var dir = DirAccess.open(flow_dir)
	if dir == null:
		return scripts

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			scripts.append(flow_dir + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()
	return scripts

## 获取指定事件类型的所有 Flow
func get_flows_by_event(event: GameplayFlowBaseClass.FlowEvent) -> Array[GameplayFlowBase]:
	var result: Array[GameplayFlowBase] = []
	var templates = _flows_by_event.get(event, [])

	for template in templates:
		result.append(template.deep_duplicate())

	return result

## 检查 Flow 是否存在
func has_flow(flow_id: String) -> bool:
	# 检查缓存
	if _flow_cache.has(flow_id):
		return true

	# 检查脚本类
	return _get_flow_script_by_class_name(flow_id) != null

## 获取所有已注册的 Flow ID
func get_all_flow_ids() -> Array[String]:
	var ids: Array[String] = []

	# 缓存中的 ID
	for id in _flow_cache.keys():
		ids.append(id)

	# 脚本类名
	var scripts = _get_all_flow_scripts()
	for script_path in scripts:
		var script = load(script_path)
		if script:
			var class_name_str = script.get_global_name()
			if not class_name_str.is_empty():
				ids.append(class_name_str)

	return ids
#endregion

#region 公共 API - Flow 注册
## 注册 Flow（手动添加）
func register_flow(flow: GameplayFlowBase) -> void:
	if flow == null or flow.flow_id.is_empty():
		push_warning("FlowRegistry: 无法注册空 Flow 或无 ID 的 Flow")
		return

	_flow_cache[flow.flow_id] = flow
	_flows_by_event[flow.trigger_event].append(flow)

## 扫描并注册所有 Flow
## 包括脚本类（Scripts/Gameplay/Flows/）和资源文件（prefab/Flows/）
func _scan_and_register_flows() -> void:
	# 1. 扫描脚本类（仅创建模板实例用于事件分类）
	_scan_flow_scripts()

	# 2. 扫描资源文件（.tres）
	_scan_flow_resources()

## 扫描脚本类
func _scan_flow_scripts() -> void:
	var scripts = _get_all_flow_scripts()

	for script_path in scripts:
		var script = load(script_path)
		if script == null:
			continue

		# 创建实例以获取属性
		var flow_instance = script.new()
		if flow_instance is GameplayFlowBase:
			# 如果有自定义 flow_id，加入缓存
			if not flow_instance.flow_id.is_empty():
				_flow_cache[flow_instance.flow_id] = flow_instance

			# 按事件类型分类
			if flow_instance.trigger_event != GameplayFlowBaseClass.FlowEvent.NONE:
				_flows_by_event[flow_instance.trigger_event].append(flow_instance)

## 扫描资源文件
func _scan_flow_resources() -> void:
	var flow_dir = "res://resources/gameplay/flows/"

	var dir = DirAccess.open(flow_dir)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = flow_dir + file_name
			_load_and_register_flow(full_path)
		file_name = dir.get_next()

	dir.list_dir_end()

## 加载并注册单个 Flow 资源
func _load_and_register_flow(path: String) -> void:
	if not ResourceLoader.exists(path):
		return

	var resource = load(path)
	if resource is GameplayFlowBase:
		register_flow(resource)
	else:
		push_warning("FlowRegistry: %s 不是 GameplayFlowBase 类型" % path)
#endregion