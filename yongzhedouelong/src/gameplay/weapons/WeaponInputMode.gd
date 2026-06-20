@tool
class_name WeaponInputMode extends Resource
## 武器输入模式数据。描述「开火键如何被解读」，由 WeaponDriver/FlowRuntime 据此把
## 原始输入（按下/松开/持续）翻译成语义事件（WEAPON_FIRE_PRESSED/HELD/RELEASED）
## 喂给常驻开火 Flow。武器逻辑本身仍写在 Flow 里，这里只描述「输入节奏」。

enum Mode {
	CLICK,   ## 点击即发：按下瞬间发一次语义 PRESSED
	HOLD,    ## 长按连发：按住期间按 repeat_interval 周期发 HELD
	CHARGE,  ## 蓄力：按下开始蓄力(PRESSED)，松开释放(RELEASED)；蓄力时长由 Flow 自己计
}

@export_group("输入模式")
## 【模式】CLICK 点击即发 / HOLD 长按连发 / CHARGE 蓄力松开释放。
@export var mode: Mode = Mode.CLICK
## 【连发间隔】秒。仅 HOLD 模式：按住时每隔多久发一次 WEAPON_FIRE_HELD。
@export var repeat_interval: float = 0.12
## 【动作名】监听的输入动作（默认 "fire"）。
@export var action_name: StringName = &"fire"

func get_mode_name() -> String:
	match mode:
		Mode.CLICK: return "CLICK"
		Mode.HOLD: return "HOLD"
		Mode.CHARGE: return "CHARGE"
	return "UNKNOWN"
