extends Node2D

class_name WeaponBase

## 统一的武器发射信号
## 参数: bullet(PackedScene), spawn_position(Vector2), direction(Vector2), speed(float), bullet_type(int)
signal weapon_fired(bullet, spawn_position, direction, speed, bullet_type)

@export var bullet: PackedScene
@export var owner_actor: CharacterBody2D

var _aim_direction: Vector2 = Vector2.RIGHT
var _aim_mouse_pos: Vector2 = Vector2.ZERO
var _default_speed: float = 250.0
var _is_holding: bool = false

func _process(_delta: float) -> void:
	update_aim()

func update_aim() -> void:
	_aim_mouse_pos = get_viewport().get_mouse_position()
	if owner_actor:
		_aim_direction = (_aim_mouse_pos - owner_actor.global_position).normalized()
	look_at(_aim_mouse_pos)

func fire() -> void:
	# 子类重写此方法
	pass

func hold_fire() -> void:
	_is_holding = true
	# 子类重写此方法实现蓄力逻辑
	pass

func release_fire() -> void:
	_is_holding = false

func emit_weapon_fired(speed: float = _default_speed, bullet_type: int = 0) -> void:
	emit_signal("weapon_fired", bullet, global_position, _aim_direction, speed, bullet_type)