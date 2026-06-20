extends SceneTree
## 第十二期 WeaponCadenceRunner 节奏状态机回归测试。
## 运行：godot --headless --path . -s res://tests/WeaponCadenceTest.gd

var _failures := 0

func _initialize() -> void:
	_run("click_fires_once_on_press", _test_click)
	_run("hold_fires_on_press_then_periodic", _test_hold)
	_run("charge_fires_on_release_with_ratio", _test_charge)
	_run("charge_ratio_caps_at_one", _test_charge_cap)
	_run("charge_to_hold_early_release_single", _test_cth_early)
	_run("charge_to_hold_burst_after_threshold", _test_cth_burst)
	_run("min_interval_gates_and_buffers", _test_cd_gate)
	quit(_failures)

func _run(name: String, c: Callable) -> void:
	var r = c.call()
	if r is bool and r == true:
		print("PASS ", name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [name, str(r)])

# 记录开火回调
class FireLog:
	var kinds: Array = []
	var ratios: Array = []
	func cb(kind: String, ratio: float, _charge: float) -> void:
		kinds.append(kind)
		ratios.append(ratio)

func _make(mode: WeaponCadence.Mode, repeat := 0.12, threshold := 0.7, min_interval := 0.0) -> Array:
	var cad := WeaponCadence.new()
	cad.mode = mode
	cad.repeat_interval = repeat
	cad.charge_threshold = threshold
	cad.min_fire_interval = min_interval
	var log := FireLog.new()
	var runner := WeaponCadenceRunner.new()
	runner.setup(cad, Callable(log, "cb"))
	return [runner, log]

func _test_click() -> Variant:
	var s := _make(WeaponCadence.Mode.CLICK)
	var runner: WeaponCadenceRunner = s[0]
	var log: FireLog = s[1]
	runner.feed_press()
	runner.feed_release()
	if log.kinds.size() != 1:
		return "CLICK 按下应发 1 次，得到 %d" % log.kinds.size()
	if log.kinds[0] != WeaponCadenceRunner.KIND_CLICK:
		return "CLICK kind 应为 click"
	return true

func _test_hold() -> Variant:
	var s := _make(WeaponCadence.Mode.HOLD, 0.1)
	var runner: WeaponCadenceRunner = s[0]
	var log: FireLog = s[1]
	runner.feed_press()  # 立即 1 发
	# 按住 0.25s → 应再发 2 发（0.1, 0.2）
	runner.tick(0.1)
	runner.tick(0.1)
	runner.tick(0.05)
	if log.kinds.size() != 3:
		return "HOLD 按下+0.25s 应发 3 次，得到 %d" % log.kinds.size()
	return true

func _test_charge() -> Variant:
	var s := _make(WeaponCadence.Mode.CHARGE, 0.12, 1.0)
	var runner: WeaponCadenceRunner = s[0]
	var log: FireLog = s[1]
	runner.feed_press()
	runner.tick(0.5)  # 蓄 0.5s（阈值 1.0 → ratio 0.5）
	if log.kinds.size() != 0:
		return "CHARGE 按住期间不应发"
	runner.feed_release()
	if log.kinds.size() != 1 or log.kinds[0] != WeaponCadenceRunner.KIND_CHARGE_RELEASE:
		return "CHARGE 松开应发 1 次 charge_release"
	if not is_equal_approx(log.ratios[0], 0.5):
		return "蓄 0.5s/阈值1.0 ratio 应 0.5，得到 %s" % log.ratios[0]
	return true

func _test_charge_cap() -> Variant:
	var s := _make(WeaponCadence.Mode.CHARGE, 0.12, 0.7)
	var runner: WeaponCadenceRunner = s[0]
	var log: FireLog = s[1]
	runner.feed_press()
	runner.tick(2.0)  # 远超阈值
	runner.feed_release()
	if not is_equal_approx(log.ratios[0], 1.0):
		return "超阈值 ratio 应封顶 1.0，得到 %s" % log.ratios[0]
	return true

func _test_cth_early() -> Variant:
	var s := _make(WeaponCadence.Mode.CHARGE_TO_HOLD, 0.1, 0.7)
	var runner: WeaponCadenceRunner = s[0]
	var log: FireLog = s[1]
	runner.feed_press()
	runner.tick(0.3)  # 未达阈值 0.7
	runner.feed_release()
	if log.kinds.size() != 1 or log.kinds[0] != WeaponCadenceRunner.KIND_CLICK:
		return "CHARGE_TO_HOLD 早松应单发 click，得到 %s" % str(log.kinds)
	return true

func _test_cth_burst() -> Variant:
	var s := _make(WeaponCadence.Mode.CHARGE_TO_HOLD, 0.1, 0.5)
	var runner: WeaponCadenceRunner = s[0]
	var log: FireLog = s[1]
	runner.feed_press()
	# 蓄过阈值 0.5 后继续按住连发
	runner.tick(0.5)  # 到阈值
	runner.tick(0.1)  # burst 1
	runner.tick(0.1)  # burst 2
	if log.kinds.size() < 2:
		return "CHARGE_TO_HOLD 过阈应连发，得到 %d" % log.kinds.size()
	for k in log.kinds:
		if k != WeaponCadenceRunner.KIND_BURST:
			return "连发 kind 应为 burst"
	return true

func _test_cd_gate() -> Variant:
	# CLICK + min_interval：狂点只发 1 发 + 缓冲 1 发，冷却后补发
	var s := _make(WeaponCadence.Mode.CLICK, 0.12, 0.7, 0.3)
	var runner: WeaponCadenceRunner = s[0]
	var log: FireLog = s[1]
	runner.feed_press(); runner.feed_release()  # 发 1（起冷却 0.3）
	runner.feed_press(); runner.feed_release()  # 冷却中 → 缓冲
	runner.feed_press(); runner.feed_release()  # 仍冷却 → 覆盖缓冲（只缓 1）
	if log.kinds.size() != 1:
		return "冷却内应只发 1 发，得到 %d" % log.kinds.size()
	runner.tick(0.31)  # 过冷却 → 补发缓冲那 1 发
	if log.kinds.size() != 2:
		return "冷却结束应补发 1 发（共 2），得到 %d" % log.kinds.size()
	return true
