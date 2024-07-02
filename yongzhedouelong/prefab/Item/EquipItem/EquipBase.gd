@tool
extends Resource
class_name Equip_Item
	#
@export_group("Settings")
@export var name:String
@export var icon:Texture2D
@export_multiline var description:String

@export_group("Item_Data")
@export var 可否叠加:bool
@export var 可否出售:bool

@export_group("Attribute")
@export_flags("基础属性", "武器属性", "特征属性") var spell_elements = 0:
	set(b):
		spell_elements = b
		print(spell_elements)
		notify_property_list_changed()
var health:int
var armor:int
var attack:int
var AttackSpeed:int
var MoveSpeed:int

var BulletCount:int
var BoomRange:int
var PopCount:int
var PassCount:int
var BulletSpeed:int
var EnergyValue:int
var EnergyRecover:int
var ChargeSpeed:int

var exCrit:int
var exMultipleCast:int
var exKillChance:int
var exDieBullet:int
var exThunder:int
var exEdrFire:int

var AttDic:Dictionary = {
	"攻击":attack,
	"防御":armor,
	"生命":health,
	"攻速":AttackSpeed,
	"移速":MoveSpeed,
	
	"子弹数量":BulletCount,
	"爆炸范围":BoomRange,
	"弹射次数":PopCount,
	"穿透次数":PassCount,
	"子弹速度":BulletSpeed,
	"能量值":EnergyValue,
	"能量恢复速度":EnergyRecover,
	"蓄力速度":ChargeSpeed,
	
	"额外暴击":exCrit,
	"多重发射":exMultipleCast,
	"致死":exKillChance,
	"死亡分裂":exDieBullet,
	"天雷伤害":exThunder,
	"地火伤害":exEdrFire
}
func ShowBaseAttr(result):
	result.append({"name":"攻击","type":TYPE_INT})
	result.append({"name":"防御","type":TYPE_INT})
	result.append({"name":"生命","type":TYPE_INT})
	result.append({"name":"攻速","type":TYPE_INT})
	result.append({"name":"移速","type":TYPE_INT})
func ShowWeaponAttr(result):
	result.append({"name":"子弹数量","type":TYPE_INT})
	result.append({"name":"爆炸范围","type":TYPE_INT})
	result.append({"name":"弹射次数","type":TYPE_INT})
	result.append({"name":"穿透次数","type":TYPE_INT})
	result.append({"name":"子弹速度","type":TYPE_INT})
	result.append({"name":"能量值","type":TYPE_INT})
func ShowTraitAttr(result):
	result.append({"name":"额外暴击","type":TYPE_INT})
	result.append({"name":"多重发射","type":TYPE_INT})
	result.append({"name":"致死","type":TYPE_INT})
	result.append({"name":"死亡分裂","type":TYPE_INT})
	result.append({"name":"天雷伤害","type":TYPE_INT})
	result.append({"name":"地火伤害","type":TYPE_INT})

func _get_property_list():
	var result = []
	match spell_elements:
		1:
			ShowBaseAttr(result)
			print("123123")
		2:
			ShowWeaponAttr(result)
		3:
			ShowBaseAttr(result)
			ShowWeaponAttr(result)
		4:
			ShowTraitAttr(result)
		5:
			ShowBaseAttr(result)
			ShowTraitAttr(result)
		6:
			ShowWeaponAttr(result)
			ShowTraitAttr(result)
		7:
			ShowBaseAttr(result)
			ShowWeaponAttr(result)
			ShowTraitAttr(result)
	return result
	
func _set(property, value):
	if AttDic.has(property.get_basename()):
		AttDic[property.get_basename()] = value
		print(AttDic[property.get_basename()])
		return true
	return false
func _get(property):
	if AttDic.has(property.get_basename()):
		return AttDic[property.get_basename()]
		

