class_name BattleStats
extends Node

@export var currentLevel:int = 1
@export var Stats:BasicStats
@export var equipMent:Array[Equip_Item]

var AttrDic:Dictionary = {}
var DynamicAttrDic:Dictionary = {}
# Called when the node enters the scene tree for the first time.
func _ready():
	AttrDic = BattleGlobal.initAttributeDic(AttrDic,BattleGlobal.AttType.all)
	DynamicAttrDic = BattleGlobal.initDynamicAttrDic(DynamicAttrDic)
	print("StateAttrDic",AttrDic.size())
	initBasicAttr()
	initEquipAttribute()
	pass # Replace with function body.

func initBasicAttr():
	AttrDic["health"] = Stats.MaxHealth + currentLevel * Stats.upHealth
	AttrDic["attack"] = Stats.AttackPoint + currentLevel * Stats.upAttack
	AttrDic["armor"] = Stats.DefencePoint + currentLevel * Stats.upDefencePoint
	AttrDic["MoveSpeed"] = Stats.MoveSpeed + currentLevel * Stats.upMoveSpeed
	AttrDic["AttackSpeed"] = Stats.AttackTime + currentLevel * Stats.upAttackTime
# Called every frame. 'delta' is the elapsed time since the previous frame.
func initEquipAttribute():
	for i:Equip_Item in equipMent:
		addEquip(i)

func addEquip(equip:Equip_Item):
	for i in equip.getEffect():
		if AttrDic.has(i):
			AttrDic[i] += equip.getEffect()[i]
	if equip.DynaEffect != null:
		for i in equip.getDynEffect():
			if DynamicAttrDic.has(i):
				DynamicAttrDic[i] += equip.getDynEffect()[i]
	UpdateCurAttr()
func removeEquip(equip:Equip_Item):
	for i in equip.getEffect():
		if AttrDic.has(i):
			AttrDic[i] -= equip.getEffect()[i]
	if equip.DynaEffect != null:
		for i in equip.getDynEffect():
			if DynamicAttrDic.has(i):
				DynamicAttrDic[i] -= equip.getDynEffect()[i]
	UpdateCurAttr()
func printAttr():
	for i in AttrDic:
		print(i,":",AttrDic[i])
	
