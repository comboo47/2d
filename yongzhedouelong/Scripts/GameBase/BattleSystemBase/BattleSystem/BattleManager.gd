extends Node

#region Buff相关方法
static func ApplyBuff(buffSource:BattleActor,buffTarget:BattleActor,buffID:String)->void:
	var buff_id = buffID
	var buff_resource = DataRegistry.instance.get_buff(buff_id)
	if buff_resource:
		var buff_instance:AttributeBuff = buff_resource.deep_duplicate(buffSource,buffTarget)
		#print(buff_instance.buff_name)
		buffTarget.buffManager.buffList.append(buff_instance)
	pass
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

#region 战斗相关相关方法
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

#region 战斗相关相关方法
static func CreateVfx()->void:
	pass

#endregion
