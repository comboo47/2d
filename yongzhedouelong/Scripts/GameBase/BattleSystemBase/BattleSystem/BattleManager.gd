extends Node
## Autoload: BattleManager
## 战斗系统静态方法集合

## 显式加载依赖类（避免 GDScript.get_path() 冲突）
const VfxConfigClass = preload("res://Scripts/GameBase/BattleSystemBase/VfxSystem/VfxConfig.gd")
const SkillConfigClass = preload("res://Scripts/GameBase/BattleSystemBase/SkillSystem/SkillConfig.gd")

#region Buff相关方法
static func ApplyBuff(buffSource:BattleActor,buffTarget:BattleActor,buffID:String)->void:
	var buff_id = buffID
	var buff_resource = DataRegistry.instance.get_buff(buff_id)
	if buff_resource:
		var buff_instance:AttributeBuff = buff_resource.deep_duplicate(buffSource,buffTarget)
		buffTarget.buffManager.buffList.append(buff_instance)

static func RemoveBuff(buffSource:BattleActor,buffTarget:BattleActor,buffID:int)->void:
	#遍历buffList，找到buffID = buffid的buff
	#调用buff的remove方法
	#从buffList里删除buff
	pass
static func SetBuffLayer(buffOwner:BattleActor,buffID:int,layer:int)->void:
	pass
static func SetBuffMaxLayer(buffOwner:BattleActor,buffID:int,layer:int)->void:
	pass
static func SetBuffLayerToMax(buffOwner:BattleActor,buffID:int)->void:
	pass
static func AddBuffLayer(buffOwner:BattleActor,buffID:int,layer:int)->void:
	pass
static func GetBuffLayer(buffOwner:BattleActor,buffID:int)->int:
	return 0
	pass
static func RemoveBuffLayer(buffOwner:BattleActor,buffID:int,layer:int)->void:
	pass
static func SetBuffLifeTime(buffOwner:BattleActor,buffID:int,time:float)->void:
	pass
static func GetBuffLifeTime(buffOwner:BattleActor,buffID:int)->float:
	return 0
	pass
static func SetBuffLeftTime(buffOwner:BattleActor,buffID:int,time:float)->void:
	pass
static func GetBuffLeftTime(buffOwner:BattleActor,buffID:int)->float:
	return 0
	pass
static func RefreshBuff(buffOwner:BattleActor,buffID:int)->void:
	pass
static func ActiveBuffImm(buffOwner:BattleActor,buffID:int)->void:
	#立即激活buff，调一下buffGo
	pass
#endregion

#region Skill 相关方法
## 应用技能效果到目标
static func ApplySkill(source: BattleActor, target: BattleActor, skill_id: String) -> bool:
	if source == null or target == null:
		return false

	var skill_manager = source.get_skill_manager()
	if skill_manager == null:
		push_warning("BattleManager.ApplySkill: source 无 SkillManager")
		return false

	var context = GameplayFlowContext.create_attack(source, target)
	return skill_manager.use_skill(skill_id, context)

## 为角色添加技能
static func AddSkillToActor(actor: BattleActor, skill_id: String, slot: SkillConfigClass.SkillSlot = SkillConfigClass.SkillSlot.SECONDARY) -> bool:
	if actor == null:
		return false

	var skill = SkillRegistry.instance.get_skill(skill_id)
	if skill == null:
		push_warning("BattleManager.AddSkillToActor: 未找到技能 ID=%s" % skill_id)
		return false

	actor.add_skill(skill, slot)
	return true

## 为角色初始化技能管理器并添加技能列表
static func SetupSkillManager(actor: BattleActor, skill_ids: Array[String]) -> SkillManager:
	return SkillRegistry.instance.setup_skill_manager(actor, skill_ids)
#endregion

#region Vfx 相关方法
## 播放特效
static func PlayVfx(vfx_type: VfxConfigClass.VfxType, position: Vector2) -> void:
	if VfxManager.instance:
		VfxManager.instance.play_vfx(vfx_type, position)

## 播放特效并跟随目标
static func PlayVfxFollow(vfx_type: VfxConfigClass.VfxType, target: Node2D, offset: Vector2 = Vector2.ZERO) -> void:
	if VfxManager.instance:
		VfxManager.instance.play_vfx_follow(vfx_type, target, offset)
#endregion

#region Flow 相关方法
## 执行 GameplayFlow
static func ExecuteFlow(flow_id: String, context: GameplayFlowContext) -> void:
	if FlowRegistry.instance == null:
		return

	var flow = FlowRegistry.instance.get_flow(flow_id)
	if flow:
		flow.execute(context)

## 触发角色的受伤 Flow
static func TriggerHitFlow(target: BattleActor, damage: float, source: BattleActor = null) -> void:
	target.trigger_hit_flow(damage, source)

## 触发角色的死亡 Flow
static func TriggerDeathFlow(target: BattleActor) -> void:
	target.trigger_death_flow()
#endregion

#region 战斗相关方法
static func hurt()->void:
	pass
static func heal()->void:
	pass
static func CreateMonster()->void:
	pass
static func DestoryMonster()->void:
	pass
static func SetMonsterDead()->void:
	pass
static func SearchTarget()->void:
	pass
static func CreateFiltter()->void:
	pass
#endregion

#region 敌人创建方法
## 创建敌人（使用 EnemyFactory）
static func CreateEnemy(enemy_id: int, position: Vector2, parent: Node = null) -> BattleActor:
	if EnemyFactory.instance == null:
		push_warning("BattleManager.CreateEnemy: EnemyFactory 未初始化")
		return null

	return EnemyFactory.instance.spawn_enemy(enemy_id, position, parent)

## 创建敌人（使用生成数据）
static func CreateEnemyFromData(spawn_data: EnemySpawnData, parent: Node = null) -> BattleActor:
	if EnemyFactory.instance == null:
		return null

	return EnemyFactory.instance.spawn_enemy_from_data(spawn_data, parent)
#endregion

#region 掉落处理方法
## 处理敌人死亡掉落
static func HandleDrop(enemy: BattleActor) -> Array[Node]:
	if DropManager.instance == null:
		return []

	return DropManager.instance.handle_enemy_death(enemy)

## 根据掉落表生成掉落
static func SpawnDrops(drop_table_id: String, position: Vector2) -> Array[Node]:
	if DropManager.instance == null:
		return []

	return DropManager.instance.spawn_drops(drop_table_id, position)
#endregion
