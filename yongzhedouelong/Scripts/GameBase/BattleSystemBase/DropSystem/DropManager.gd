extends Node
## Autoload: DropManager
## 掉落管理单例 - 统一管理游戏掉落系统
## 使用 DropConfig.json 数据驱动配置

## 单例实例
## 单例实例（不使用类型声明，因为是 autoload）
static var instance

## 掉落计算器
var _drop_calculator: DropCalculator

## Poker 预制体路径
const POKER_PREFAB_PATH := "res://prefab/Item/Poker.tscn"

## 初始化完成信号
signal drop_manager_initialized

func _init():
	instance = self

func _ready():
	# 创建配置加载器
	var config_loader = EnemyConfigLoader.new()
	config_loader.load_configs()

	# 创建掉落计算器
	_drop_calculator = DropCalculator.new(config_loader)

	# 加载 Poker 预制体
	_load_poker_prefab()

	drop_manager_initialized.emit()

#region 公共 API - 掉落处理
## 处理敌人死亡掉落
func handle_enemy_death(enemy: BattleActor) -> Array[Node]:
	return _drop_calculator.handle_enemy_death_drop(enemy)

## 根据掉落表生成掉落
func spawn_drops(drop_table_id: String, position: Vector2) -> Array[Node]:
	return _drop_calculator.spawn_drops(drop_table_id, position)

## 计算掉落列表（不生成实例）
func calculate_drops(drop_table_id: String) -> Array[Dictionary]:
	return _drop_calculator.calculate_drops(drop_table_id)
#endregion

#region 公共 API - 兼容旧接口
## 兼容旧接口：dropPoker
func dropPoker(droper: Node) -> void:
	if droper is BattleActor:
		handle_enemy_death(droper)
	else:
		push_warning("DropManager: dropPoker 参数不是 BattleActor")

## 兼容旧接口：getDropItem
func getDropItem(droperID: int) -> Vector2:
	var drop_table_id = _drop_calculator._config_loader.get_enemy_drop_table_id(droperID)
	var drops = _drop_calculator.calculate_drops(drop_table_id)

	if drops.is_empty():
		return Vector2(0, 0)

	# 返回第一个掉落物品的扑克牌信息
	var first_drop = drops[0]
	return Vector2(first_drop.get("number", 0), first_drop.get("flower", 0))
#endregion

#region 公共 API - 池状态
## 获取待掉落池大小
func get_wait_pool_size() -> int:
	return _drop_calculator.get_wait_pool_size()

## 获取已掉落池大小
func get_dropped_pool_size() -> int:
	return _drop_calculator.get_dropped_pool_size()

## 强制重置扑克牌池
func reset_poker_pool() -> void:
	_drop_calculator.force_reset_pool()
#endregion

#region 公共 API - 配置
## 重新加载配置
func reload_configs() -> void:
	_drop_calculator._config_loader.reload()

## 设置 Poker 预制体
func set_poker_prefab(prefab: PackedScene) -> void:
	_drop_calculator.set_poker_prefab(prefab)

## 获取掉落计算器（直接访问）
func get_calculator() -> DropCalculator:
	return _drop_calculator
#endregion

#region 内部方法
## 加载 Poker 预制体
func _load_poker_prefab() -> void:
	if ResourceLoader.exists(POKER_PREFAB_PATH):
		var prefab = load(POKER_PREFAB_PATH)
		_drop_calculator.set_poker_prefab(prefab)
	else:
		push_warning("DropManager: Poker 预制体不存在 %s" % POKER_PREFAB_PATH)
#endregion
