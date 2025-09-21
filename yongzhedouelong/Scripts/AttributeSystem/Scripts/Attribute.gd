class_name Attributes
extends Resource

signal attribute_changged(attribute:Attributes)

@export var attribute_name:String

@export var base_value :=0.0:set = setter_base_value

##公式计算的结果
var current_value := 0.0

var modifier:Array[AttributeModifier] = []

var attribute_set:AttributeSet


func apply_modifier(mod:AttributeModifier):
	modifier.append(mod)
	current_value = _compute_value()

func remove_modifier(mod:AttributeModifier):
	modifier.erase(mod)
	_compute_value()
#数值计算
func _compute_value()->float:
	var compute_result = 0.0
	var dervied_attribute :Array[Attributes]= []
	var dervied_attribute_names = derived_from()
	for _name in dervied_attribute_names:
		var _attribute = attribute_set.find_attribute(_name)
		dervied_attribute.append(_attribute)
	
	compute_result = custom_compute(dervied_attribute)
	for mod in modifier:
		compute_result = mod.operate(compute_result)
	return compute_result

func setter_base_value(v):
	base_value = v
	current_value = v

func setter_current_value(v):
	current_value = v
	attribute_changged.emit(self)

##自定义公式
func custom_compute(_compute_params:Array[Attributes])->float:
	return base_value
	
func derived_from() -> Array[String]:
	return []
