# Save System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现第一版单自动进度存档，让游戏能保存和读取关卡完成、关卡解锁、奖励和重置状态。

**Architecture:** 新增 `SaveManager` autoload 统一管理 `user://save/progress.json` 的读取、写入、默认值、去重和错误回退。现有系统通过 `SaveManager` API 间接操作存档；第一版不接入复杂 UI，也不保存战斗现场。

**Tech Stack:** Godot 4.6、GDScript、`FileAccess`、`DirAccess`、`JSON`、现有 `tests/GameplayCoreTest.gd` headless 测试入口。

---

## 文件结构

- Create: `src/app/SaveManager.gd`
  负责存档默认数据、路径、JSON 读写、进度变更 API、测试路径注入。
- Modify: `project.godot`
  在 `[autoload]` 中注册 `SaveManager="*res://src/app/SaveManager.gd"`。
- Modify: `tests/GameplayCoreTest.gd`
  加入 SaveManager 的 headless 单元测试，使用隔离路径避免覆盖真实 `user://save/progress.json`。

实施时从项目根目录 `E:\Godot工程\DragonKiller\2d\yongzhedouelong` 运行命令。当前工作区已有其他未提交改动，只 stage 本计划涉及的三个文件。

### Task 1: SaveManager 基础测试

**Files:**
- Modify: `tests/GameplayCoreTest.gd`
- Create later in Task 2: `src/app/SaveManager.gd`

- [ ] **Step 1: 在测试文件顶部加入 SaveManager 脚本预加载**

在 `tests/GameplayCoreTest.gd` 的 `extends SceneTree` 后面加入：

```gdscript
const SaveManagerScript = preload("res://src/app/SaveManager.gd")
const TEST_SAVE_PATH := "user://save_manager_test/progress.json"
```

- [ ] **Step 2: 在 `_initialize()` 中注册基础存档测试**

在现有 `_run(...)` 列表末尾、`quit(_failures)` 前加入：

```gdscript
	_run("save_manager_missing_file_returns_default_progress", _test_save_manager_missing_file_returns_default_progress)
	_run("save_manager_save_and_load_round_trip", _test_save_manager_save_and_load_round_trip)
```

- [ ] **Step 3: 在测试文件末尾加入测试 helper 和两个测试**

把下面代码放在 `_cleanup_test_nodes()` 之后：

```gdscript
func _test_save_manager_missing_file_returns_default_progress() -> Variant:
	_remove_test_save_file()
	var manager := _make_save_manager()
	var progress := manager.load_progress()

	if progress.get("schema_version") != 1:
		return "expected schema_version 1"
	if progress.get("current_level_id") != "":
		return "expected empty current_level_id"
	if progress.get("completed_levels", []).size() != 0:
		return "expected no completed levels"
	if progress.get("unlocked_levels", []).size() != 0:
		return "expected no unlocked levels"
	if not progress.get("rewards", {}) is Dictionary:
		return "expected rewards dictionary"
	return true

func _test_save_manager_save_and_load_round_trip() -> Variant:
	_remove_test_save_file()
	var manager := _make_save_manager()
	var progress := {
		"schema_version": 1,
		"current_level_id": "level_01",
		"completed_levels": ["level_01"],
		"unlocked_levels": ["level_01", "level_02"],
		"rewards": {"coin": 3},
		"updated_at": ""
	}

	if not manager.save_progress(progress):
		return "save_progress should return true"
	if not FileAccess.file_exists(TEST_SAVE_PATH):
		return "save file should exist"

	var reloaded := _make_save_manager()
	var loaded := reloaded.load_progress()
	if loaded.get("current_level_id") != "level_01":
		return "expected current_level_id level_01"
	if loaded.get("completed_levels", []) != ["level_01"]:
		return "expected completed level round trip"
	if loaded.get("unlocked_levels", []) != ["level_01", "level_02"]:
		return "expected unlocked levels round trip"
	if loaded.get("rewards", {}).get("coin") != 3:
		return "expected coin reward round trip"
	return true

func _make_save_manager() -> Node:
	var manager = SaveManagerScript.new()
	manager.set_save_path_for_tests(TEST_SAVE_PATH)
	return manager

func _remove_test_save_file() -> void:
	if not FileAccess.file_exists(TEST_SAVE_PATH):
		return
	var dir := DirAccess.open(TEST_SAVE_PATH.get_base_dir())
	if dir:
		dir.remove(TEST_SAVE_PATH.get_file())

func _write_test_save_text(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE_PATH.get_base_dir())
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(text)
```

