class_name PopDamageWidget extends Control

@export var numberList: Array[Resource]
@onready var h_box_container: HBoxContainer = $Path2D/PathFollow2D/HBoxContainer
@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D
@onready var timer: Timer = $Timer

var damageValue = []
var popPosition: Vector2 = Vector2.ZERO
var _is_active: bool = false
# 注意：timer.timeout 信号已在 PopDamage.tscn 中连接到 _on_timer_timeout

## 初始化伤害显示
func init(_actor: BattleActor, _damageNumber: float = 15) -> void:
	popPosition = _actor.global_position + Vector2(0, -12) + Vector2(randf() * 7.5, randf() * 7.5)
	damageValue = split_number_to_list_str(int(ceil(_damageNumber)))
	_setup_digits()

func _setup_digits() -> void:
	# 清除旧数字
	for child in h_box_container.get_children():
		child.queue_free()

	# 创建数字显示
	for num in damageValue:
		var numResource = numberList[num].duplicate(true)
		var textureRect: TextureRect = TextureRect.new()
		textureRect.texture = numResource
		textureRect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		h_box_container.add_child(textureRect)

## 是否正在使用
func is_active() -> bool:
	return _is_active

## 显示伤害动画
func pop_damage() -> void:
	_is_active = true
	set_process(true)
	self.global_position = popPosition
	path_follow_2d.progress_ratio = 0.0

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(path_follow_2d, "progress_ratio", 1, 0.5)
	tween.play()

	timer.start()

## 重置状态（用于池化回收）
func reset() -> void:
	_is_active = false
	set_process(false)
	damageValue.clear()
	popPosition = Vector2.ZERO
	path_follow_2d.progress_ratio = 0.0

	# 清除所有数字
	for child in h_box_container.get_children():
		child.queue_free()

func split_number_to_list_str(num: int) -> Array:
	# 处理0的特殊情况
	if num == 0:
		return [0]
	# 转为字符串并去除负号，遍历每个字符转为数字
	var num_str = str(abs(num))
	var digit_list = []
	for char in num_str:
		digit_list.append(int(char))
	return digit_list

func _on_timer_timeout() -> void:
	_is_active = false
	reset()
	# 不再 queue_free，由 UIManager 池化管理
