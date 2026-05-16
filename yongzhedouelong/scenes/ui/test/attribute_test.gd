extends Control

@export var attributeConpunent:AttributeComponent
@onready var v_box_container: VBoxContainer = $VBoxContainer
var dic = {}
func _ready() -> void:
	for att in attributeConpunent.attribute_set.attributes:
		var lab:Label = Label.new()
		
		lab.text = str(AttributeConfig.AttributeName.find_key(att.attribute_name)) + ":"+ str(att.computed_value)
		dic[AttributeConfig.AttributeName.find_key(att.attribute_name)] = lab
		v_box_container.add_child(lab)
	if attributeConpunent.find_attribute(AttributeConfig.AttributeName.Hp):
		attributeConpunent.find_attribute(AttributeConfig.AttributeName.Hp).attribute_changed.connect(attributeChanged)
func attributeChanged(_att:Attribute,_oldvalue:float,_newvalue:float)->void:
	if dic.has(AttributeConfig.AttributeName.find_key(_att.attribute_name)):
		dic[AttributeConfig.AttributeName.find_key(_att.attribute_name)].text = str(AttributeConfig.AttributeName.find_key(_att.attribute_name)) + ":"+ str(_newvalue)
	
	
