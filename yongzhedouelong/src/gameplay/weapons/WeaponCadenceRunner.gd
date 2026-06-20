class_name WeaponCadenceRunner extends RefCounted
## 武器节奏状态机（第十二期，纯逻辑、可单测）。把四个 Flow_*Fire 散落的节奏逻辑
## （蓄力计时/连发间隔/射速门控/缓冲补发）上移到这里统一。
##
## 用法：setup(cadence, fire_cb) → feed_press()/feed_release() 喂输入 → tick(delta) 每帧推进。
## 到达开火时机时回调 fire_cb.call(trigger_kind: String, charge_ratio: float, charge_time: float)。
## 「能不能发」（能量等）由回调方（WeaponDriver）判定；本类只管"何时该发"。

## 开火意图类型（喂给 skill flow 决定发射形态）
const KIND_CLICK := "click"               # 单次点击发射
const KIND_CHARGE_RELEASE := "charge_release"  # 蓄力松开发射（带 charge_ratio）
const KIND_BURST := "burst"               # 连发流中的一发

var _cadence: WeaponCadence = null
var _fire_cb: Callable = Callable()

# 运行时状态
var _pressed: bool = false
var _charge_time: float = 0.0
var _burst_accum: float = 0.0
var _fired_this_press: bool = false      # CHARGE_TO_HOLD：本次按住是否已发过（早松单发用）

# 射速门控（min_fire_interval）+ 缓冲补发
var _cooldown: float = 0.0
var _pending: bool = false
var _pending_kind: String = ""
var _pending_ratio: float = 0.0
var _pending_charge: float = 0.0

func setup(cadence: WeaponCadence, fire_cb: Callable) -> void:
	_cadence = cadence
	_fire_cb = fire_cb

func is_pressed() -> bool:
	return _pressed

func charge_time() -> float:
	return _charge_time

## 蓄力程度 0~1（按 charge_threshold 归一）。
func charge_ratio() -> float:
	if _cadence == null or _cadence.charge_threshold <= 0.0:
		return 1.0 if _charge_time > 0.0 else 0.0
	return clampf(_charge_time / _cadence.charge_threshold, 0.0, 1.0)

#region 输入喂入
func feed_press() -> void:
	if _cadence == null:
		return
	_pressed = true
	_charge_time = 0.0
	_burst_accum = 0.0
	_fired_this_press = false
	match _cadence.mode:
		WeaponCadence.Mode.CLICK:
			_request_fire(KIND_CLICK)
		WeaponCadence.Mode.HOLD:
			_request_fire(KIND_BURST)  # 按下立即发一发
		# CHARGE / CHARGE_TO_HOLD：按下只开始蓄力，不发

func feed_release() -> void:
	if _cadence == null:
		_pressed = false
		return
	match _cadence.mode:
		WeaponCadence.Mode.CHARGE:
			_request_fire(KIND_CHARGE_RELEASE)
		WeaponCadence.Mode.CHARGE_TO_HOLD:
			# 未达阈值且本次没连发过 → 单发
			if _charge_time < _cadence.charge_threshold and not _fired_this_press:
				_request_fire(KIND_CLICK)
	_pressed = false
#endregion

#region 每帧推进
func tick(delta: float) -> void:
	if _cadence == null:
		return
	# 射速冷却倒计时 + 缓冲补发
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
		if _cooldown <= 0.0 and _pending:
			_pending = false
			_emit_fire(_pending_kind, _pending_ratio, _pending_charge)
			_start_cooldown()
	# 蓄力计时
	if _pressed:
		_charge_time += delta
	# 连发节奏
	match _cadence.mode:
		WeaponCadence.Mode.HOLD:
			if _pressed:
				_burst_tick(delta)
		WeaponCadence.Mode.CHARGE_TO_HOLD:
			if _pressed and _charge_time >= _cadence.charge_threshold:
				_burst_tick(delta)

func _burst_tick(delta: float) -> void:
	_burst_accum += delta
	while _burst_accum >= _cadence.repeat_interval:
		_burst_accum -= _cadence.repeat_interval
		_request_fire(KIND_BURST)
#endregion

#region 内部：开火意图 + 射速门控
## 产生一次开火意图：冷却中则缓冲（只缓最近一发），否则立即发并起冷却。
func _request_fire(kind: String) -> void:
	var ratio := charge_ratio()
	if _cadence.min_fire_interval > 0.0 and _cooldown > 0.0:
		_pending = true
		_pending_kind = kind
		_pending_ratio = ratio
		_pending_charge = _charge_time
		return
	_emit_fire(kind, ratio, _charge_time)
	_start_cooldown()

func _emit_fire(kind: String, ratio: float, charge: float) -> void:
	_fired_this_press = true
	if _fire_cb.is_valid():
		_fire_cb.call(kind, ratio, charge)

func _start_cooldown() -> void:
	if _cadence.min_fire_interval > 0.0:
		_cooldown = _cadence.min_fire_interval
#endregion
