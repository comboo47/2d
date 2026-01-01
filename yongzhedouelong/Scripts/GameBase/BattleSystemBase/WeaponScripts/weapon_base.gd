extends Node2D

class_name weapon_base

@export var bullet: PackedScene
#@export var state:BattleStats
@export var ownerCharacter:CharacterBody2D
signal fired_bullet(bullet,_position,_rotation,direction,type)

var targetPosition = Vector2()

func realFire(firebullet,firePosition:Vector2,fireRotation:Vector2,fireVelocity:Vector2,bulletType:int):
	emit_signal("fired_bullet",firebullet,firePosition,fireRotation,fireVelocity,bulletType)
	
