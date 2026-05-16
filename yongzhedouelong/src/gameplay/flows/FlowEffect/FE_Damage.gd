class_name FE_Damage extends FlowEffectBase

@export var base_damage: float = 10.0
@export var use_attack_bonus: bool = true
@export var use_armor_reduction: bool = true
@export var damage_expression: String = ""
@export var damage_tags: Array[String] = []

func apply(context: GameplayFlowContext) -> void:
	if context == null or context.target == null:
		return

	var request := DamageRequest.new()
	request.source = context.source
	request.target = context.target
	request.skill = context.skill
	request.buff = context.buff
	request.amount = _base_amount(context)
	request.formula = damage_expression
	request.tags = damage_tags.duplicate()
	request.event_data = context.event_data
	context.damage_request = request

	var result := DamageResolver.resolve(request)
	context.event_data["actual_damage"] = result.final_amount

	var ui_manager := _get_ui_manager()
	if result.final_amount > 0.0 and ui_manager and ui_manager.has_method("can_show_damage") and ui_manager.can_show_damage():
		ui_manager.show_damage(context.target, result.final_amount)

func _base_amount(context: GameplayFlowContext) -> float:
	var damage := base_damage
	if use_attack_bonus and context.source:
		var atk_attr := context.source.GetAttributes().find_attribute(AttributeConfig.AttributeName.Atk)
		if atk_attr:
			damage += atk_attr.get_value()
	if use_armor_reduction and context.target:
		var armor_attr := context.target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Armor)
		if armor_attr:
			damage -= armor_attr.get_value()
	return max(0.0, damage)

func get_description() -> String:
	return "Deal %.1f damage" % base_damage

func _get_ui_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("UIManager")
