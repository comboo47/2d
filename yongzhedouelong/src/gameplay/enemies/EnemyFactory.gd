extends Node
## Autoload: EnemyFactory
## 敌人工厂 - 根据 EnemyConfig.json 动态创建敌人实例
## 用法: EnemyFactory.instance.spawn_enemy(enemy_id, position) 或 EnemyFactory.spawn_enemy(enemy_id, position)
## 单例实例（不使用类型声明，因为是 autoload）
static var instance

## 配置加载器
var _config_loader: EnemyConfigLoader

## 预制体缓存 {path: PackedScene}
var _prefab_cache: Dictionary = {}

## BehaviorTree 缓存 {path: BehaviorTree}
var _bt_cache: Dictionary = {}

## 初始化完成信号
signal factory_initialized

func _init():
	instance = self

func _ready():
	_config_loader = EnemyConfigLoader.new()
	_config_loader.load_configs()

	# 预加载常用预制体
	_preload_prefabs()

	factory_initialized.emit()

#region 公共 API - 敌人创建
## 创建敌人（根据 ID 和位置）
func create_enemy(enemy_id: int, position: Vector2) -> BattleActor:
	return create_enemy_from_spawn_data(EnemySpawnData.new().from_dict({
		"enemy_id": enemy_id,
		"position": {"x": position.x, "y": position.y}
	}))

## 创建敌人（根据生成数据）
func create_enemy_from_spawn_data(spawn_data: EnemySpawnData) -> BattleActor:
	var enemy_id = spawn_data.enemy_id

	# 获取配置
	var config = _config_loader.get_enemy_config(enemy_id)
	if config.is_empty():
		push_error("EnemyFactory: 无法创建敌人 ID=%d，配置不存在" % enemy_id)
		return null

	# 获取预制体
	var prefab_path = config.get("prefab_path", "")
	var prefab = _get_prefab(prefab_path)
	if prefab == null:
		push_error("EnemyFactory: 无法加载预制体 %s" % prefab_path)
		return null

	# 实例化
	var enemy = prefab.instantiate() as BattleActor
	if enemy == null:
		push_error("EnemyFactory: 预制体不是 BattleActor 类型")
		return null

	# 设置位置
	enemy.global_position = spawn_data.spawn_position

	# 应用属性配置
	_apply_attributes(enemy, config.get("attributes", {}), spawn_data.attribute_overrides)

	# 应用 BehaviorTree
	_apply_behavior_tree(enemy, config.get("behavior_tree", ""), spawn_data.behavior_tree_override)

	# 设置敌人 ID（如果敌人有这个属性）
	if enemy.has_method("set_enemy_id"):
		enemy.set_enemy_id(enemy_id)
	elif enemy.get("EnemyID") != null:
		enemy.set("EnemyID", enemy_id)

	# 设置掉落表（如果敌人有这个属性）
	var drop_table_id = spawn_data.drop_table_override
	if drop_table_id.is_empty():
		drop_table_id = config.get("drop_table_id", "")
	if enemy.get("drop_table_id") != null:
		enemy.set("drop_table_id", drop_table_id)

	# 触发生成 Flow（第十三期：FlowRegistry 返回 FlowGraph，经解释器一次性跑完）
	var spawn_flow_id = config.get("spawn_flow_id", "")
	if not spawn_flow_id.is_empty() and FlowRegistry.instance:
		var flow = FlowRegistry.instance.get_flow(spawn_flow_id)
		if flow:
			var context = GameplayFlowContext.create_simple(enemy)
			FlowInterpreter.run_oneshot(flow, context, enemy)

	return enemy

## 创建并添加敌人到场景
func spawn_enemy(enemy_id: int, position: Vector2, parent: Node = null) -> BattleActor:
	var enemy = create_enemy(enemy_id, position)
	if enemy == null:
		return null

	if parent:
		parent.add_child(enemy)
	else:
		var tree = get_tree()
		if tree and tree.current_scene:
			tree.current_scene.add_child(enemy)

	return enemy

