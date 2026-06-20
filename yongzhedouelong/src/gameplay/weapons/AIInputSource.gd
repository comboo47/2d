class_name AIInputSource extends WeaponInputSource
## AI 武器输入源：敌人 AI / 行为树通过 set_pressed(action, bool) 驱动开火。
## 让敌人也能用同一套武器开火链路（WeaponDriver 不关心输入来自玩家还是 AI）。

var _pressed: Dictionary = {}  # action_name(String) -> bool

func set_pressed(action_name: StringName, value: bool) -> void:
	_pressed[String(action_name)] = value

func is_pressed(action_name: StringName) -> bool:
	return _pressed.get(String(action_name), false)
