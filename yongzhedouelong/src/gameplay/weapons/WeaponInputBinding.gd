class_name WeaponInputBinding extends Resource
## 武器输入绑定（第十二期）。一条绑定 = 一个输入动作 → 用什么节奏 → 激活哪个 skill。
## 武器持 Array[WeaponInputBinding]：主攻 fire / 副攻 fire_secondary / 技能键 skill_1 …
## WeaponDriver 为每条绑定建一个 WeaponCadenceRunner，按节奏到点 → 门控 → skill.use(context)。

## 监听的输入动作名（Godot InputMap action）。
@export var action_name: StringName = &"fire"
## 节奏（单发/连发/蓄力/蓄力转连发 + 参数）。
@export var cadence: WeaponCadence
## 激活的技能（完整 SkillBase；开火 skill 配 cost=NONE/cd=0，门控归 Weapon）。
@export var skill: SkillBase
## 该绑定的开火是否消耗武器能量（能量门控归 Weapon，cost 在武器侧判）。
@export var consume_energy: bool = false
## 单发能耗（consume_energy=true 时用）。
@export var energy_cost: float = 0.0
