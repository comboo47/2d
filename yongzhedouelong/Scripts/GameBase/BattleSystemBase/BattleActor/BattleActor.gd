extends CharacterBody2D
class_name BattleActor

@export var Eattribute:AttributeComponent
var attribute
var buffManager:BuffManager = BuffManager.new()

func _enter_tree() -> void:
	self.add_child(buffManager)

func SetAttributes(atc:AttributeComponent) -> void:
	attribute = atc
	self.set_meta("Attribute",attribute)

func GetAttributes() -> AttributeComponent:
	if attribute != null:
		return attribute
	
	else:
		attribute = Eattribute
		return attribute
