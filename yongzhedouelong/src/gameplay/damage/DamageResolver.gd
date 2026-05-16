class_name DamageResolver extends RefCounted

static func resolve(request: DamageRequest) -> DamageResult:
	var result := DamageResult.new()
	result.request = request
	if request == null or request.target == null:
		return result

	var requested_event := GameplayEvent.create(GameplayEvent.EventType.DAMAGE_REQUESTED, request.source, request.target)
	requested_event.skill = request.skill
	requested_event.buff = request.buff
	requested_event.damage_request = request
	requested_event.event_data = request.event_data
	GameplayEventBus.emit_event(requested_event)

	result.final_amount = max(0.0, request.evaluate_amount())

	var hp_attr := request.target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp)
	if hp_attr:
		result.target_hp_before = hp_attr.get_value()
		hp_attr.sub(result.final_amount)
		result.target_hp_after = hp_attr.get_value()

	var applied_event := GameplayEvent.create(GameplayEvent.EventType.DAMAGE_APPLIED, request.source, request.target)
	applied_event.skill = request.skill
	applied_event.buff = request.buff
	applied_event.damage_request = request
	applied_event.event_data = request.event_data.duplicate()
	applied_event.event_data["final_amount"] = result.final_amount
	applied_event.event_data["target_hp_before"] = result.target_hp_before
	applied_event.event_data["target_hp_after"] = result.target_hp_after
	GameplayEventBus.emit_event(applied_event)

	return result
