extends Node
## Autoload: VfxManager
## 特效管理单例 - 统一管理所有游戏特效
## 支持预加载池化、按类型播放、自动回收

## 单例实例（不使用类型声明，因为是 autoload）
static var instance

## 显式加载 VfxConfig 类（避免与 GDScript.get_path() 冲突）
const VfxConfigClass = preload("res://Scripts/GameBase/BattleSystemBase/VfxSystem/VfxConfig.gd")

## 特效池字典 {VfxType: Array[Node]}
var _vfx_pools: Dictionary = {}

## 场景缓存 {VfxType: PackedScene}
var _scene_cache: Dictionary = {}

## 活动特效追踪
var _active_vfx: Array[Node] = []

## 回收队列
var _return_queue: Array[Dictionary] = []

## 初始化完成信号
signal vfx_initialized

func _init():
	instance = self

func _ready():
	_preload_vfx_scenes()
	_init_pools()
	# 设置为在暂停时也能处理（确保特效能正常播放）
	process_mode = Node.PROCESS_MODE_ALWAYS
	vfx_initialized.emit()

#region 公共 API - 特效播放
## 播放特效（指定类型和位置）
func play_vfx(vfx_type: VfxConfigClass.VfxType, position: Vector2, parent: Node = null) -> Node:
	var vfx = _get_from_pool(vfx_type)
	if vfx == null:
		vfx = _create_vfx_instance(vfx_type)

	if vfx == null:
		push_warning("VfxManager: 无法创建特效实例，类型=%s" % VfxConfigClass.get_type_name(vfx_type))
		return null

	# 设置位置和父节点
	vfx.global_position = position
	if parent:
		parent.add_child(vfx)
	else:
		# 默认添加到当前场景
		var tree = get_tree()
		if tree and tree.current_scene:
			tree.current_scene.add_child(vfx)
		else:
			add_child(vfx)

	# 记录活动特效
	_active_vfx.append(vfx)

	# 播放后自动回收
	var duration = VfxConfigClass.get_duration(vfx_type)
	_schedule_return(vfx_type, vfx, duration)

	return vfx

## 播放特效并跟随目标
func play_vfx_follow(vfx_type: VfxConfigClass.VfxType, target: Node2D, offset: Vector2 = Vector2.ZERO) -> Node:
	var vfx = play_vfx(vfx_type, target.global_position + offset, target)
	return vfx

## 立即停止并回收特效
func stop_vfx(vfx: Node) -> void:
	if vfx == null:
		return

	# 从活动列表移除
	if vfx in _active_vfx:
		_active_vfx.erase(vfx)

	# 回收
	_return_to_pool(vfx)
#endregion

#region 公共 API - 查询
## 检查特效类型是否可用
func is_vfx_available(vfx_type: VfxConfigClass.VfxType) -> bool:
	return VfxConfigClass.has_vfx_path(vfx_type)

## 获取活动特效数量
func get_active_count() -> int:
	return _active_vfx.size()
#endregion

#region 内部方法 - 池管理
## 预加载特效场景
func _preload_vfx_scenes() -> void:
	for vfx_type in VfxConfigClass.VfxType.values():
		var path = VfxConfigClass.get_vfx_scene_path(vfx_type)
		if path != "" and ResourceLoader.exists(path):
			_scene_cache[vfx_type] = load(path)

## 初始化特效池
func _init_pools() -> void:
	for vfx_type in VfxConfigClass.VfxType.values():
		var pool_size = VfxConfigClass.get_pool_size(vfx_type)
		var pool: Array[Node] = []
		_vfx_pools[vfx_type] = pool

		# 预创建实例（仅在场景存在时）
		if _scene_cache.has(vfx_type):
			for i in range(pool_size):
				var vfx = _create_vfx_instance(vfx_type)
				if vfx:
					pool.append(vfx)

## 从池获取特效
func _get_from_pool(vfx_type: VfxConfigClass.VfxType) -> Node:
	var pool = _vfx_pools.get(vfx_type, [])
	for vfx in pool:
		if vfx and not vfx.is_inside_tree():
			return vfx
	return null

## 创建特效实例
func _create_vfx_instance(vfx_type: VfxConfigClass.VfxType) -> Node:
	var scene = _scene_cache.get(vfx_type)
	if scene:
		return scene.instantiate()
	return null

## 安排回收
func _schedule_return(vfx_type: VfxConfigClass.VfxType, vfx: Node, delay: float) -> void:
	# 使用 Tween 或定时器实现延迟回收
	if delay <= 0.0:
		delay = VfxConfigClass.get_duration(vfx_type)

	# 创建定时器
	var timer = get_tree().create_timer(delay)
	timer.timeout.connect(_on_return_timer.bind(vfx_type, vfx))

## 定时器回调 - 回收特效
func _on_return_timer(vfx_type: VfxConfigClass.VfxType, vfx: Node) -> void:
	if vfx == null:
		return

	# 从活动列表移除
	if vfx in _active_vfx:
		_active_vfx.erase(vfx)

	# 回收到池
	_return_to_pool(vfx)

## 回收到池
func _return_to_pool(vfx: Node) -> void:
	if vfx == null:
		return

	# 如果还在场景树中，移除
	if vfx.is_inside_tree():
		vfx.get_parent().remove_child(vfx)

	# 重置状态（如果有 reset 方法）
	if vfx.has_method("reset"):
		vfx.reset()
#endregion

#region 内部方法 - 清理
## 清理所有活动特效（场景切换时调用）
func cleanup_all() -> void:
	for vfx in _active_vfx:
		if vfx and vfx.is_inside_tree():
			vfx.get_parent().remove_child(vfx)
	_active_vfx.clear()
#endregion
