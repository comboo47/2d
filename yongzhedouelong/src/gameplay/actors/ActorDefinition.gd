class_name ActorDefinition extends Resource
## 角色（敌人/NPC）数据定义。把原 EnemyConfig.json 的一条配置抽成资源。
## 一个 .tres = 一个角色。运行时由 EnemyConfigLoader 扫描，经 to_config_dict()
## 转回与旧 JSON 同形态的 dict 供 EnemyFactory 消费（消费方零改动）。
## 存放目录：res://resources/gameplay/actors/

#region 标识
@export_group("标识")
## 【角色ID】主键，必填且唯一。EnemyFactory/ActorRegistry 以此索引。
@export var actor_id: int = 0
## 【代码名】内部代号（原 enemy_name），如 "FirstEnemy"。
@export var actor_name: String = ""
## 【显示名称】UI/调试用的可读名，如 "初级敌人"。
@export var display_name: String = ""
## 【描述】角色说明文本，不影响逻辑。
@export_multiline var description: String = ""
#endregion

#region 预制 / AI
@export_group("预制 / AI")
## 【预制体】角色场景（须继承 BattleActor），决定外观/碰撞/组件。
@export var prefab: PackedScene
## 【行为树】LimboAI BehaviorTree 资源（.tres），可空表示无 AI。
@export var behavior_tree: Resource
#endregion

#region 属性
@export_group("属性")
## 【初始属性】属性名→初值字典（max_hp/attack/armor/speed/jump_power 等）。
## 由 EnemyFactory 映射到 AttributeComponent。原样保留全部键，勿丢字段。
@export var attributes: Dictionary = {}
#endregion

#region 归属内容
@export_group("归属内容")
## 【拥有技能】此角色拥有的技能（强类型引用，供编辑器建树与未来 apply）。
@export var skills: Array[SkillBase] = []
## 【拥有Buff】此角色初始/拥有的 Buff。
@export var buffs: Array[AttributeBuff] = []
#endregion

#region Flow / 掉落
@export_group("Flow / 掉落")
## 【生成Flow ID】生成时触发的 Flow（经 FlowRegistry 解析），可空。
@export var spawn_flow_id: String = ""
## 【死亡Flow ID】死亡时触发的 Flow，可空。
@export var death_flow_id: String = ""
## 【掉落表ID】关联 DropConfig.json 的掉落表，可空。
@export var drop_table_id: String = ""
#endregion

## 输出与旧 EnemyConfig.json 同形态的配置 dict，供 EnemyConfigLoader/EnemyFactory 消费。
## 关键：prefab→prefab_path 字符串、behavior_tree→路径字符串、skills→skill_id 数组。
func to_config_dict() -> Dictionary:
	var skill_ids: Array = []
	for s in skills:
		if s and not s.skill_id.is_empty():
			skill_ids.append(s.skill_id)
	return {
		"enemy_id": float(actor_id),
		"enemy_name": actor_name,
		"display_name": display_name,
		"description": description,
		"prefab_path": prefab.resource_path if prefab else "",
		"behavior_tree": behavior_tree.resource_path if behavior_tree else "",
		"attributes": attributes.duplicate(true),
		"skills": skill_ids,
		"spawn_flow_id": spawn_flow_id,
		"death_flow_id": death_flow_id,
		"drop_table_id": drop_table_id,
	}

## 校验定义完整性，返回错误描述列表（空 = 通过）。供编辑器 Validate 用。
func validate() -> Array[String]:
	var errors: Array[String] = []
	if actor_id <= 0:
		errors.append("actor_id 必须为正整数")
	if prefab == null:
		errors.append("未设置 prefab（预制体）")
	return errors
