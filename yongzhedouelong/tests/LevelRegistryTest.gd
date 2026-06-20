extends SceneTree
## 第十期 LevelRegistry 回归测试。
## 运行：godot --headless --path . -s res://tests/LevelRegistryTest.gd
## 注：直接 new 一个 registry 实例 + 手动扫描，避免依赖 autoload（-s 模式下 autoload 可用但显式更稳）。

const RegScript = preload("res://src/gameplay/levels/LevelRegistry.gd")

var _failures := 0

func _initialize() -> void:
	_run("scan_finds_level_01_and_02", _test_scan)
	_run("get_definition_deep_copy", _test_deep_copy)
	_run("next_level_id_chain", _test_next_chain)
	_run("get_all_definitions_sorted", _test_sorted)
	quit(_failures)

func _run(name: String, c: Callable) -> void:
	var r = c.call()
	if r is bool and r == true:
		print("PASS ", name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [name, str(r)])

func _make_reg():
	var reg = RegScript.new()
	reg._scan_and_register()
	return reg

func _test_scan() -> Variant:
	var reg = _make_reg()
	if not reg.has("level_01"):
		return "应扫到 level_01"
	if not reg.has("level_02"):
		return "应扫到 level_02"
	return true

func _test_deep_copy() -> Variant:
	var reg = _make_reg()
	var a = reg.get_definition("level_01")
	var b = reg.get_definition("level_01")
	if a == null or b == null:
		return "get_definition 应返回非空"
	if a == b:
		return "应返回深拷贝（两次取应为不同实例）"
	return true

func _test_next_chain() -> Variant:
	var reg = _make_reg()
	var l1 = reg.get_definition("level_01")
	if l1.next_level_id != "level_02":
		return "level_01.next 应为 level_02，得到 %s" % l1.next_level_id
	var l2 = reg.get_definition("level_02")
	if l2.next_level_id != "":
		return "level_02 应为末关（next 空）"
	return true

func _test_sorted() -> Variant:
	var reg = _make_reg()
	var defs = reg.get_all_definitions()
	if defs.size() < 2:
		return "至少应有 2 关，得到 %d" % defs.size()
	# level_order 升序
	for i in range(defs.size() - 1):
		if defs[i].level_order > defs[i + 1].level_order:
			return "应按 level_order 升序"
	return true
