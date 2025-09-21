class_name Attribute_HP
extends Attributes
const  attribute_hp_name = "HP"
const strength_attribute_name = "Strength"

@export var HpPerStrength = 5.0

func custom_compute(_custom_params:Array[Attributes]) ->float:
	var strength_attribute = _custom_params[0]
	return base_value + strength_attribute.get_value() * HpPerStrength
	
func dervied_from() -> Array[String]:
	return [
		strength_attribute_name,
	]
