extends SceneTree
## 第十期 存档解锁闭环单测（用 set_save_path_for_tests 隔离，不碰真实存档）。
## 运行：godot --headless --path . -s res://tests/SaveUnlockFlowTest.gd

const SaveManagerScript = preload("res://src/app/SaveManager.gd")
const TEST_SAVE_PATH := "user://save_unlock_flow_test/progress.json"

var _failures := 0

func _initialize() -> void:
	_run("complete_and_unlock_persists", _test_complete_unlock)
	_run("unlock_dedupes", _test_dedup)
	quit(_failures)

func _run(name: String, c: Callable) -> void:
	_remove_save()
	var r = c.call()
	if r is bool and r == true:
		print("PASS ", name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [name, str(r)])

func _make_manager() -> Node:
	var m = SaveManagerScript.new()
	m.set_save_path_for_tests(TEST_SAVE_PATH)
	return m

func _test_complete_unlock() -> Variant:
	var m := _make_manager()
	if not m.mark_level_completed("level_01"):
		return "mark_level_completed 应成功"
	if not m.unlock_level("level_02"):
		return "unlock_level 应成功"
	# 重载验证持久化
	var m2 := _make_manager()
	var p = m2.load_progress()
	if not p.get("completed_levels", []).has("level_01"):
		return "completed 应含 level_01"
	if not p.get("unlocked_levels", []).has("level_02"):
		return "unlocked 应含 level_02"
	return true

func _test_dedup() -> Variant:
	var m := _make_manager()
	m.unlock_level("level_02")
	m.unlock_level("level_02")
	var p = m.get_progress()
	var count := 0
	for id in p.get("unlocked_levels", []):
		if id == "level_02":
			count += 1
	if count != 1:
		return "重复 unlock 应去重，得到 %d" % count
	return true

func _remove_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		var dir := DirAccess.open(TEST_SAVE_PATH.get_base_dir())
		if dir:
			dir.remove(TEST_SAVE_PATH.get_file())
