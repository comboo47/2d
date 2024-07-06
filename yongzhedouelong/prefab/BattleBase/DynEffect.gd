@tool
extends Resource
class_name DynEffect

var KeyList = PackedInt32Array([0,0,0,0,0,0,0,0,0,0,0,0,0])
var ValueList = PackedInt32Array([0,0,0,0,0,0,0,0,0,0,0,0,0])

@export_group("Effects")
@export var EffectNum = 0:
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
	var a = BattleGlobal.DyAttr.keys()
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
			EffectDic = BattleGlobal.initDynamicAttrDic(EffectDic)
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
		if EffectDic.has(BattleGlobal.DyAttr.keys()[KeyList[index]]):
			EffectDic[BattleGlobal.DyAttr.keys()[KeyList[index]]] += ValueList[index]
	for i in EffectDic:
		print(i,":",EffectDic[i])
		pass
	pass

