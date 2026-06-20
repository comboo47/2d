class_name WeaponRuntimeState extends RefCounted
## 武器运行时状态（第十二期）。能量/蓄力/冷却的单一真相，从 fire_flow 私有 var 上移到
## Weapon 模块，纯逻辑可单测。WeaponDriver 持有一个，对外暴露只读 + 发信号供 UI。
## 「能不能发」的门控判定用这里的状态；扣能量也在这里。

var max_energy: float = 0.0
var energy: float = 0.0
var energy_regen: float = 0.0

func setup(p_max_energy: float, p_regen: float) -> void:
	max_energy = p_max_energy
	energy_regen = p_regen
	energy = p_max_energy

## 每帧能量回复（封顶 max）。返回能量是否变化（供 Driver 决定是否发信号）。
func regen(delta: float) -> bool:
	if energy >= max_energy:
		return false
	energy = minf(max_energy, energy + energy_regen * delta)
	return true

func has_energy(cost: float) -> bool:
	return energy >= cost

## 扣能量（不为负）。返回是否变化。
func consume(cost: float) -> bool:
	if cost <= 0.0:
		return false
	energy = maxf(0.0, energy - cost)
	return true

func energy_ratio() -> float:
	if max_energy <= 0.0:
		return 1.0
	return clampf(energy / max_energy, 0.0, 1.0)
