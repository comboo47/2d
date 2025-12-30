class_name AttributeModify extends AttributeBuffEffect


@export var attributeType:AttributeConfig.AttributeName
var attribute:Attribute = target.attribute.find_attribute(attributeType)

func EffectGo():
	attribute.add(self._last_evaluation)
	
func EffectRemove():
	attribute.sub(self._last_evaluation)
