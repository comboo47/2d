class_name LevelActorDefinition extends Resource

@export var actor_scene: PackedScene
@export var position: Vector2 = Vector2.ZERO
## 是否为敌人。关卡结束判定按此区分：仅 is_enemy 的 actor 计入"清空胜利"。
## 玩家/友方设 false。
@export var is_enemy: bool = true
## 实例初始化数据（第十一期）：SpawnFlow/DeathFlow 等。可空。生成时经 setup_init_data 注入。
@export var init_data: ActorInitData = null
@export var initial_skills: Array[SkillBase] = []
@export var initial_buffs: Array[AttributeBuff] = []
