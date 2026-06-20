extends Node2D
## 通用武器驱动节点（第三期）。替代 weapon_base + 三个硬编码子类。
##
## 职责（仅"伸进场景的手脚"，零武器特性逻辑）：
##   1. 持有 WeaponDefinition；装备时按 input_bindings 给 actor 加开火 skill + 建节奏机。
##   2. 每帧轮询输入源算 press/release 边沿喂节奏机，到点门控（能量）后激活 skill。
##   3. 提供 Marker2D 发射点、Sprite 朝向、能量信号。
##
## 第十三期：旧的常驻 fire_flow 路径（经 FlowRuntime）已删——开火统一走 input_bindings→skill。
##
## 兼容契约：实现与旧 weapon_base 相同的节点接口（owner_actor / on_weapon_enter /
## on_weapon_exit / hold_fire / fire），使 WeaponRoot/Player 无需改动即可驱动它。

@export var definition: WeaponDefinition
@export var owner_actor: BattleActor

@onready var marker: Marker2D = $Marker2D if has_node("Marker2D") else null

## 能量变化信号（current, max）。对齐 UIManager._bind_weapon_energy。
signal energy_changed(current: float, max_energy: float)

var _aim_direction: Vector2 = Vector2.RIGHT
var _is_holding: bool = false

## 武器运行时状态（第十二期：能量/蓄力单一真相）。
var _runtime: WeaponRuntimeState = null

## 第十二期开火转 skill：input_bindings 驱动。
## _binding_runners: [{binding, runner, action(StringName), prev_pressed(bool)}]
var _binding_runners: Array = []
## 输入源（默认玩家；敌人可换 AIInputSource）。第十二期：开火输入从 Player 剖离。
var _input_source: WeaponInputSource = null

func _process(delta: float) -> void:
	_update_aim()
	# 能量回复（RuntimeState 持有能量，每帧回复并发信号供 UI）
	if _runtime != null and _runtime.regen(delta):
		energy_changed.emit(_runtime.energy, _runtime.max_energy)
	# 每帧轮询输入源算 press/release 边沿喂节奏机 + 推进节奏
	_poll_input()
	for br in _binding_runners:
		br.runner.tick(delta)

#region 节点契约（被 WeaponRoot/Player 调用，签名对齐旧 weapon_base）
func on_weapon_enter() -> void:
	_init_runtime()
	_setup_bindings()

func on_weapon_exit() -> void:
	_teardown_bindings()
	_is_holding = false

## 当前能量 / 上限（供 UI / 外部读）。
func get_energy() -> float:
	return _runtime.energy if _runtime else 0.0

func get_max_energy() -> float:
	return _runtime.max_energy if _runtime else 0.0

func get_energy_ratio() -> float:
	return _runtime.energy_ratio() if _runtime else 1.0

## 开火键按下（默认动作 "fire"）。喂对应 binding 的节奏机。
func hold_fire() -> void:
	_is_holding = true
	_feed_action(&"fire", true)

## 开火键松开。
func fire() -> void:
	_is_holding = false
	_feed_action(&"fire", false)

## 通用动作输入入口（供未来多键/输入源剖离用）。pressed=true 按下、false 松开。
func feed_action(action_name: StringName, pressed: bool) -> void:
	_feed_action(action_name, pressed)

func get_spawn_position() -> Vector2:
	if marker:
		return marker.global_position
	return global_position

func get_aim_direction() -> Vector2:
	return _aim_direction
#endregion

#region 技能槽（沿用第二期 WeaponDefinition 的技能槽；被 resolve_bullet_hit 调用）
## 命中/击杀时由 BattleManager.resolve_bullet_hit 调用，触发对应触发类型的技能槽。
func trigger_skill_by_type(trigger_type: WeaponSkillSlot.TriggerType, context: GameplayFlowContext = null) -> void:
	if definition == null or owner_actor == null or owner_actor.skill_manager == null:
		return
	if context == null:
		context = GameplayFlowContext.create_simple(owner_actor)
	context.event_data["weapon"] = self
	context.event_data["position"] = get_spawn_position()
	for slot in [definition.primary_skill_slot, definition.secondary_skill_slot, definition.ultimate_skill_slot]:
		if slot and slot.trigger_type == trigger_type:
			slot.trigger(owner_actor.skill_manager, context)
