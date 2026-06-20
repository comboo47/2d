class_name FlowActions
## Flow 通用动作库（第八期）。
## gameplay 编排的「动作 API」——flow 脚本通过 GameplayFlowBase 的薄方法 self.调，
## 底层全部委托到这里的静态方法。无状态、可单测、EffectBase 也可复用。
##
## 设计原则：
## - 伤害收口铁律：deal_damage / modify_attr(Hp+SUB) 必须走 DamageResolver.resolve，不绕过。
## - 这些动作逻辑由旧的 FE_* effect 原样搬运而来（第八期把数据拼装层换成脚本动作库）。
##
## opts 为 Dictionary，缺省值见各方法注释。

#region 发射子弹
## 发射子弹（含散射）。opts:
##   bullet:PackedScene（必填）, position:Vector2(缺省 ctx.get_position()),
##   direction:Vector2(缺省 RIGHT), speed:float(缺省 250), bullet_type:int(缺省 0),
##   owner:BattleActor(缺省 ctx.source), spread_count:int(缺省 1), spread_angle:float(缺省 0)
## 返回是否至少发出一发。
static func fire_projectile(ctx: GameplayFlowContext, opts: Dictionary = {}) -> bool:
	if ctx == null:
		return false
	var bullet = opts.get("bullet", ctx.event_data.get("bullet", null))
	if bullet == null:
		push_warning("FlowActions.fire_projectile: 缺少 'bullet' PackedScene")
		return false

	var position: Vector2 = opts.get("position", ctx.get_position())
	var direction: Vector2 = opts.get("direction", ctx.event_data.get("direction", Vector2.RIGHT))
	var speed: float = opts.get("speed", ctx.event_data.get("speed", 250.0))
	var bullet_type: int = opts.get("bullet_type", ctx.event_data.get("bullet_type", 0))
	var owner = opts.get("owner", ctx.source)
	var spread_count: int = opts.get("spread_count", 1)
	var spread_angle: float = opts.get("spread_angle", 0.0)

	var bullet_manager := _get_node(ctx, "BulletManager")
	if bullet_manager == null:
		push_warning("FlowActions.fire_projectile: 找不到 BulletManager")
		return false

	for d in _spread_directions(direction, spread_count, spread_angle):
		bullet_manager.handle_bullet_spawn(bullet, position, d, speed, bullet_type, owner)
	return true

## 计算散射方向列表（以 center 为中心扇形均布）。
static func _spread_directions(center: Vector2, spread_count: int, spread_angle: float) -> Array:
	if spread_count <= 1 or spread_angle <= 0.0:
		return [center]
	var dirs := []
	var start := -spread_angle * 0.5
	var step := spread_angle / float(spread_count - 1)
	for i in spread_count:
		dirs.append(center.rotated(start + step * i))
	return dirs
#endregion

#region 伤害（走 DamageResolver 收口）
## 造成伤害。opts:
##   base:float(缺省 10), use_atk:bool(缺省 true), use_armor:bool(缺省 true),
##   formula:String(缺省 ""), tags:Array[String](缺省 [])
## 攻击/护甲加成折进 amount；公式走 DamageRequest.formula。返回 DamageResult。
static func deal_damage(ctx: GameplayFlowContext, opts: Dictionary = {}):
	if ctx == null or ctx.target == null:
		return null

	var base: float = opts.get("base", 10.0)
	var use_atk: bool = opts.get("use_atk", true)
	var use_armor: bool = opts.get("use_armor", true)

	var amount := base
	if use_atk and ctx.source:
		var atk_attr = ctx.source.GetAttributes().find_attribute(AttributeConfig.AttributeName.Atk)
		if atk_attr:
			amount += atk_attr.get_value()
	if use_armor and ctx.target:
		var armor_attr = ctx.target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Armor)
		if armor_attr:
			amount -= armor_attr.get_value()
	amount = max(0.0, amount)

	var request := DamageRequest.new()
	request.source = ctx.source
	request.target = ctx.target
	request.skill = ctx.skill
	request.buff = ctx.buff
	request.amount = amount
	request.formula = opts.get("formula", "")
	var tags_opt = opts.get("tags", [])
	var typed_tags: Array[String] = []
	for t in tags_opt:
		typed_tags.append(str(t))
	request.tags = typed_tags
	request.event_data = ctx.event_data
	ctx.damage_request = request

	var result := DamageResolver.resolve(request)
	ctx.event_data["actual_damage"] = result.final_amount

	var ui = _get_node(ctx, "UIManager")
	if result.final_amount > 0.0 and ui and ui.has_method("can_show_damage") and ui.can_show_damage():
		ui.show_damage(ctx.target, result.final_amount)
	return result
#endregion

