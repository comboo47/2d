extends Node
var pokerWaitDropDic:Array
var pokerDropedDic:Array
var dropDic:Dictionary
@export var Poker: PackedScene

func _ready():
	for i in range(1,14):
		for j in range(0,4):
			pokerWaitDropDic.append(Vector2(i,j))
	dropDic[1001] = Vector2(5,1)
	pass

func getDropItem(droperID)->Vector2:
	if dropDic.has(droperID):
		return dropDic[1001]
	else:
		return Vector2(0,0)
	pass

func dropPoker(droper:Node):
	var dropItem = Vector2(0,0)
	var poker = Poker.instantiate()
	var number
	var flower
	var randomPoker = pokerWaitDropDic.pick_random()
	number = randomPoker.x
	flower = randomPoker.y
	if droper.has_method("getID"):
		var droperID = droper.getID()
		dropItem = getDropItem(droperID)
	if dropItem != Vector2(0,0):
		for i in pokerWaitDropDic:
			print(i)
			if i == dropItem:
				number = i.x
				flower = i.y
				dropDicOperate(i)
	dropDicOperate(Vector2(number,flower))
	poker.number = number
	poker.flower = flower
	poker.position = droper.global_position
	add_child(poker)
	print("poker:",poker.global_position,"droper:",droper.global_position)
		
func dropDicOperate(dropItem:Vector2):
	pokerDropedDic.append(dropItem)
	pokerWaitDropDic.erase(dropItem)
	if(pokerWaitDropDic.size() == 0):
		for i in pokerDropedDic:
			pokerWaitDropDic.append(i)
		pokerDropedDic.clear()
		
