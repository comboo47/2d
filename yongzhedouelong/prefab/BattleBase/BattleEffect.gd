@tool
extends Resource
class_name BattleEffect

var KeyList = PackedInt32Array([0,0,0,0,0,0,0,0,0,0,0,0,0])
var ValueList = PackedInt32Array([0,0,0,0,0,0,0,0,0,0,0,0,0])

@export_group("EffectSetting")
@export_enum("Instance","Duration","Inifi") var EffectType = 0:
	set(t):
		EffectType = t
		notify_property_list_changed()
@export var periodTime:float
@export var totalTime:float

@export_group("Effects")
@export var EffectNum = 3:
	set(n):
		EffectNum = n
		KeyList.resize(EffectNum)
		ValueList.resize(EffectNum)
		#EffectDic.clear()
		notify_property_list_changed()
var EffectDic:Dictionary = {}

func _get_property_list():
	var result = []
	var hint:String = ","
	var a = BattleGlobal.BaseAttribute.keys() + BattleGlobal.WeaponAttribute.keys() + BattleGlobal.SpecialAttribute.keys()
	hint = hint.join(a)
	#print(hint)
	for i in range(EffectNum):
		result.append({
			"name":"Effect_%d" % (i),
			"type":TYPE_INT,
			"hint":PROPERTY_HINT_ENUM,
			"hint_string":hint
		})
		result.append({
			"name":"Value_%d" % (i),
			"type":TYPE_INT,
		})
	updateValue()
	return result

func _get(property):
	if property.begins_with("Effect_"):
		var index = property.get_slice("_",1).to_int()
		return KeyList[index]
	if property.begins_with("Value_"):
		var index = property.get_slice("_",1).to_int()
		return ValueList[index]
	
func _set(property, value):
	if property.begins_with("Effect_"):
		if EffectDic == {}:
			BattleGlobal.initAttributeDic(EffectDic,BattleGlobal.AttType.all)
		var index = property.get_slice("_",1).to_int()
		KeyList[index] = value
		updateValue()
		return true
	if property.begins_with("Value_"):
		var index = property.get_slice("_",1).to_int()
		ValueList[index] = value
		updateValue()
	pass
func updateValue():
	for i in EffectDic:
		EffectDic[i] = 0
	for index in range(EffectNum):
		if KeyList[index] < BattleGlobal.BaseAttribute.keys().size():
			print(KeyList[index],":::",BattleGlobal.BaseAttribute.keys().size())
			if EffectDic.has(BattleGlobal.BaseAttribute.keys()[KeyList[index]]):
				EffectDic[BattleGlobal.BaseAttribute.keys()[KeyList[index]]] += ValueList[index]
		elif KeyList[index] - BattleGlobal.BaseAttribute.keys().size() < BattleGlobal.WeaponAttribute.keys().size():
			var tempIndex = KeyList[index] -BattleGlobal.BaseAttribute.keys().size()
			print(KeyList[index],":",tempIndex,":",BattleGlobal.WeaponAttribute.keys().size())
			if EffectDic.has(BattleGlobal.WeaponAttribute.keys()[tempIndex]):
				EffectDic[BattleGlobal.WeaponAttribute.keys()[tempIndex]] += ValueList[index]
		else:
			var tempIndex = KeyList[index] -BattleGlobal.BaseAttribute.keys().size() - BattleGlobal.WeaponAttribute.keys().size()
			print(KeyList[index],":",tempIndex,":",BattleGlobal.SpecialAttribute.keys().size())
			if EffectDic.has(BattleGlobal.SpecialAttribute.keys()[tempIndex]):
				EffectDic[BattleGlobal.SpecialAttribute.keys()[tempIndex]] += ValueList[index]
	for i in EffectDic:
		print(i,":",EffectDic[i])
		pass
	pass

