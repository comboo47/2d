extends Resource
class_name BattleGlobal
enum AttType{
	base,
	weapon,
	special,
	all,
}

enum BaseAttribute{
	health,
	armor,
	attack,
	AttackSpeed,
	MoveSpeed,
} 

enum WeaponAttribute{
	BulletCount,
	BoomRange,
	PopCount,
	PassCount,
	BulletSpeed,	
	EnergyValue,
	EnergyRecover,
	ChargeSpeed,
} 
enum SpecialAttribute{
	exCrit,
	exMultipleCast,
	exKillChance,
	exDieBullet,
	exThunder,
	exEdrFire,
}
enum DynamicAttribute{
	
}

static func initAttributeDic(Dic:Dictionary,attributeType:AttType)->Dictionary:
	match attributeType:
		AttType.base:
			for i in BaseAttribute:
				Dic[i] = 0
		AttType.weapon:
			for i in WeaponAttribute:
				Dic[i] = 0
		AttType.weapon:
			for i in SpecialAttribute:
				Dic[i] = 0
		_:
			for i in BaseAttribute:
				Dic[i] = 0
			for i in WeaponAttribute:
				Dic[i] = 0
			for i in SpecialAttribute:
				Dic[i] = 0
	return Dic

static func initDynamicAttrDic(Dic:Dictionary) ->Dictionary:
	for i in DynamicAttribute:
		Dic[i] = 0
	return Dic
	
