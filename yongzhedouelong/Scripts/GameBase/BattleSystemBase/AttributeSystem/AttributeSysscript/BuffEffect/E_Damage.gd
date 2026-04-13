class_name E_Damage extends AttributeBuffEffect

func EffectGo():
	_compile_expression()

	# 防御性检查：确保 source 和 target 存在
	if source == null or target == null:
		push_warning("E_Damage: source 或 target 为 null，无法计算伤害")
		return

	var source_attrs = source.GetAttributes()
	var target_attrs = target.GetAttributes()

	if source_attrs == null or target_attrs == null:
		push_warning("E_Damage: 无法获取属性组件")
		return

	var atk_attr = source_attrs.find_attribute(AttributeConfig.AttributeName.Atk)
	var armor_attr = target_attrs.find_attribute(AttributeConfig.AttributeName.Armor)
	var hp_attr = target_attrs.find_attribute(AttributeConfig.AttributeName.Hp)

	if atk_attr == null or armor_attr == null or hp_attr == null:
		push_warning("E_Damage: 无法找到必要的属性")
		return

	var atk = atk_attr.computed_value
	var armor = armor_attr.computed_value
	var dmg = _last_evaluation + atk - armor
	hp_attr.sub(dmg)
