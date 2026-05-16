class_name DamageRequest extends RefCounted

var source: BattleActor = null
var target: BattleActor = null
var skill: SkillBase = null
var buff: AttributeBuff = null
var amount: float = 0.0
var formula: String = ""
var tags: Array[String] = []
var event_data: Dictionary = {}

func evaluate_amount() -> float:
	if formula.is_empty():
		return amount

	var expression := Expression.new()
	var parse_result := expression.parse(
		formula,
		["source", "target", "skill", "buff", "event_data", "damage", "level", "stack"]
	)
	if parse_result != OK:
		push_error("DamageRequest formula parse error: %s" % expression.get_error_text())
		return amount

	var skill_level := 0
	if skill:
		skill_level = skill.skill_level
	var buff_stack := 0
	if buff:
		buff_stack = buff.stack

	var result = expression.execute(
		[source, target, skill, buff, event_data, self, skill_level, buff_stack],
		self
	)
	if expression.has_execute_failed():
		push_error("DamageRequest formula execution error: %s" % expression.get_error_text())
		return amount
	if result is int or result is float:
		return float(result)
	return amount

func source_attr(attribute_name: String) -> float:
	return _actor_attr(source, attribute_name)

func target_attr(attribute_name: String) -> float:
	return _actor_attr(target, attribute_name)

func event_value(key: String, default_value: Variant = 0.0) -> Variant:
	return event_data.get(key, default_value)

func has_tag(tag: String) -> bool:
	return tags.has(tag)

func _actor_attr(actor: BattleActor, attribute_name: String) -> float:
	if actor == null or actor.GetAttributes() == null:
		return 0.0
	var enum_value := _attribute_name_to_enum(attribute_name)
	if enum_value == -1:
		return 0.0
	var attr := actor.GetAttributes().find_attribute(enum_value)
	if attr == null:
		return 0.0
	return attr.get_value()

func _attribute_name_to_enum(attribute_name: String) -> int:
	match attribute_name.to_lower():
		"hp", "health", "max_hp":
			return AttributeConfig.AttributeName.Hp
		"atk", "attack":
			return AttributeConfig.AttributeName.Atk
		"armor", "defense":
			return AttributeConfig.AttributeName.Armor
		"mana":
			return AttributeConfig.AttributeName.Mana
		"crit":
			return AttributeConfig.AttributeName.Crit
		_:
			return -1
