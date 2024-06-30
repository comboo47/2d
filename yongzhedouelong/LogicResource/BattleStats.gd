class_name BattleStats
extends Node

var curHp:float
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

@export var Stats:BasicStats
# Called when the node enters the scene tree for the first time.
func _ready():
	curMaxHp = Stats.MaxHealth
	curHp = curMaxHp
	atk = Stats.AttackPoint
	def = Stats.DefencePoint
	speed = Stats.MoveSpeed
	atkTime = Stats.AttackTime
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
