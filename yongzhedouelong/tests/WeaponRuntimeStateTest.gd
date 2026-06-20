extends SceneTree
## 第十二期 WeaponRuntimeState 回归测试。
## 运行：godot --headless --path . -s res://tests/WeaponRuntimeStateTest.gd

var _failures := 0

func _initialize() -> void:
	_run("setup_full_energy", _test_setup)
	_run("regen_caps_at_max", _test_regen_cap)
	_run("consume_not_below_zero", _test_consume)
	_run("has_energy_boundary", _test_has)
	_run("energy_ratio", _test_ratio)
	quit(_failures)

func _run(name: String, c: Callable) -> void:
	var r = c.call()
	if r is bool and r == true:
		print("PASS ", name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [name, str(r)])

func _make(max_e := 100.0, regen := 10.0) -> WeaponRuntimeState:
	var s := WeaponRuntimeState.new()
	s.setup(max_e, regen)
	return s

func _test_setup() -> Variant:
	var s := _make(100.0, 5.0)
	if s.energy != 100.0:
		return "setup 后能量应为满 100，得到 %s" % s.energy
	return true

func _test_regen_cap() -> Variant:
	var s := _make(100.0, 50.0)
	s.consume(40.0)  # 60
	var changed := s.regen(0.5)  # +25 → 85
	if not changed or not is_equal_approx(s.energy, 85.0):
		return "回复应到 85，得到 %s" % s.energy
	# 满了不再变
	s.regen(10.0)  # 封顶 100
	if not is_equal_approx(s.energy, 100.0):
		return "应封顶 100"
	if s.regen(1.0):
		return "满能量 regen 应返回 false（无变化）"
	return true

func _test_consume() -> Variant:
	var s := _make(30.0, 0.0)
	s.consume(50.0)  # 不为负
	if s.energy != 0.0:
		return "过量消耗应钳到 0，得到 %s" % s.energy
	if s.consume(0.0):
		return "consume 0 应返回 false"
	return true

func _test_has() -> Variant:
	var s := _make(100.0, 0.0)
	s.consume(91.0)  # 9
	if s.has_energy(10.0):
		return "9 能量不应满足 cost 10"
	if not s.has_energy(9.0):
		return "9 能量应满足 cost 9"
	return true

func _test_ratio() -> Variant:
	var s := _make(200.0, 0.0)
	s.consume(50.0)  # 150/200=0.75
	if not is_equal_approx(s.energy_ratio(), 0.75):
		return "ratio 应 0.75，得到 %s" % s.energy_ratio()
	return true