- [ ] **Step 4: 运行测试并确认失败来自缺失脚本**

Run:

```powershell
powershell -NoProfile -Command "& (Join-Path $env:LOCALAPPDATA 'Programs\Godot\godot.cmd') --headless --path . -s res://tests/GameplayCoreTest.gd"
```

Expected: FAIL 或解析错误，原因包含 `res://src/app/SaveManager.gd` 不存在。

- [ ] **Step 5: 提交失败测试**

Run:

```powershell
git add tests/GameplayCoreTest.gd
git commit -m "test: add save manager baseline tests"
```

Expected: commit 成功，且没有 stage 其他工作区改动。

### Task 2: 实现 SaveManager 核心读写

**Files:**
- Create: `src/app/SaveManager.gd`
- Test: `tests/GameplayCoreTest.gd`

- [ ] **Step 1: 创建 `src/app/SaveManager.gd`**

写入完整文件内容：

```gdscript
extends Node

const SCHEMA_VERSION := 1
const DEFAULT_SAVE_PATH := "user://save/progress.json"

var save_path := DEFAULT_SAVE_PATH
var _progress: Dictionary = {}

func _ready() -> void:
	load_progress()

func set_save_path_for_tests(path: String) -> void:
	save_path = path
	_progress = _default_progress()

func load_progress() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		_progress = _default_progress()
		return get_progress()

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: failed to open save file for reading: %s" % save_path)
		_progress = _default_progress()
		return get_progress()

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("SaveManager: malformed save file, using default progress: %s" % save_path)
		_progress = _default_progress()
		return get_progress()

	_progress = _normalize_progress(parsed)
	return get_progress()

func save_progress(progress: Dictionary) -> bool:
	var normalized := _normalize_progress(progress)
	normalized["updated_at"] = Time.get_datetime_string_from_system(false, true)

	if not _ensure_save_directory():
		push_error("SaveManager: failed to create save directory: %s" % save_path.get_base_dir())
		return false

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open save file for writing: %s" % save_path)
		return false

	file.store_string(JSON.stringify(normalized, "\t"))
	_progress = normalized
	return true

func get_progress() -> Dictionary:
	if _progress.is_empty():
		_progress = _default_progress()
	return _progress.duplicate(true)

func mark_level_completed(level_id: String, rewards: Dictionary = {}) -> bool:
	var trimmed_id := level_id.strip_edges()
	if trimmed_id == "":
		return false

	var next_progress := get_progress()
	var completed: Array = next_progress.get("completed_levels", [])
	if not completed.has(trimmed_id):
		completed.append(trimmed_id)
	next_progress["completed_levels"] = completed
	next_progress["current_level_id"] = trimmed_id
	next_progress["rewards"] = _merge_rewards(next_progress.get("rewards", {}), rewards)
	return save_progress(next_progress)

func unlock_level(level_id: String) -> bool:
	var trimmed_id := level_id.strip_edges()
	if trimmed_id == "":
		return false

	var next_progress := get_progress()
	var unlocked: Array = next_progress.get("unlocked_levels", [])
	if not unlocked.has(trimmed_id):
		unlocked.append(trimmed_id)
	next_progress["unlocked_levels"] = unlocked
	return save_progress(next_progress)

func reset_progress() -> bool:
	return save_progress(_default_progress())

func has_save() -> bool:
	return FileAccess.file_exists(save_path)

func _default_progress() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"current_level_id": "",
		"completed_levels": [],
		"unlocked_levels": [],
		"rewards": {},
		"updated_at": ""
	}

func _normalize_progress(raw_progress: Dictionary) -> Dictionary:
	if int(raw_progress.get("schema_version", 0)) != SCHEMA_VERSION:
		return _default_progress()

	var normalized := _default_progress()
	normalized["current_level_id"] = str(raw_progress.get("current_level_id", "")).strip_edges()
	normalized["completed_levels"] = _normalize_string_array(raw_progress.get("completed_levels", []))
	normalized["unlocked_levels"] = _normalize_string_array(raw_progress.get("unlocked_levels", []))

	var raw_rewards = raw_progress.get("rewards", {})
	if raw_rewards is Dictionary:
		normalized["rewards"] = raw_rewards.duplicate(true)

	normalized["updated_at"] = str(raw_progress.get("updated_at", ""))
	return normalized

func _normalize_string_array(value: Variant) -> Array:
	var result: Array = []
	if not value is Array:
		return result

	for item in value:
		var item_id := str(item).strip_edges()
		if item_id != "" and not result.has(item_id):
			result.append(item_id)
	return result

func _merge_rewards(current: Variant, incoming: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if current is Dictionary:
		result = current.duplicate(true)

	for key in incoming.keys():
		result[str(key)] = incoming[key]
	return result

func _ensure_save_directory() -> bool:
	var dir_path := save_path.get_base_dir()
	if dir_path == "":
		return true
	return DirAccess.make_dir_recursive_absolute(dir_path) == OK
```

