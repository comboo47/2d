class_name WeaponBase extends Node2D
## 武器基类
## 所有武器继承此类，统一接口

## 统一的武器发射信号
## 参数: bullet(PackedScene), spawn_position(Vector2), direction(Vector2), speed(float), bullet_type(int), owner(BattleActor)
signal weapon_fired(bullet: PackedScene, spawn_position: Vector2, direction: Vector2, speed: float, bullet_type: int, owner: BattleActor)

## 能量变化信号
## 参数: current(当前能量), max_energy(最大能量)
signal energy_changed(current: float, max_energy: float)

## 武器状态变化信号
## 参数: state(WeaponConfig.WeaponState)
signal weapon_state_changed(state: WeaponConfig.WeaponState)

## 武器进入信号（被切换为当前武器时触发）
## 参数: weapon(WeaponBase), owner(BattleActor)
signal weapon_enter(weapon: WeaponBase, owner: BattleActor)

## 武器退出信号（被切换离开当前武器时触发）
## 参数: weapon(WeaponBase), owner(BattleActor)
signal weapon_exit(weapon: WeaponBase, owner: BattleActor)

## 基础属性
@export var bullet: PackedScene
@export var owner_actor: BattleActor

## 武器类型
@export var weapon_type: WeaponConfig.WeaponType = WeaponConfig.WeaponType.BOW

## 子弹类型
@export var bullet_type: WeaponConfig.BulletType = WeaponConfig.BulletType.NORMAL

## 基础速度
@export var base_speed: float = 250.0

## 伤害 Buff ID
@export var damage_buff_id: String = "1001"

## 能量系统（可选）
@export var max_energy: float = 100.0
@export var energy_cost: float = 10.0
@export var energy_regen: float = 3.0
var current_energy: float = 0.0

## 蓄力系统（可选）
@export var max_charge_speed: float = 650.0
@export var charge_rate: float = 5.0  # 每帧增加的速度
@export var charge_time: float = 0.7  # 蓄力时间阈值
var hold_time: float = 0.0
var charge_speed: float = 0.0

## 关联技能系统
## 武器有三个主动技能槽配置（PRIMARY、SECONDARY、ULTIMATE）
## 每个槽位使用 WeaponSkillSlot 定义触发时机和关联技能

## 主技能槽配置
@export var primary_skill_slot: WeaponSkillSlot

## 副技能槽配置
@export var secondary_skill_slot: WeaponSkillSlot

## 终极技能槽配置
@export var ultimate_skill_slot: WeaponSkillSlot

## 被动技能列表（可关联多个被动技能）
## 被动技能在武器进入时自动激活，退出时自动移除
@export var passive_skills: Array[SkillBase] = []

## 运行时状态
var _aim_direction: Vector2 = Vector2.RIGHT
var _aim_mouse_pos: Vector2 = Vector2.ZERO
var _is_holding: bool = false
var _weapon_state: WeaponConfig.WeaponState = WeaponConfig.WeaponState.IDLE

## 弹道预览节点（由场景配置）
@onready var trajectory_line: Line2D = $Line2D if has_node("Line2D") else null
@onready var marker: Marker2D = $Marker2D if has_node("Marker2D") else null

func _ready() -> void:
	# 初始化能量
	current_energy = max_energy

	# 获取子弹默认速度
	if bullet:
		var temp_bullet = bullet.instantiate()
		if temp_bullet.get("speed") != null:
			base_speed = temp_bullet.speed
		temp_bullet.queue_free()

func _process(delta: float) -> void:
	update_aim()

	# 能量恢复（非蓄力状态）
	if not _is_holding and energy_regen > 0:
		_regen_energy(delta)

	# 蓄力更新
	if _is_holding:
		_update_charge(delta)

	# 更新弹道预览
	_update_trajectory(delta)

## 更新瞄准方向
func update_aim() -> void:
	_aim_mouse_pos = get_viewport().get_mouse_position()
	if owner_actor:
		_aim_direction = (_aim_mouse_pos - owner_actor.global_position).normalized()
	look_at(_aim_mouse_pos)

#region 公共 API - 发射控制
## 开始蓄力
func hold_fire() -> void:
	_is_holding = true
	hold_time = 0.0
	charge_speed = 0.0
	_set_state(WeaponConfig.WeaponState.CHARGING)

## 发射（释放时调用）
func fire() -> void:
	_is_holding = false
	_set_state(WeaponConfig.WeaponState.IDLE)
	# 子类重写此方法实现具体发射逻辑

## 强制释放（清除蓄力状态）
func release_fire() -> void:
	_is_holding = false
	hold_time = 0.0
	charge_speed = 0.0
	_set_state(WeaponConfig.WeaponState.IDLE)
#endregion

#region 公共 API - 能量系统
## 消耗能量
func consume_energy(amount: float) -> bool:
	if current_energy >= amount:
		current_energy -= amount
		energy_changed.emit(current_energy, max_energy)

		if current_energy <= 0:
			_set_state(WeaponConfig.WeaponState.EMPTY)

		return true
	return false

## 检查能量是否足够
func has_energy(amount: float) -> bool:
	return current_energy >= amount

## 获取当前能量
func get_current_energy() -> float:
	return current_energy

## 获取能量百分比
func get_energy_percent() -> float:
	return current_energy / max_energy if max_energy > 0 else 0.0
#endregion

#region 公共 API - 状态查询
## 获取当前状态
func get_state() -> WeaponConfig.WeaponState:
	return _weapon_state

## 是否正在蓄力
func is_charging() -> bool:
	return _is_holding