## 创建并添加敌人（根据生成数据）
func spawn_enemy_from_data(spawn_data: EnemySpawnData, parent: Node = null) -> BattleActor:
	var enemy = create_enemy_from_spawn_data(spawn_data)
	if enemy == null:
		return null

	if parent:
		parent.add_child(enemy)
	else:
		var tree = get_tree()
		if tree and tree.current_scene:
			tree.current_scene.add_child(enemy)

	return enemy
#endregion

#region 公共 API - 配置查询
## 获取配置加载器
func get_config_loader() -> EnemyConfigLoader:
	return _config_loader

## 检查敌人是否可创建
func can_create_enemy(enemy_id: int) -> bool:
	if not _config_loader.has_enemy_config(enemy_id):
		return false

	var prefab_path = _config_loader.get_enemy_prefab_path(enemy_id)
	return prefab_path != "" and ResourceLoader.exists(prefab_path)

## 重新加载配置
func reload_configs() -> void:
	_config_loader.reload()
	_prefab_cache.clear()
	_bt_cache.clear()
	_preload_prefabs()
#endregion

#region 内部方法 - 应用配置
## 应用属性配置
func _apply_attributes(enemy: BattleActor, base_attrs: Dictionary, overrides: Dictionary) -> void:
	var attr_comp = enemy.GetAttributes()
	if attr_comp == null:
		return

	# 合并基础属性和覆盖属性
	var final_attrs = base_attrs.duplicate()
	for key in overrides.keys():
		final_attrs[key] = overrides[key]

	# 应用到 Attribute
	for attr_name in final_attrs.keys():
		var value = final_attrs[attr_name]
		var enum_value = _map_attr_name_to_enum(attr_name)
		if enum_value != -1:
			var attr = attr_comp.find_attribute(enum_value)
			if attr:
				# 设置 base_value 或 computed_value
				attr.base_value = value
				attr.computed_value = value

## 应用 BehaviorTree
func _apply_behavior_tree(enemy: BattleActor, bt_path: String, override_path: String) -> void:
	var final_path = override_path if not override_path.is_empty() else bt_path
	if final_path.is_empty():
		return

	var bt = _get_behavior_tree(final_path)
	if bt == null:
		push_warning("EnemyFactory: 无法加载 BehaviorTree %s" % final_path)
		return

	# 设置 BehaviorTree（如果敌人有这个属性）
	if enemy.get("bt") != null:
		enemy.set("bt", bt)
		# 激活 BehaviorTree
		if enemy.has_method("_setup_behavior_tree"):
			enemy._setup_behavior_tree()
#endregion

#region 内部方法 - 缓存获取
## 预加载预制体
func _preload_prefabs() -> void:
	for enemy_id in _config_loader.get_all_enemy_ids():
		var prefab_path = _config_loader.get_enemy_prefab_path(enemy_id)
		if prefab_path != "" and ResourceLoader.exists(prefab_path):
			_prefab_cache[prefab_path] = load(prefab_path)

## 获取预制体（带缓存）
func _get_prefab(path: String) -> PackedScene:
	if path.is_empty():
		return null

	if not _prefab_cache.has(path):
		if ResourceLoader.exists(path):
			_prefab_cache[path] = load(path)
		else:
			push_warning("EnemyFactory: 预制体路径不存在 %s" % path)
			return null

	return _prefab_cache[path]

## 获取 BehaviorTree（带缓存）
func _get_behavior_tree(path: String) -> Resource:
	if path.is_empty():
		return null

	if not _bt_cache.has(path):
		if ResourceLoader.exists(path):
			_bt_cache[path] = load(path)
		else:
			push_warning("EnemyFactory: BehaviorTree 路径不存在 %s" % path)
			return null

	return _bt_cache[path]
#endregion

#region 内部方法 - 属性名映射
## 将属性名字符串映射到 AttributeConfig.AttributeName 枚举
func _map_attr_name_to_enum(attr_name: String) -> int:
	attr_name = attr_name.to_lower()

	match attr_name:
		"max_hp", "hp": return AttributeConfig.AttributeName.Hp
		"attack", "atk": return AttributeConfig.AttributeName.Atk
		"armor": return AttributeConfig.AttributeName.Armor
		"mana": return AttributeConfig.AttributeName.Mana
		"crit": return AttributeConfig.AttributeName.Crit
		_: return -1
#endregion
