class_name DropCalculator extends RefCounted
## 掉落计算器
## 根据掉落配置计算实际掉落物品

## 掉落配置加载器引用
var _config_loader: EnemyConfigLoader

## 扑克牌待掉落池 {Vector2(number, flower)}
var _poker_wait_pool: Array = []

## 已掉落扑克牌池
var _poker_dropped_pool: Array = []

## Poker 预制体
var _poker_prefab: PackedScene = null

func _init(config_loader: EnemyConfigLoader):
	_config_loader = config_loader
	_init_poker_pool()

## 初始化扑克牌池
func _init_poker_pool() -> void:
	# 创建所有扑克牌（1-13号，4种花色）
	for number in range(1, 14):
		for flower in range(0, 4):
			_poker_wait_pool.append(Vector2(number, flower))

## 设置 Poker 预制体
func set_poker_prefab(prefab: PackedScene) -> void:
	_poker_prefab = prefab

#region 公共 API - 掉落计算
## 计算掉落列表
func calculate_drops(drop_table_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if drop_table_id.is_empty():
		return result

	# 获取掉落配置
	var config = _config_loader.get_drop_config(drop_table_id)
	if config.is_empty():
		return result

	# 获取掉落条目列表
	var drop_entries = config.get("drops", [])
	var max_drops = _config_loader.get_max_drops(drop_table_id)

	# 按权重随机选择
	for drop_entry in drop_entries:
		if result.size() >= max_drops:
			break

		if _roll_weight(drop_entry.get("weight", 100)):
			var drop_item = _generate_drop_item(drop_entry)
			if not drop_item.is_empty():
				result.append(drop_item)

	# 添加保底掉落
	var guaranteed = config.get("guaranteed_drop")
	if guaranteed != null and not guaranteed.is_empty():
		var guaranteed_item = _generate_drop_item(guaranteed)
		if not guaranteed_item.is_empty():
			result.append(guaranteed_item)

	return result

## 生成掉落实例并添加到场景
func spawn_drops(drop_table_id: String, spawn_position: Vector2, parent: Node = null) -> Array[Node]:
	var drops = calculate_drops(drop_table_id)
	var spawned: Array[Node] = []

	if _poker_prefab == null:
		push_warning("DropCalculator: Poker 预制体未设置")
		return spawned

	var global_config = _config_loader.get_global_drop_config()
	var offset = Vector2(0, 0)
	if global_config.has("drop_spawn_offset"):
		offset = Vector2(global_config["drop_spawn_offset"].get("x", 0), global_config["drop_spawn_offset"].get("y", -5))

	for drop_data in drops:
		if drop_data.get("item_type") == "poker" or drop_data.get("item_type") == "random_poker" or drop_data.get("item_type") == "specific_poker":
			var poker = _poker_prefab.instantiate()
			poker.number = drop_data.get("number", 1)
			poker.flower = drop_data.get("flower", 0)
			poker.position = spawn_position + offset + Vector2(randf() * 10 - 5, randf() * 10 - 5)

			# 从池中移除
			_remove_from_pool(Vector2(poker.number, poker.flower))

			# 添加到场景
			if parent:
				parent.add_child(poker)
			else:
				spawned.append(poker)

	return spawned

## 处理敌人死亡掉落（兼容旧接口）
func handle_enemy_death_drop(enemy: BattleActor) -> Array[Node]:
	var drop_table_id = ""

	# 尝试获取敌人的掉落表 ID
	if enemy.get("drop_table_id") != null:
		drop_table_id = enemy.get("drop_table_id")
	elif enemy.has_method("get_drop_table_id"):
		drop_table_id = enemy.get_drop_table_id()
	elif enemy.has_method("getID"):
		# 兼容旧接口：根据敌人 ID 硬编码获取
		var enemy_id = enemy.getID()
		drop_table_id = _config_loader.get_enemy_drop_table_id(enemy_id)

	return spawn_drops(drop_table_id, enemy.global_position)
#endregion

#region 内部方法 - 随机计算
## 权重随机（返回是否命中）
func _roll_weight(weight: int) -> bool:
	return randi() % 100 < weight

## 生成单个掉落物品数据
func _generate_drop_item(entry: Dictionary) -> Dictionary:
	var item_type = entry.get("item_type", "")

	match item_type:
		"random_poker":
			return _generate_random_poker()
		"specific_poker":
			return {
				"item_type": "poker",
				"number": entry.get("number", 1),
				"flower": entry.get("flower", 0)
			}
		"poker":
			# 通用扑克牌类型
			if entry.has("min_number") and entry.has("max_number"):
				var number = randi_range(entry["min_number"], entry["max_number"])
				var flower = randi_range(0, 3)
				return {"item_type": "poker", "number": number, "flower": flower}
			elif entry.has("number") and entry.has("flower"):
				return {"item_type": "poker", "number": entry["number"], "flower": entry["flower"]}
			else:
				return _generate_random_poker()
		_:
			push_warning("DropCalculator: 未知的掉落类型 %s" % item_type)
			return {}

## 生成随机扑克牌
func _generate_random_poker() -> Dictionary:
	if _poker_wait_pool.is_empty():
		# 检查是否需要重置池
		var global_config = _config_loader.get_global_drop_config()
		if global_config.get("poker_pool_reset_when_empty", true):
			_reset_poker_pool()
		else:
			push_warning("DropCalculator: 扑克牌池已空")
			return {}

	var poker = _poker_wait_pool.pick_random()
	return {
		"item_type": "poker",
		"number": int(poker.x),
		"flower": int(poker.y)
	}

## 从池中移除扑克牌
func _remove_from_pool(poker: Vector2) -> void:
	_poker_dropped_pool.append(poker)
	_poker_wait_pool.erase(poker)

	# 检查是否需要重置池
	if _poker_wait_pool.is_empty():
		var global_config = _config_loader.get_global_drop_config()
		if global_config.get("poker_pool_reset_when_empty", true):
			_reset_poker_pool()

## 重置扑克牌池
func _reset_poker_pool() -> void:
	for poker in _poker_dropped_pool:
		_poker_wait_pool.append(poker)
	_poker_dropped_pool.clear()
#endregion

#region 公共 API - 池状态查询
## 获取待掉落池大小
func get_wait_pool_size() -> int:
	return _poker_wait_pool.size()

## 获取已掉落池大小
func get_dropped_pool_size() -> int:
	return _poker_dropped_pool.size()

## 强制重置池
func force_reset_pool() -> void:
	_reset_poker_pool()
#endregion