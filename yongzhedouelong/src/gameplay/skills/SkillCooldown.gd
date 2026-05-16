class_name SkillCooldown extends RefCounted
## 技能冷却管理
## 管理单个技能的冷却计时器

## 冷却时间（秒）
var cooldown_time: float = 0.0

## 剩余冷却时间（秒）
var remaining_cooldown: float = 0.0

## 是否正在冷却
var is_cooling: bool = false

## 冷却完成信号
signal cooldown_finished()

## 初始化冷却时间
func init(duration: float) -> void:
	cooldown_time = duration
	remaining_cooldown = 0.0
	is_cooling = false

## 开始冷却
func start() -> void:
	if cooldown_time > 0.0:
		remaining_cooldown = cooldown_time
		is_cooling = true

## 更新冷却（每帧调用）
func update(delta: float) -> void:
	if not is_cooling:
		return

	remaining_cooldown -= delta

	if remaining_cooldown <= 0.0:
		remaining_cooldown = 0.0
		is_cooling = false
		cooldown_finished.emit()

## 强制结束冷却
func force_end() -> void:
	remaining_cooldown = 0.0
	is_cooling = false

## 重置冷却（重新开始）
func reset() -> void:
	start()

## 是否可用（冷却结束）
func is_ready() -> bool:
	return not is_cooling

## 获取冷却进度（0.0 - 1.0，1.0 表示可用）
func get_progress() -> float:
	if cooldown_time <= 0.0:
		return 1.0
	return 1.0 - (remaining_cooldown / cooldown_time)

## 获取剩余冷却时间
func get_remaining() -> float:
	return remaining_cooldown

## 设置冷却时间
func set_cooldown_time(duration: float) -> void:
	cooldown_time = duration