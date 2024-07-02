class_name BattleStats
extends Node

var curHp:float
var curHpAdd:float
var curMaxHp:float

var atk:float
var atkAdd:float
var atkMul:float

var def:float
var defAdd:float
var defMul:float

var speed:float
var speedAdd:float
var speedMul:float

var atkTime:float
var atkTimeAdd:float
var atkTimeMul:float

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

@export var currentLevel:int = 1
@export var Stats:BasicStats
@export var equipMent:Array[Equip_Item]
# Called when the node enters the scene tree for the first time.
func _ready():
	initBasicAttr()
	initEquipAttribute()
	pass # Replace with function body.

func initBasicAttr():
	curMaxHp = Stats.MaxHealth + currentLevel * Stats.upHealth
	curHp = curMaxHp
	atk = Stats.AttackPoint + currentLevel * Stats.upAttack
	def = Stats.DefencePoint + currentLevel * Stats.upDefencePoint
	speed = Stats.MoveSpeed + currentLevel * Stats.upMoveSpeed
	atkTime = Stats.AttackTime + currentLevel * Stats.upAttackTime
# Called every frame. 'delta' is the elapsed time since the previous frame.
func initEquipAttribute():
	for i:Equip_Item in equipMent:
		addEquip(i)

func addEquip(equip:Equip_Item):
		curHpAdd += float(equip.health/10000)
		atkAdd += float(equip.attack/10000)
		defAdd += float(equip.armor/10000)
		speed += float(equip.MoveSpeed/10000)
		atkTime += float(equip.AttackSpeed/10000)
func removeEquip(equip:Equip_Item):
		curHpAdd -= float(equip.health/10000)
		atkAdd -= float(equip.attack/10000)
		defAdd -= float(equip.armor/10000)
		speed -= float(equip.MoveSpeed/10000)
		atkTime -= float(equip.AttackSpeed/10000)	

func _process(delta):
	pass
