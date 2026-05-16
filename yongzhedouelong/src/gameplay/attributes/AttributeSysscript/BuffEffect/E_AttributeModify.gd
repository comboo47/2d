
class_name E_AttributeModify extends AttributeBuffEffect


@export var attributeType:AttributeConfig.AttributeName

func EffectGo():
	var attribute:Attribute = target.GetAttributes().find_attribute(attributeType)
	attribute.add(self._last_evaluation)
	
func EffectRemove():
	var attribute:Attribute = target.GetAttributes().find_attribute(attributeType)
	attribute.sub(self._last_evaluation)
