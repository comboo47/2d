class_name EnemySpawnData extends RefCounted
## 敌人生成数据结构
## 包含生成位置、敌人 ID、初始化参数等

## 敌人 ID（对应 EnemyConfig.json）
var enemy_id: int = 1001

## 生成位置
var spawn_position: Vector2 = Vector2.ZERO

## 初始方向（用于移动方向）
var initial_direction: float = 1.0

## 是否激活（生成后立即开始行动）
var activate_on_spawn: bool = true

## 自定义属性覆盖（可选，覆盖 EnemyConfig 中的默认属性）
var attribute_overrides: Dictionary = {}

## 自定义 BehaviorTree 覆盖（可选）
var behavior_tree_override: String = ""

## 自定义掉落表覆盖（可选）
var drop_table_override: String = ""

## 从字典创建生成数据
static func from_dict(data: Dictionary) -> EnemySpawnData:
	var spawn_data = EnemySpawnData.new()
	spawn_data.enemy_id = data.get("enemy_id", 1001)

	if data.has("position"):
		var pos_data = data["position"]
		spawn_data.spawn_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))

	spawn_data.initial_direction = data.get("initial_direction", 1.0)
	spawn_data.activate_on_spawn = data.get("activate_on_spawn", true)

	if data.has("attribute_overrides"):
		spawn_data.attribute_overrides = data["attribute_overrides"]

	spawn_data.behavior_tree_override = data.get("behavior_tree_override", "")
	spawn_data.drop_table_override = data.get("drop_table_override", "")

	return spawn_data

## 转换为字典（用于序列化）
func to_dict() -> Dictionary:
	var data = {
		"enemy_id": enemy_id,
		"position": {"x": spawn_position.x, "y": spawn_position.y},
		"initial_direction": initial_direction,
		"activate_on_spawn": activate_on_spawn,
	}

	if not attribute_overrides.is_empty():
		data["attribute_overrides"] = attribute_overrides

	if behavior_tree_override != "":
		data["behavior_tree_override"] = behavior_tree_override

	if drop_table_override != "":
		data["drop_table_override"] = drop_table_override

	return data