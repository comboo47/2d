class_name GameplayFlowContext extends RefCounted

var source: BattleActor = null
var target: BattleActor = null
var skill: SkillBase = null
var buff: AttributeBuff = null
var level: Variant = null
var gameplay_event: GameplayEvent = null
var damage_request: DamageRequest = null
var stack: int = 0
var event_data: Dictionary = {}

func get_damage() -> float:
	if damage_request:
		return damage_request.amount
	return event_data.get("damage", 0.0)

func get_position() -> Vector2:
	if event_data.has("position"):
		return event_data["position"]
	if target:
		return target.global_position
	if source:
		return source.global_position
	return Vector2.ZERO

func get_skill_id() -> String:
	if skill:
		return skill.skill_id
	return event_data.get("skill_id", "")

func get_buff_id() -> String:
	if buff:
		return buff.buff_id
	return event_data.get("buff_id", "")

func set_damage(value: float) -> void:
	event_data["damage"] = value
	if damage_request:
		damage_request.amount = value

func set_position(pos: Vector2) -> void:
	event_data["position"] = pos

func bind_event(event: GameplayEvent) -> GameplayFlowContext:
	gameplay_event = event
	source = event.source
	target = event.target
	skill = event.skill
	buff = event.buff
	damage_request = event.damage_request
	event_data = event.event_data
	if buff:
		stack = buff.stack
	return self

static func create_simple(source_actor: BattleActor) -> GameplayFlowContext:
	var ctx := GameplayFlowContext.new()
	ctx.source = source_actor
	ctx.target = source_actor
	return ctx

static func create_attack(source_actor: BattleActor, target_actor: BattleActor, damage: float = 0.0) -> GameplayFlowContext:
	var ctx := GameplayFlowContext.new()
	ctx.source = source_actor
	ctx.target = target_actor
	ctx.event_data["damage"] = damage
	return ctx

static func create_at_position(pos: Vector2, source_actor: BattleActor = null) -> GameplayFlowContext:
	var ctx := GameplayFlowContext.new()
	ctx.source = source_actor
	ctx.event_data["position"] = pos
	return ctx

static func create_from_event(event: GameplayEvent) -> GameplayFlowContext:
	return GameplayFlowContext.new().bind_event(event)
