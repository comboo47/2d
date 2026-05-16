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
var t:Array
@export_group("Attribute")
var DynaEffect:DynEffect

@export_flags("基础属性", "武器属性", "特征属性") var spell_elements = 0:
	set(b):
		spell_elements = b
		#print(spell_elements)
		notify_property_list_changed()

var AttrDic:Dictionary = {}
var DynAttrDic:Dictionary = {}
	
func ShowBaseAttr(result):
	for i in BattleGlobal.BaseAttr:
		result.append({"name":i,"type":TYPE_INT})
func ShowWeaponAttr(result):
	for i in BattleGlobal.WeaponAttr:
		result.append({"name":i,"type":TYPE_INT})
func ShowSpecAttr(result):
	for i in BattleGlobal.SpecialAttr:
		result.append({"name":i,"type":TYPE_INT})

func _get_property_list():
	var result = []
	match spell_elements:
		0:
			result.append({
				"name":"DynaEffect",
				"type":TYPE_OBJECT,
				"hint":PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string":"DynEffect"
				})
		1:
			ShowBaseAttr(result)
		2:
			ShowWeaponAttr(result)
		3:
			ShowBaseAttr(result)
			ShowWeaponAttr(result)
		4:
			ShowSpecAttr(result)
		5:
			ShowBaseAttr(result)
			ShowSpecAttr(result)
		6:
			ShowWeaponAttr(result)
			ShowSpecAttr(result)
		7:
			ShowBaseAttr(result)
			ShowWeaponAttr(result)
			ShowSpecAttr(result)
	return result
	
func _set(property, value):
	if AttrDic == {}:
		#for i in BattleGlobal.BaseAttr:
			#AttrDic[i] = 0
		#for i in BattleGlobal.WeaponAttr:
			#AttrDic[i] = 0
		#for i in BattleGlobal.SpecialAttr:
			#AttrDic[i] = 0
		AttrDic = BattleGlobal.initAttributeDic(AttrDic,BattleGlobal.AttType.all)
	if AttrDic.has(property.get_basename()):
		AttrDic[property.get_basename()] = value
		print(AttrDic[property.get_basename()])
		return true
	if property == "DynaEffect":
		DynaEffect = value
		
	return false
func _get(property):
	if AttrDic.has(property.get_basename()):
		return AttrDic[property.get_basename()]
	if property == "DynaEffect":
		return getEffect()
func getDynEffect()->Dictionary:
	return DynaEffect.EffectDic
func getEffect()->Dictionary:
	return AttrDic