#endregion

#region 第十二期：input_bindings 新路（开火=激活 skill）
## 装备：为每条绑定建节奏机 + 把绑定的 skill 加进 actor 的 SkillManager。
func _setup_bindings() -> void:
	_binding_runners.clear()
	if owner_actor == null:
		return
	var mgr = owner_actor.skill_manager
	if mgr == null and owner_actor.has_method("add_skill_manager"):
		mgr = owner_actor.add_skill_manager()
	for binding in definition.input_bindings:
		if binding == null or binding.cadence == null or binding.skill == null:
			continue
		# 把开火 skill 加进 SkillManager（duplicate+initialize），记下运行实例 id
		if mgr != null and not mgr.has_skill(binding.skill.skill_id):
			mgr.add_skill(binding.skill)
		var runner := WeaponCadenceRunner.new()
		runner.setup(binding.cadence, _make_fire_cb(binding))
		_binding_runners.append({"binding": binding, "runner": runner, "action": binding.action_name, "prev_pressed": false})
	# 默认玩家输入源（敌人装备时由 AI 设 _input_source）
	if _input_source == null:
		_input_source = PlayerInputSource.new()

## 设输入源（敌人 AI 装备时注入 AIInputSource）。
func set_input_source(src: WeaponInputSource) -> void:
	_input_source = src

## 每帧轮询输入源，对每条 binding 算按下/松开边沿喂节奏机。
func _poll_input() -> void:
	if _input_source == null:
		return
	for br in _binding_runners:
		var now: bool = _input_source.is_pressed(br.action)
		if now and not br.prev_pressed:
			br.runner.feed_press()
			_is_holding = true
		elif not now and br.prev_pressed:
			br.runner.feed_release()
			_is_holding = false
		br.prev_pressed = now

## 卸下：移除绑定的 skill（避免切武器后残留）。
func _teardown_bindings() -> void:
	if owner_actor != null and owner_actor.skill_manager != null:
		for br in _binding_runners:
			owner_actor.skill_manager.remove_skill(br.binding.skill.skill_id)
	_binding_runners.clear()

## 把动作输入喂给对应 binding 的节奏机。
func _feed_action(action_name: StringName, pressed: bool) -> void:
	for br in _binding_runners:
		if br.binding.action_name == action_name:
			if pressed:
				br.runner.feed_press()
			else:
				br.runner.feed_release()

## 生成节奏机的开火回调：门控（能量）→ 打包 context → skill.use。
func _make_fire_cb(binding: WeaponInputBinding) -> Callable:
	return func(trigger_kind: String, charge_ratio: float, charge_time: float) -> void:
		_on_cadence_fire(binding, trigger_kind, charge_ratio, charge_time)

## 节奏到点：Weapon 侧门控（能量）通过后激活 skill。
func _on_cadence_fire(binding: WeaponInputBinding, trigger_kind: String, charge_ratio: float, charge_time: float) -> void:
	if owner_actor == null or owner_actor.skill_manager == null:
		return
	# 能量门控（归 Weapon）
	if binding.consume_energy and _runtime != null:
		if not _runtime.has_energy(binding.energy_cost):
			return
		_runtime.consume(binding.energy_cost)
		energy_changed.emit(_runtime.energy, _runtime.max_energy)
	# 打包调用情况 context
	var ctx := GameplayFlowContext.create_simple(owner_actor)
	var d := ctx.event_data
	d["trigger_kind"] = trigger_kind
	d["charge_ratio"] = charge_ratio
	d["charge_time"] = charge_time
	d["direction"] = _aim_direction
	d["position"] = get_spawn_position()
	d["owner"] = owner_actor
	d["weapon"] = self
	owner_actor.skill_manager.use_skill(binding.skill.skill_id, ctx)
#endregion

#region 内部
## 初始化武器运行时状态（能量）。装备时调。
func _init_runtime() -> void:
	if definition == null:
		return
	_runtime = WeaponRuntimeState.new()
	_runtime.setup(definition.max_energy, definition.energy_regen)
	energy_changed.emit(_runtime.energy, _runtime.max_energy)

func _update_aim() -> void:
	var mouse := get_global_mouse_position()
	if owner_actor:
		_aim_direction = (mouse - owner_actor.global_position).normalized()
	look_at(mouse)
#endregion
