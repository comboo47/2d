class_name WeaponInputSource extends RefCounted
## 武器输入源抽象（第十二期）。把"开火输入从哪来"与武器逻辑解耦——
## 玩家走 InputManager、敌人 AI 走脚本驱动，WeaponDriver 只问 is_pressed(action)。
## 这样武器开火不再写死在 Player._process，敌人也能装武器开火。
##
## Driver 每帧对每条 binding 的 action 调 is_pressed()，自己算 press/release 边沿喂节奏机。

## 该 action 当前是否按下。子类实现。
func is_pressed(_action_name: StringName) -> bool:
	return false
