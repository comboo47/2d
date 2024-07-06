extends Resource
class_name BattleGlobal
enum AttType{
	base,
	weapon,
	special,
	all,
}

enum BaseAttr{
	health,
	armor,
	attack,
	AttackSpeed,
	MoveSpeed,
} 

enum WeaponAttr{
	BulletCount,
	BoomRange,
	PopCount,
	PassCount,
	BulletSpeed,	
	EnergyValue,
	EnergyRecover,
	ChargeSpeed,
} 
enum SpecialAttr{
	exCrit,
	exMultipleCast,
	exKillChance,
	exDieBullet,
	exThunder,
	exEdrFire,
}
enum DyAttr{
	curHp,
	
	curMaxHp,
	curMaxHpAdd,
	curMaxHpMul,

	curatk,
	atkAdd,
	atkMul,

	curdef,
	defAdd,
	defMul,

	curspeed,
	speedAdd,
	speedMul,

	curatkTime,
	atkTimeAdd,
	atkTimeMul,

	curBulletCount,
	BulletCountAdd,
	BulletCountMul,

	curBoomRange,
	BoomRangeAdd,
	BoomRangeMul,

	curPopCount,
	PopCountAdd,
	PopCountMul,

	curPassCount,
	PassCountAdd,
	PassCountMul,

	curBulletSpeed,
	BulletSpeedAdd,
	BulletSpeedMul,

	curEnergyValue,
	EnergyValueAdd,
	EnergyValueMul,

	curEnergyRecover,
	EnergyRecoverAdd,
	EnergyRecoverMul,

	curChargeSpeed,
	ChargeSpeedAdd,
	ChargeSpeedMul,

	cur_exCrit,
	exCritAdd,
	exCritMul,

	cur_exMultipleCast,
	exMultipleCastAdd,
	exMultipleCastMul,

	cur_exKillChance,
	exKillChanceAdd,
	exKillChanceMul,

	cur_exDieBullet,
	exDieBulletAdd,
	exDieBulletMul,

	cur_exThunder,
	exThunderAdd,
	exThunderMul,

	cur_exEdrFire,
	exEdrFireAdd,
	exEdrFireMul,
}

static func initAttributeDic(Dic:Dictionary,attributeType:AttType)->Dictionary:
	match attributeType:
		AttType.base:
			for i in BaseAttr:
				Dic[i] = 0
		AttType.weapon:
			for i in WeaponAttr:
				Dic[i] = 0
		AttType.weapon:
			for i in SpecialAttr:
				Dic[i] = 0
		_:
			for i in BaseAttr:
				Dic[i] = 0
			for i in WeaponAttr:
				Dic[i] = 0
			for i in SpecialAttr:
				Dic[i] = 0
	return Dic

static func initDynamicAttrDic(Dic:Dictionary) ->Dictionary:
	for i:String in DyAttr:
		if i.ends_with("Mul"):
			Dic[i] = 1
		else:
			Dic[i] = 0
	return Dic
	
