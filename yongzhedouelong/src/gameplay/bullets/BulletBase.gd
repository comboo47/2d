class_name BulletBase extends RigidBody2D
## 子弹基类：抽出 bow_bullet / bottle_bullet 共享的伤害结算、销毁、定义应用与运动钩子。
##
## 设计约束（保持零回归）：
## - 子类保留自己在 .tscn 里连接的信号方法（_on_body_entered / _on_bullet_hit /
##   _releaseSelf）与各自的命中分发逻辑——本基类只提供共享实现，不强行统一。
## - speed 仍由各子类声明（默认值不同：bow=250 / bottle=300），weapon_base._ready
##   会实例化子弹读取 speed 作为 base_speed 默认，统一到基类会让 bottle 退化。
## - 无 BulletDefinition 时（_definition == null）行为与改造前完全一致：
##   _motion 为 null、pierce/aoe 不生效。

## 命中附加的状态 Buff ID（原各子类 @export，上移去重）。
@export var damagebuffid: String = ""
## 基础伤害（注入自 BulletManager / BulletDefinition）。
@export var base_damage: float = 10.0

## 发射者（由 BulletManager 注入）。
var bulletOwner: BattleActor
## 发射武器引用（由 BulletManager 注入，供命中触发 ON_HIT/ON_KILL）。
var source_weapon = null

## 当前应用的子弹定义（可空）。
var _definition: BulletDefinition = null
## 运动策略实例（可空；非空时每物理帧驱动）。
var _motion: BulletMotionBase = null
## 剩余穿透次数。
var _pierce_left: int = 0

## 特质容器（可空；仅当 definition.traits 非空时创建）。
var _traits: TraitContainer = null

## 应用子弹定义：设置伤害/外观/生命周期/重力/运动策略。
## 由 BulletManager 在实例化并设好初速后调用（不改初速，避免双重设速）。
func apply_definition(def: BulletDefinition) -> void:
	_definition = def
	if def == null:
		return
	base_damage = def.base_damage
	damagebuffid = def.damage_buff_id
	if "speed" in self:
		set("speed", def.speed)
	_pierce_left = def.pierce_count
	if has_node("Timer"):
		$Timer.wait_time = def.lifetime
	if has_node("AnimatedSprite2D"):
		var spr := $AnimatedSprite2D
		if def.modulate != Color.WHITE:
			spr.modulate = def.modulate
		if def.sprite_frames != null:
			spr.sprite_frames = def.sprite_frames
	if def.gravity_scale_override >= 0.0:
		gravity_scale = def.gravity_scale_override
	if not String(def.motion_key).is_empty():
		_motion = BulletMotionRegistry.create(def.motion_key)
		if _motion != null:
			_motion.setup(self, def)
	# 特质：仅当定义带 traits 时建容器并加载（无 traits 时 _traits 保持 null，行为不变）
	if "traits" in def and def.traits != null and not def.traits.is_empty():
		_traits = TraitContainer.new(self)
		for tid in def.traits:
			_traits.add_trait_by_id(tid)
		_dispatch_trait_event(GameplayEvent.EventType.BULLET_SPAWNED)

func _physics_process(delta: float) -> void:
	if _motion != null:
		_motion.process(self, delta)
	if _traits != null:
		_traits.tick(delta)

## 对单个目标结算伤害（保持原 resolve_bullet_hit 路径不变）。
func hurt_somebody(body: Node) -> void:
	if body.has_method("_beHurt"):
		BattleManager.resolve_bullet_hit(bulletOwner, body, base_damage, "", damagebuffid, source_weapon)

## 销毁子弹。
func _releaseSelf() -> void:
	if _traits != null:
		_dispatch_trait_event(GameplayEvent.EventType.BULLET_RELEASED)
		_traits.stop_all()
	queue_free()

## 数据驱动的通用命中入口（供需要 pierce/aoe 的子弹直接调用）。
## aoe_radius>0 且场景含 BoomArea → 范围结算；否则单体结算。穿透耗尽后销毁。
func _on_hit(body: Node) -> void:
	if _definition != null and _definition.aoe_radius > 0.0 and has_node("BoomArea"):
		for b in $BoomArea.get_overlapping_bodies():
			hurt_somebody(b)
	else:
		hurt_somebody(body)
	# 特质命中钩子：若特质否决销毁（如弹射），子弹存活，不消耗 pierce
	var r = _dispatch_trait_event(GameplayEvent.EventType.BULLET_HIT, body)
	if r != null and r.veto_release:
		return
	if not _consume_pierce():
		_releaseSelf()

## 消耗一次穿透；返回 true 表示子弹应存活（已穿透），false 表示应销毁。
func _consume_pierce() -> bool:
	if _pierce_left > 0:
		_pierce_left -= 1
		return true
	return false

## 分发一个子弹生命周期事件给特质容器。无特质则返回 null（调用方据此走原路径）。
func _dispatch_trait_event(type: int, hit_body: Node = null) -> TraitContainer.TraitDispatchResult:
	if _traits == null:
		return null
	var evt := GameplayEvent.create(type, bulletOwner, null)
	if hit_body != null:
		evt.event_data["hit_body"] = hit_body
	return _traits.dispatch(evt)
