extends Node

static var instance

var _drop_calculator: DropCalculator

signal drop_manager_initialized

func _init():
	instance = self

func _ready():
	var config_loader = EnemyConfigLoader.new()
	config_loader.load_configs()

	_drop_calculator = DropCalculator.new(config_loader)
	drop_manager_initialized.emit()

func handle_enemy_death(enemy: BattleActor) -> Array[Node]:
	return _drop_calculator.handle_enemy_death_drop(enemy)

func spawn_drops(drop_table_id: String, position: Vector2) -> Array[Node]:
	return _drop_calculator.spawn_drops(drop_table_id, position)

func calculate_drops(drop_table_id: String) -> Array[Dictionary]:
	return _drop_calculator.calculate_drops(drop_table_id)

func dropPoker(droper: Node) -> void:
	if droper is BattleActor:
		handle_enemy_death(droper)
	else:
		push_warning("DropManager: dropPoker expects a BattleActor")

func getDropItem(droperID: int) -> Vector2:
	var drop_table_id = _drop_calculator._config_loader.get_enemy_drop_table_id(droperID)
	var drops = _drop_calculator.calculate_drops(drop_table_id)

	if drops.is_empty():
		return Vector2(0, 0)

	var first_drop = drops[0]
	return Vector2(first_drop.get("number", 0), first_drop.get("flower", 0))

func get_wait_pool_size() -> int:
	return _drop_calculator.get_wait_pool_size()

func get_dropped_pool_size() -> int:
	return _drop_calculator.get_dropped_pool_size()

func reset_poker_pool() -> void:
	_drop_calculator.force_reset_pool()

func reload_configs() -> void:
	_drop_calculator._config_loader.reload()

func set_poker_prefab(prefab: PackedScene) -> void:
	_drop_calculator.set_poker_prefab(prefab)

func get_calculator() -> DropCalculator:
	return _drop_calculator
