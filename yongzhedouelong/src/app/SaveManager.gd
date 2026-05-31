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
	var write_error := file.get_error()
	if write_error != OK:
		push_error("SaveManager: failed to write save file: %s (error %d)" % [save_path, write_error])
		return false

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
	var raw_schema_version = raw_progress.get("schema_version", 0)
	if not (raw_schema_version is int or raw_schema_version is float):
		return _default_progress()

	if raw_schema_version != SCHEMA_VERSION:
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