func UpdateCurAttr():
	var j = 1
	var base = []
	for i in BattleGlobal.BaseAttr:
		base.append(i)
	for i in BattleGlobal.WeaponAttr:
		base.append(i)
	for i in BattleGlobal.SpecialAttr:
		base.append(i)
	for i in range(base.size()):
		DynamicAttrDic[BattleGlobal.DyAttr.keys()[j]] = AttrDic[base[i]] * DynamicAttrDic[BattleGlobal.DyAttr.keys()[j+2]] + DynamicAttrDic[BattleGlobal.DyAttr.keys()[j+1]]
		j += 3
	DynamicAttrDic[BattleGlobal.DyAttr.keys()[0]] = DynamicAttrDic[BattleGlobal.DyAttr.keys()[1]]
	#DynamicAttrDic[BattleGlobal.DyAttr.curMaxHp] = AttrDic[BattleGlobal.BaseAttr.health] * DynamicAttrDic[BattleGlobal.DyAttr.curMaxHpMul] + DynamicAttrDic[BattleGlobal.DyAttr.curMaxHpAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curatk] = AttrDic[BattleGlobal.BaseAttr.attack] * DynamicAttrDic[BattleGlobal.DyAttr.atkMul] + DynamicAttrDic[BattleGlobal.DyAttr.atkAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curdef] = AttrDic[BattleGlobal.BaseAttr.armor] * DynamicAttrDic[BattleGlobal.DyAttr.defMul] + DynamicAttrDic[BattleGlobal.DyAttr.defAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curspeed] = AttrDic[BattleGlobal.BaseAttr.MoveSpeed] * DynamicAttrDic[BattleGlobal.DyAttr.speedMul] + DynamicAttrDic[BattleGlobal.DyAttr.speedAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curatkTime] = AttrDic[BattleGlobal.BaseAttr.AttackSpeed] * DynamicAttrDic[BattleGlobal.DyAttr.atkTimeMul] + DynamicAttrDic[BattleGlobal.DyAttr.atkTimeAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curBulletCount] = AttrDic[BattleGlobal.WeaponAttr.BulletCount] * DynamicAttrDic[BattleGlobal.DyAttr.BulletCountMul] + DynamicAttrDic[BattleGlobal.DyAttr.BulletCountAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curBoomRange] = AttrDic[BattleGlobal.WeaponAttr.BoomRange] * DynamicAttrDic[BattleGlobal.DyAttr.BoomRangeMul] + DynamicAttrDic[BattleGlobal.DyAttr.BoomRangeAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curPopCount] = AttrDic[BattleGlobal.WeaponAttr.PopCount] * DynamicAttrDic[BattleGlobal.DyAttr.PopCountMul] + DynamicAttrDic[BattleGlobal.DyAttr.PopCountAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curPassCount] = AttrDic[BattleGlobal.WeaponAttr.PassCount] * DynamicAttrDic[BattleGlobal.DyAttr.PassCountMul] + DynamicAttrDic[BattleGlobal.DyAttr.PassCountAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curBulletSpeed] = AttrDic[BattleGlobal.WeaponAttr.BulletSpeed] * DynamicAttrDic[BattleGlobal.DyAttr.BulletSpeedMul] + DynamicAttrDic[BattleGlobal.DyAttr.BulletSpeedAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curEnergyValue] = AttrDic[BattleGlobal.WeaponAttr.EnergyValue] * DynamicAttrDic[BattleGlobal.DyAttr.EnergyValueMul] + DynamicAttrDic[BattleGlobal.DyAttr.EnergyValueAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.curChargeSpeed] = AttrDic[BattleGlobal.WeaponAttr.ChargeSpeed] * DynamicAttrDic[BattleGlobal.DyAttr.ChargeSpeedMul] + DynamicAttrDic[BattleGlobal.DyAttr.ChargeSpeedAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.cur_exCrit] = AttrDic[BattleGlobal.SpecialAttr.exCrit] * DynamicAttrDic[BattleGlobal.DyAttr.exCritMul] + DynamicAttrDic[BattleGlobal.DyAttr.exCritAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.cur_exMultipleCast] = AttrDic[BattleGlobal.SpecialAttr.exMultipleCast] * DynamicAttrDic[BattleGlobal.DyAttr.exMultipleCastMul] + DynamicAttrDic[BattleGlobal.DyAttr.exMultipleCastAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.cur_exKillChance] = AttrDic[BattleGlobal.SpecialAttr.exKillChance] * DynamicAttrDic[BattleGlobal.DyAttr.exKillChanceMul] + DynamicAttrDic[BattleGlobal.DyAttr.exKillChanceAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.cur_exDieBullet] = AttrDic[BattleGlobal.SpecialAttr.exDieBullet] * DynamicAttrDic[BattleGlobal.DyAttr.exDieBulletMul] + DynamicAttrDic[BattleGlobal.DyAttr.exDieBulletAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.cur_exThunder] = AttrDic[BattleGlobal.SpecialAttr.exThunder] * DynamicAttrDic[BattleGlobal.DyAttr.exThunderMul] + DynamicAttrDic[BattleGlobal.DyAttr.exThunderAdd]
	#DynamicAttrDic[BattleGlobal.DyAttr.cur_exEdrFire] = AttrDic[BattleGlobal.SpecialAttr.exEdrFire] * DynamicAttrDic[BattleGlobal.DyAttr.exEdrFireMul] + DynamicAttrDic[BattleGlobal.DyAttr.exEdrFireAdd]
func _process(delta):
	pass
