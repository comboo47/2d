extends Resource

class_name BattleEffect
@export_group("EffectSetting")
@export var periodTime:float
@export var totalTime:float

@export_group("Effect")
@export var EffectList:Array[BattleGlobal.Attribute]


func _init(t1,t2,t3):
	periodTime = t1
	totalTime = t2
	
