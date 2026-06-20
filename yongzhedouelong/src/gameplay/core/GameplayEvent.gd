class_name GameplayEvent extends RefCounted

enum EventType {
	LEVEL_START,
	LEVEL_END,
	ACTOR_SPAWNED,
	ACTOR_DIED,
	ACTOR_HIT,
	ACTOR_KILL,
	SKILL_USED,
	BUFF_APPLIED,
	BUFF_REMOVED,
	BUFF_TICK,
	BUFF_STACK_CHANGED,
	DAMAGE_REQUESTED,
	DAMAGE_APPLIED,
	# 武器输入语义事件（由 FlowRuntime 按武器 input_mode 翻译原始输入后发出，
	# 供常驻开火 Flow 在 on_event 中响应）
	WEAPON_FIRE_PRESSED,   # 开火键按下瞬间
	WEAPON_FIRE_HELD,      # 开火键持续按住（每帧/按节奏）
	WEAPON_FIRE_RELEASED,  # 开火键松开瞬间
	# 子弹生命周期事件（由 BulletBase 在对应代码点分发给子弹自己的 TraitContainer，
	# 不走全局总线——子弹量大短命、命中是子弹私有事件）
	BULLET_SPAWNED,        # 子弹应用定义/生成后
	BULLET_PROCESS,        # 子弹每物理帧
	BULLET_HIT,            # 子弹命中结算后（特质可否决销毁）
	BULLET_RELEASED,       # 子弹销毁前
}

var event_type: EventType = EventType.LEVEL_START
var source: BattleActor = null
var target: BattleActor = null
var skill: SkillBase = null
var buff: AttributeBuff = null
var damage_request: DamageRequest = null
var event_data: Dictionary = {}

static func create(type: EventType, source_actor: BattleActor = null, target_actor: BattleActor = null) -> GameplayEvent:
	var event := GameplayEvent.new()
	event.event_type = type
	event.source = source_actor
	event.target = target_actor
	return event

func to_context() -> GameplayFlowContext:
	return GameplayFlowContext.create_from_event(self)