## 获取蓄力时间
func get_hold_time() -> float:
	return hold_time

## 获取当前发射速度（基础 + 蓄力加成）
func get_current_speed() -> float:
	return base_speed + charge_speed

## 获取瞄准方向
func get_aim_direction() -> Vector2:
	return _aim_direction

## 获取发射位置
func get_spawn_position() -> Vector2:
	if marker:
		return marker.global_position
	return global_position

## 兼容旧接口：获取能量值
func getWeaponEnergy() -> float:
	return get_current_energy()
#endregion

#region 内部方法 - 发射辅助
## 发射子弹（子类调用）
func emit_bullet(direction: Vector2, speed: float = -1.0) -> void:
	if speed < 0:
		speed = get_current_speed()

	var spawn_pos = get_spawn_position()
	emit_signal("weapon_fired", bullet, spawn_pos, direction, speed, bullet_type, owner_actor)

## 发射多颗子弹（散射）
func emit_bullets(directions: Array[Vector2], speed: float = -1.0) -> void:
	if speed < 0:
		speed = get_current_speed()

	for dir in directions:
		emit_bullet(dir, speed)
#endregion

#region 内部方法 - 更新逻辑
## 更新蓄力
func _update_charge(delta: float) -> void:
	hold_time += delta
	charge_speed += charge_rate
	charge_speed = clamp(charge_speed, 0.0, max_charge_speed - base_speed)

## 能量恢复
func _regen_energy(delta: float) -> void:
	if energy_regen > 0 and current_energy < max_energy:
		current_energy = min(max_energy, current_energy + energy_regen * delta)
		energy_changed.emit(current_energy, max_energy)

## 更新弹道预览线
func _update_trajectory(delta: float) -> void:
	if trajectory_line == null:
		return

	trajectory_line.clear_points()

	if _is_holding:
		_draw_trajectory(delta)

## 绘制弹道轨迹
func _draw_trajectory(delta: float) -> void:
	var speed = get_current_speed()
	var dir = _aim_direction

	# 计算轨迹点（考虑重力）
	var gravity = 490.0  # Godot 默认重力值
	var step_x = dir.x * speed
	var step_y = dir.y * speed

	for i in range(30):
		var point = Vector2(step_x * i * delta, (step_y + gravity * i * delta) * i * delta)
		trajectory_line.add_point(point)

## 设置武器状态
func _set_state(new_state: WeaponConfig.WeaponState) -> void:
	if _weapon_state != new_state:
		_weapon_state = new_state
		weapon_state_changed.emit(new_state)
#endregion

#region 公共 API - 技能关联
## 触发指定槽位的技能
## slot_type: WeaponSkillSlot.TriggerType (ON_FIRE, ON_HIT, ON_KILL, ON_CHARGE_MAX, ON_ENERGY_EMPTY)
func trigger_skill_by_type(trigger_type: WeaponSkillSlot.TriggerType, context: GameplayFlowContext = null) -> void:
	if owner_actor == null or owner_actor.skill_manager == null:
		return

	if context == null:
		context = GameplayFlowContext.create_simple(owner_actor)

	context.event_data["weapon"] = self
	context.event_data["position"] = get_spawn_position()

	# 检查三个主动技能槽
	var slots = [primary_skill_slot, secondary_skill_slot, ultimate_skill_slot]
	for slot in slots:
		if slot and slot.trigger_type == trigger_type:
			slot.trigger(owner_actor.skill_manager, context)

## 触发主技能槽的技能（便捷方法）
func trigger_primary_skill(context: GameplayFlowContext = null) -> void:
	if primary_skill_slot == null:
		return
	trigger_skill_by_type(primary_skill_slot.trigger_type, context)

## 触发副技能槽的技能（便捷方法）
func trigger_secondary_skill(context: GameplayFlowContext = null) -> void:
	if secondary_skill_slot == null:
		return
	trigger_skill_by_type(secondary_skill_slot.trigger_type, context)

## 触发终极技能槽的技能（便捷方法）
func trigger_ultimate_skill(context: GameplayFlowContext = null) -> void:
	if ultimate_skill_slot == null:
		return
	trigger_skill_by_type(ultimate_skill_slot.trigger_type, context)

## 激活所有被动技能（武器进入时调用）
func activate_passive_skills() -> void:
	if owner_actor == null or owner_actor.skill_manager == null:
		return

	for skill in passive_skills:
		if skill and skill.skill_type == SkillConfig.SkillType.PASSIVE:
			owner_actor.skill_manager.add_skill(skill, SkillConfig.SkillSlot.PASSIVE_SLOT)

## 移除所有被动技能（武器退出时调用）
func deactivate_passive_skills() -> void:
	if owner_actor == null or owner_actor.skill_manager == null:
		return

	for skill in passive_skills:
		if skill:
			owner_actor.skill_manager.remove_skill(skill.skill_id)
#endregion

#region 公共 API - 武器切换
## 武器进入（被切换为当前武器时调用）
func on_weapon_enter() -> void:
	weapon_enter.emit(self, owner_actor)

	# 激活被动技能
	activate_passive_skills()

	# 重置能量显示
	if owner_actor and owner_actor.has_meta("weaponEnergyBar"):
		owner_actor.get_meta("weaponEnergyBar").updateEnergyBarvisible()

## 武器退出（被切换离开当前武器时调用）
func on_weapon_exit() -> void:
	weapon_exit.emit(self, owner_actor)

	# 移除被动技能
	deactivate_passive_skills()

	# 清理蓄力状态
	release_fire()
#endregion
