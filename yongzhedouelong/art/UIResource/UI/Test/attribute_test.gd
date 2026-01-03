extends Control

@export var attributeConpunent:AttributeComponent
@onready var v_box_container: VBoxContainer = $VBoxContainer

func _ready() -> void:
	for att in attributeConpunent.attribute_set.attributes:
		var lab:Label = Label.new()
		lab.text = str(AttributeConfig.AttributeName.find_key(att.attribute_name)) + ":"+ str(att.computed_value)
		v_box_container.add_child(lab)
