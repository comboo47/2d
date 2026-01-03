class_name E_Damage extends AttributeBuffEffect

func EffectGo():
	_compile_expression()
	var atk = source.GetAttributes().find_attribute(AttributeConfig.AttributeName.Atk).computed_value
	var armor = target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Armor).computed_value
	var dmg = _last_evaluation + atk - armor
	target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp).sub(dmg)
	pass
