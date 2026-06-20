class_name WeaponCadence extends Resource
## 武器开火节奏（第十二期）。把"原始输入怎么变成开火时机"数据化——
## 几种标准节奏（单发/连发/蓄力/蓄力转连发）+ 参数。由 WeaponCadenceRunner 解读执行。
## 罕见怪节奏不在此表达，走 weapon_flow / skill flow 自管（逃生口）。
##
## 节奏只管"何时产生一次开火意图"（含蓄力时长、射速门控/缓冲）；
## "能不能发"的能量判定与"发什么"的形态由 Weapon 门控 / skill flow 负责。

enum Mode {
	CLICK,           # 点击即发：按下发一次
	HOLD,            # 长按连发：按下发一次 + 按住期间每 repeat_interval 发一次
	CHARGE,          # 蓄力：按下蓄力，松开发一次（带蓄力程度）
	CHARGE_TO_HOLD,  # 蓄力转连发：蓄力达阈值后每 repeat_interval 连发；未达阈值就松开则单发
}

## 节奏模式
@export var mode: Mode = Mode.CLICK
## 连发间隔（秒，HOLD / CHARGE_TO_HOLD 用）
@export var repeat_interval: float = 0.12
## 蓄力阈值（秒，CHARGE 用作 ratio 归一基准；CHARGE_TO_HOLD 用作转连发的门槛）
@export var charge_threshold: float = 0.7
## 射速上限（秒，最短开火间隔；0=不限）。冷却内的开火意图缓冲一发，冷却结束补发。
@export var min_fire_interval: float = 0.0