#region 属性修改
## 修改属性。opts: attr:AttributeConfig.AttributeName(必填), op(ModifyOp), value:float
## ModifyOp: "add"/"sub"/"set"/"mult"。对 Hp 的 sub 走 DamageResolver（伤害收口）。
## 注意：面板属性的可逆叠加用 ModifierEffect（修改源栈），本动作是 flow 即时改。
static func modify_attr(ctx: GameplayFlowContext, opts: Dictionary = {}) -> void:
	if ctx == null or ctx.target == null:
		return
	var attr_comp = ctx.target.GetAttributes()
	if attr_comp == null:
		return
	var attribute_type: int = opts.get("attr", AttributeConfig.AttributeName.Hp)
	var op: String = opts.get("op", "add")
	var value: float = opts.get("value", 0.0)

	# 伤害收口：对 Hp 的减法视为伤害，走 DamageResolver。
	if attribute_type == AttributeConfig.AttributeName.Hp and op == "sub":
		var request := DamageRequest.new()
		request.source = ctx.source
		request.target = ctx.target
		request.skill = ctx.skill
		request.buff = ctx.buff
		request.amount = value
		request.tags = ["flow", "modify_attr"]
		DamageResolver.resolve(request)
		return

	var attr = attr_comp.find_attribute(attribute_type)
	if attr == null:
		return
	match op:
		"add": attr.add(value)
		"sub": attr.sub(value)
		"set": attr.set_value(value)
		"mult": attr.mult(value)
#endregion

#region 应用 Buff
## 应用 Buff。buff_or_id 可为 String（buff_id，走 DataRegistry）或 AttributeBuff 资源。
## opts: use_source_owner:bool(缺省 true), apply_to_source:bool(缺省 false)
static func apply_buff(ctx: GameplayFlowContext, buff_or_id, opts: Dictionary = {}) -> void:
	if ctx == null:
		return
	var use_source_owner: bool = opts.get("use_source_owner", true)
	var apply_to_source: bool = opts.get("apply_to_source", false)
	var target = ctx.source if apply_to_source else ctx.target
	if target == null:
		return

	if buff_or_id is String:
		var buff_source = ctx.source if use_source_owner else null
		var bm = _get_node(ctx, "BattleManager")
		if bm:
			bm.ApplyBuff(buff_source, target, buff_or_id)
	elif buff_or_id is AttributeBuff:
		if target.buffManager == null:
			return
		var source = ctx.source if use_source_owner else target
		var runtime_buff = target.buffManager.apply_buff(buff_or_id, source, target)
		if runtime_buff:
			ctx.buff = runtime_buff
			ctx.event_data["applied_buff_id"] = runtime_buff.get_runtime_id()
#endregion

#region 生成实体
## 生成实体。opts: scene:PackedScene(必填), offset:Vector2, as_child_of_target:bool,
##   init_data:Dictionary
static func spawn_entity(ctx: GameplayFlowContext, opts: Dictionary = {}) -> Node:
	if ctx == null:
		return null
	var entity_scene = opts.get("scene", null)
	if entity_scene == null:
		push_warning("FlowActions.spawn_entity: 缺少 'scene'")
		return null
	var entity = entity_scene.instantiate()
	if entity == null:
		return null
	entity.global_position = ctx.get_position() + opts.get("offset", Vector2.ZERO)

	if opts.get("as_child_of_target", false) and ctx.target:
		ctx.target.add_child(entity)
	else:
		var tree := _get_tree(ctx)
		if tree and tree.current_scene:
			tree.current_scene.add_child(entity)
	var init_data: Dictionary = opts.get("init_data", {})
	if entity.has_method("init") and not init_data.is_empty():
		entity.init(init_data)
	return entity
#endregion

#region 特效
## 播放特效。opts: vfx_type:VfxConfig.VfxType(必填), offset:Vector2, follow_target:bool
static func play_vfx(ctx: GameplayFlowContext, opts: Dictionary = {}) -> void:
	if ctx == null:
		return
	var vfx = _get_node(ctx, "VfxManager")
	if vfx == null:
		return
	var vfx_type = opts.get("vfx_type", VfxConfig.VfxType.HIT_IMPACT)
	if not vfx.is_vfx_available(vfx_type):
		return
	var offset: Vector2 = opts.get("offset", Vector2.ZERO)
	if opts.get("follow_target", false) and ctx.target:
		vfx.play_vfx_follow(vfx_type, ctx.target, offset)
	else:
		vfx.play_vfx(vfx_type, ctx.get_position() + offset)
#endregion

#region 完成通知
## 调用 ctx.event_data["on_finish"] 回调并清除（幂等：只回调一次）。
## 宿主（如 actor 死亡门控）把 Callable 塞进 event_data["on_finish"]，flow 跑完调本动作通知。
static func finish(ctx: GameplayFlowContext) -> void:
	if ctx == null or not ctx.event_data.has("on_finish"):
		return
	var cb = ctx.event_data["on_finish"]
	ctx.event_data.erase("on_finish")
	if cb is Callable and cb.is_valid():
		cb.call()
#endregion

#region 内部
static func _get_tree(ctx: GameplayFlowContext) -> SceneTree:
	if ctx and ctx.source and ctx.source.is_inside_tree():
		return ctx.source.get_tree()
	return Engine.get_main_loop() as SceneTree

static func _get_node(ctx: GameplayFlowContext, node_name: String) -> Node:
	var tree := _get_tree(ctx)
	if tree == null:
		return null
	return tree.root.get_node_or_null(node_name)
#endregion
