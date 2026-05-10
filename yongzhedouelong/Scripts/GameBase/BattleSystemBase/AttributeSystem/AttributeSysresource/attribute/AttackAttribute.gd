class_name AttackAttribute extends Attribute

const attack_attribute_name = AttributeConfig.AttributeName.Atk

func custom_compute(_operated_value: float, _compute_params: Array[Attribute]) -> float:
	return _operated_value

func derived_from() -> Array[int]:
	return []