- [ ] **Step 2: 运行基础测试**

Run:

```powershell
powershell -NoProfile -Command "& (Join-Path $env:LOCALAPPDATA 'Programs\Godot\godot.cmd') --headless --path . -s res://tests/GameplayCoreTest.gd"
```

Expected: SaveManager 两个测试 PASS。若其他既有测试失败，先确认失败是否来自本任务改动；不要修改无关系统。

- [ ] **Step 3: 提交核心实现**

Run:

```powershell
git add src/app/SaveManager.gd
git commit -m "feat: add save manager progress storage"
```

Expected: commit 成功。

### Task 3: 补全去重、重置、损坏文件测试

**Files:**
- Modify: `tests/GameplayCoreTest.gd`
- Modify only if test exposes defect: `src/app/SaveManager.gd`

- [ ] **Step 1: 在 `_initialize()` 增加剩余测试注册**

在 Task 1 的 SaveManager 测试后面继续加入：

```gdscript
	_run("save_manager_mark_level_completed_deduplicates_levels_and_merges_rewards", _test_save_manager_mark_level_completed_deduplicates_levels_and_merges_rewards)
	_run("save_manager_unlock_level_deduplicates_levels", _test_save_manager_unlock_level_deduplicates_levels)
	_run("save_manager_reset_progress_restores_default_shape", _test_save_manager_reset_progress_restores_default_shape)
	_run("save_manager_malformed_json_falls_back_to_default_progress", _test_save_manager_malformed_json_falls_back_to_default_progress)
```

- [ ] **Step 2: 在 helper 区域加入四个测试**

把下面代码放到 Task 1 新增测试之后、helper 函数之前：

```gdscript
func _test_save_manager_mark_level_completed_deduplicates_levels_and_merges_rewards() -> Variant:
	_remove_test_save_file()
	var manager := _make_save_manager()

	if not manager.mark_level_completed("level_01", {"coin": 1}):
		return "first mark_level_completed should save"
	if not manager.mark_level_completed("level_01", {"gem": 2}):
		return "second mark_level_completed should save"

	var progress := manager.get_progress()
	if progress.get("current_level_id") != "level_01":
		return "expected current level to be level_01"
	if progress.get("completed_levels", []) != ["level_01"]:
		return "expected completed level to be deduplicated"
	if progress.get("rewards", {}).get("coin") != 1:
		return "expected existing reward to remain"
	if progress.get("rewards", {}).get("gem") != 2:
		return "expected new reward to merge"
	return true

func _test_save_manager_unlock_level_deduplicates_levels() -> Variant:
	_remove_test_save_file()
	var manager := _make_save_manager()

	if not manager.unlock_level("level_02"):
		return "first unlock_level should save"
	if not manager.unlock_level("level_02"):
		return "second unlock_level should save"

	var progress := manager.get_progress()
	if progress.get("unlocked_levels", []) != ["level_02"]:
		return "expected unlocked level to be deduplicated"
	return true

func _test_save_manager_reset_progress_restores_default_shape() -> Variant:
	_remove_test_save_file()
	var manager := _make_save_manager()
	manager.mark_level_completed("level_01", {"coin": 1})

	if not manager.reset_progress():
		return "reset_progress should save"

	var progress := manager.get_progress()
	if progress.get("schema_version") != 1:
		return "expected schema_version 1 after reset"
	if progress.get("current_level_id") != "":
		return "expected empty current_level_id after reset"
	if progress.get("completed_levels", []).size() != 0:
		return "expected no completed levels after reset"
	if progress.get("unlocked_levels", []).size() != 0:
		return "expected no unlocked levels after reset"
	if progress.get("rewards", {}).size() != 0:
		return "expected no rewards after reset"
	return true

func _test_save_manager_malformed_json_falls_back_to_default_progress() -> Variant:
	_remove_test_save_file()
	_write_test_save_text("{ this is not valid json")

	var manager := _make_save_manager()
	var progress := manager.load_progress()
	if progress.get("schema_version") != 1:
		return "expected schema_version 1 for malformed file fallback"
	if progress.get("completed_levels", []).size() != 0:
		return "expected default completed levels for malformed file fallback"
	if not FileAccess.file_exists(TEST_SAVE_PATH):
		return "malformed file should remain on disk"
	return true
```

