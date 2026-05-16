class_name FE_SpawnEntity extends FlowEffectBase
## 生成实体效果
## 在指定位置生成实体（掉落物、子弹等）

## 实体场景路径
@export var entity_scene: PackedScene

## 是否作为目标的子节点
@export var as_child_of_target: bool = false

## 位置偏移
@export var position_offset: Vector2 = Vector2.ZERO

## 生成后的初始化数据（传递给实体的 init 方法）
@export var init_data: Dictionary = {}

## 执行实体生成
func apply(context: GameplayFlowContext) -> void:
	if entity_scene == null:
		push_warning("FE_SpawnEntity: entity_scene 为空")
		return

	# 实例化实体
	var entity = entity_scene.instantiate()
	if entity == null:
		push_warning("FE_SpawnEntity: 无法实例化实体")
		return

	# 设置位置
	entity.global_position = context.get_position() + position_offset

	# 添加到场景树
	if as_child_of_target and context.target:
		context.target.add_child(entity)
	else:
		var tree = context.source.get_tree() if context.source else get_tree()
		if tree and tree.current_scene:
			tree.current_scene.add_child(entity)

	# 初始化（如果有 init 方法）
	if entity.has_method("init") and not init_data.is_empty():
		entity.init(init_data)

func get_description() -> String:
	if entity_scene == null:
		return "生成实体（未配置场景）"
	return "生成实体: %s" % entity_scene.resource_path