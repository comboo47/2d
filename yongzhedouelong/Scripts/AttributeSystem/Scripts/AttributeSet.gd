class_name AttributeSet
extends Resource

@export var attributes:Array[Attributes]:set = setter_attribute

var attributes_runtime_dict:Dictionary[String,Attributes]={}


func setter_attribute(v):
	attributes = v
	attributes_runtime_dict.clear()
	for attr in attributes:
		if attributes_runtime_dict.has(attr.attributes_name):
			push_warning("AttributeSet 有重复属性名称 %s" % attr.attributes_name)
			continue
		var duplicated_attribute = attr.duplicate(true) as Attributes
		duplicated_attribute.attribute_set = self
		attributes_runtime_dict[attr.attributes_name] = duplicated_attribute
		duplicated_attribute.attribute_changed.connect(_on_attribute_changed)

func find_attribute(attribute_name:String)->Attributes:
	if attributes_runtime_dict.has(attribute_name):
		return	attributes_runtime_dict[attribute_name]
	push_error("AttributeSet 未找到指定属性 %s" % attribute_name)
	return null


func _on_attribute_changed(attribute:Attributes):
	pass
