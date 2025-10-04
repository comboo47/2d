extends CharacterBody2D
class_name BattleActor

var attribute:AttributeComponent

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
