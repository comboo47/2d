class_name WeaponCrossbow extends WeaponBase
## 弩枪武器
## 能量系统 + 蓄力连射

## 连射间隔（秒）
@export var fire_interval: float = 0.1

## 连射累计时间
var _fire_accumulator: float = 0.0

## 能量恢复定时器引用（由场景配置）
@onready var refresh_timer: Timer = $RefreshTimer if has_node("RefreshTimer") else null

func _ready() -> void:
	super._ready()
	weapon_type = WeaponConfig.WeaponType.CROSSBOW
	bullet_type = WeaponConfig.BulletType.STRAIGHT  # 无重力

	# 弩枪专用参数
	max_energy = 100.0
	energy_cost = 10.0
	energy_regen = 3.0
	charge_time = 0.7

	# 初始化能量
	current_energy = max_energy

func _process(delta: float) -> void:
	super._process(delta)

	# 蓄力连射逻辑（蓄力足够时自动连射）
	if _is_holding and hold_time >= charge_time:
		_fire_accumulator += delta

		# 达到连射间隔时发射
		if _fire_accumulator >= fire_interval:
			_fire_accumulator = 0.0
			_try_fire_continuous()

## 尝试连射
func _try_fire_continuous() -> void:
	if has_energy(energy_cost):
		consume_energy(energy_cost)
		emit_bullet(_aim_direction, base_speed)

## 发射弩枪（释放按键时调用）
func fire() -> void:
	# 如果蓄力时间不足，单发射击
	if hold_time < charge_time:
		if has_energy(energy_cost):
			consume_energy(energy_cost)
			emit_bullet(_aim_direction, base_speed)

	# 重置所有状态
	_is_holding = false
	hold_time = 0.0
	_fire_accumulator = 0.0
	_set_state(WeaponConfig.WeaponState.IDLE)

## 弩枪不需要弹道预览（直射）
func _update_trajectory(_delta: float) -> void:
	if trajectory_line:
		trajectory_line.clear_points()

## 更新蓄力（弩枪不增加速度，只计时触发连射）
func _update_charge(delta: float) -> void:
	hold_time += delta

## 兼容旧接口
func getWeaponEnergy() -> float:
	return get_current_energy()