- [ ] **Step 3: 运行测试并修正 SaveManager 缺陷**

Run:

```powershell
powershell -NoProfile -Command "& (Join-Path $env:LOCALAPPDATA 'Programs\Godot\godot.cmd') --headless --path . -s res://tests/GameplayCoreTest.gd"
```

Expected: 新增 SaveManager 测试 PASS，现有 gameplay 测试保持原结果。

如果失败来自 SaveManager，按失败信息修正 `src/app/SaveManager.gd`，保持 API 名称不变：

```gdscript
func mark_level_completed(level_id: String, rewards: Dictionary = {}) -> bool
func unlock_level(level_id: String) -> bool
func reset_progress() -> bool
```

- [ ] **Step 4: 提交完整测试覆盖**

Run:

```powershell
git add tests/GameplayCoreTest.gd src/app/SaveManager.gd
git commit -m "test: cover save manager progress mutations"
```

Expected: commit 成功。

### Task 4: 注册 SaveManager autoload

**Files:**
- Modify: `project.godot`
- Test: `tests/GameplayCoreTest.gd`

- [ ] **Step 1: 修改 `[autoload]`**

在 `project.godot` 的 `[autoload]` 区域中，`InputManager` 后面加入：

```ini
SaveManager="*res://src/app/SaveManager.gd"
```

目标片段应类似：

```ini
[autoload]

GameManager="*res://src/app/GameManager.gd"
InputManager="*res://src/app/InputManager.gd"
SaveManager="*res://src/app/SaveManager.gd"
DropManager="*res://src/gameplay/drops/DropManager.gd"
```

- [ ] **Step 2: 运行测试确认 autoload 注册不破坏启动**

Run:

```powershell
powershell -NoProfile -Command "& (Join-Path $env:LOCALAPPDATA 'Programs\Godot\godot.cmd') --headless --path . -s res://tests/GameplayCoreTest.gd"
```

Expected: `GameplayCoreTest.gd` 通过，且没有 `SaveManager` 解析错误。

- [ ] **Step 3: 提交 autoload 注册**

Run:

```powershell
git add project.godot
git commit -m "chore: register save manager autoload"
```

Expected: commit 成功。注意 `project.godot` 当前可能已有用户改动，提交前用 `git diff -- project.godot` 确认只包含新增 `SaveManager` 行；如果包含无关改动，先停下让主会话决定如何拆分。

### Task 5: 最终验证和交付检查

**Files:**
- Verify: `src/app/SaveManager.gd`
- Verify: `project.godot`
- Verify: `tests/GameplayCoreTest.gd`

- [ ] **Step 1: 运行 whitespace 检查**

Run:

```powershell
git diff --check
```

Expected: 无输出，退出码为 0。

- [ ] **Step 2: 运行完整 headless gameplay 测试**

Run:

```powershell
powershell -NoProfile -Command "& (Join-Path $env:LOCALAPPDATA 'Programs\Godot\godot.cmd') --headless --path . -s res://tests/GameplayCoreTest.gd"
```

Expected: 所有测试 PASS，输出包含新增 SaveManager 测试名。

- [ ] **Step 3: 检查最终 diff**

Run:

```powershell
git status --short
git diff -- src/app/SaveManager.gd project.godot tests/GameplayCoreTest.gd
```

Expected: 如果前面每个任务都已提交，三个目标文件没有未提交 diff。工作区仍可能显示其他早已存在的改动，不处理它们。

- [ ] **Step 4: 给主会话汇报**

汇报内容包含：

```text
Implemented SaveManager progress save system.
Verified with:
- git diff --check
- powershell -NoProfile -Command "& (Join-Path $env:LOCALAPPDATA 'Programs\Godot\godot.cmd') --headless --path . -s res://tests/GameplayCoreTest.gd"

Touched files:
- src/app/SaveManager.gd
- project.godot
- tests/GameplayCoreTest.gd
```

## 自检记录

- Spec 覆盖：计划覆盖单自动存档、JSON schema、公开 API、错误回退、autoload 注册、重置接口、隔离测试路径。
- 占位符扫描：未发现占位符类文本。
- 类型一致性：计划中 API 名称与 spec 一致；额外 `set_save_path_for_tests(path: String)` 只用于测试路径注入。
