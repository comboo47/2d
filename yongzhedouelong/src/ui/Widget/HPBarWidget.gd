class_name HPBarWidget extends Control

## 信号
signal value_changed(current: float, max_value: float)
signal value_depleted()

## 动画配置
@export var flash_duration: float = 0.1
@export var low_hp_threshold: float = 0.3  # 30%以下为低血量

## 状态
var _current_value: float = 0.0
var _max_value: float = 100.0
var _is_low_hp: bool = false

func update_value(current: float, max_value: float) -> void:
	_current_value = current
	_max_value = max_value

	# 检查节点是否存在
	var progress_bar = get_node_or_null("ProgressBar")
	var hp_label = get_node_or_null("HpLabel")

	if progress_bar:
		progress_bar.max_value = max_value
		progress_bar.value = current

	if hp_label:
		hp_label.text = str(int(current))

	# 低血量警告
	if max_value > 0:
		var hp_ratio = current / max_value
		if hp_ratio <= low_hp_threshold and not _is_low_hp:
			_trigger_low_hp_warning()
		elif hp_ratio > low_hp_threshold:
			_is_low_hp = false
			modulate = Color.WHITE

	if current <= 0:
		value_depleted.emit()

	value_changed.emit(current, max_value)

func _trigger_low_hp_warning() -> void:
	_is_low_hp = true
	_flash_low_hp()

func _flash_low_hp() -> void:
	if not _is_low_hp:
		return

	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate", Color.RED, flash_duration)
	tween.tween_property(self, "modulate", Color.WHITE, flash_duration)

func reset() -> void:
	_is_low_hp = false
	modulate = Color.WHITE
	update_value(_max_value, _max_value)

## 获取当前 HP 比例
func get_hp_ratio() -> float:
	if _max_value <= 0:
		return 0.0
	return _current_value / _max_value