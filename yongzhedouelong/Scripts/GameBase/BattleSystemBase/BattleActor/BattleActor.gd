extends CharacterBody2D
class_name BattleActor

var attribute
var buffManager:BuffManager = BuffManager.new()


func SetAttributes(atc:AttributeComponent) -> void:
	attribute = atc
	self.set_meta("Attribute",attribute)

func GetAttributes() -> AttributeComponent:
	if attribute != null:
		return attribute
	elif self.get_meta("Attribute")!=null:
		return self.get_meta("Attribute")
	else:
		return null
