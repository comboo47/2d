class_name HealthAttribute extends Attribute

const healthEnum = AttributeConfig.AttributeName.Hp

func post_attribute_value_changed(_value: float) -> float:
	var max_health_attribute = attribute_set.find_attribute(healthEnum)
	if is_instance_valid(max_health_attribute):
		_value = clamp(_value, 0.0, max_health_attribute.get_value())
	return _value


func custom_compute(operated_value: float, _compute_params: Array[Attribute]) -> float:
	if _compute_params.size() >0:
		var max_health_attribute = _compute_params[0]
		if max_health_attribute:
			return clamp(operated_value, 0.0, max_health_attribute.get_value())
		else:
			return 0
	else:
		return operated_value


## 属性依赖列表
## @ return: 返回依赖属性的名称数组
func derived_from() -> Array[int]:
	return[
	]
