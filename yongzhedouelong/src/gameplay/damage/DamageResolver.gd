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

	var was_dead: bool = request.target.is_dead
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

	# === ACTOR 生命周期收口（DamageResolver 全权负责）===
	# 造成了伤害 → 受击：广播 ACTOR_HIT + 驱动目标受伤 Flow。
	if result.final_amount > 0.0:
		var hit_event := GameplayEvent.create(GameplayEvent.EventType.ACTOR_HIT, request.source, request.target)
		hit_event.skill = request.skill
		hit_event.buff = request.buff
		hit_event.damage_request = request
		hit_event.event_data = {
			"damage": result.final_amount,
			"target_hp_before": result.target_hp_before,
			"target_hp_after": result.target_hp_after,
		}
		GameplayEventBus.emit_event(hit_event)
		request.target.trigger_hit_flow(result.final_amount, request.source)

	# HP≤0 且本次之前未死 → 死亡判定（唯一收口点）：
	# 广播 ACTOR_DIED（死者视角，killer 在 event_data）+ ACTOR_KILL（击杀者视角）+ 驱动死亡。
	if hp_attr and result.target_hp_after <= 0.0 and not was_dead and not request.target.is_dead:
		var died_event := GameplayEvent.create(GameplayEvent.EventType.ACTOR_DIED, request.target, request.target)
		died_event.event_data = {"killer": request.source}
		GameplayEventBus.emit_event(died_event)

		if request.source != null:
			var kill_event := GameplayEvent.create(GameplayEvent.EventType.ACTOR_KILL, request.source, request.target)
			GameplayEventBus.emit_event(kill_event)
			request.source.trigger_kill_flow(request.target)

		request.target.kill(request.source)

	return result
