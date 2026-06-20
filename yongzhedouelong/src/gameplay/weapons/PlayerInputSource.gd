class_name PlayerInputSource extends WeaponInputSource
## 玩家武器输入源：经 InputManager 查询动作（含锁定 + 游戏状态门控）。
## 取代 Player._process 里手写的 is_action_just_pressed("fire")→hold_fire 逻辑。

func is_pressed(action_name: StringName) -> bool:
	var im = Engine.get_main_loop().root.get_node_or_null("InputManager") if Engine.get_main_loop() else null
	if im == null:
		return false
	return im.is_action_pressed(String(action_name))
