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
		#print(spell_elements)
		notify_property_list_changed()
		

var AttrDic:Dictionary = {}
	
func ShowBaseAttr(result):
	for i in BattleGlobal.BaseAttribute:
		result.append({"name":i,"type":TYPE_INT})
func ShowWeaponAttr(result):
	for i in BattleGlobal.WeaponAttribute:
		result.append({"name":i,"type":TYPE_INT})
func ShowSpecAttr(result):
	for i in BattleGlobal.SpecialAttribute:
		result.append({"name":i,"type":TYPE_INT})

func _get_property_list():
	var result = []
	match spell_elements:
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
		#for i in BattleGlobal.BaseAttribute:
			#AttrDic[i] = 0
		#for i in BattleGlobal.WeaponAttribute:
			#AttrDic[i] = 0
		#for i in BattleGlobal.SpecialAttribute:
			#AttrDic[i] = 0
		AttrDic = BattleGlobal.initAttributeDic(AttrDic,BattleGlobal.AttType.all)
	if AttrDic.has(property.get_basename()):
		AttrDic[property.get_basename()] = value
		print(AttrDic[property.get_basename()])
		return true
	return false
func _get(property):
	if AttrDic.has(property.get_basename()):
		return AttrDic[property.get_basename()]
		

