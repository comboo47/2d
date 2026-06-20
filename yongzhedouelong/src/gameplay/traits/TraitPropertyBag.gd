class_name TraitPropertyBag extends RefCounted
## 特质属性袋（每个 holder 一个）。动态字符串键的属性集合。
##
## 世界观：base 永不原地改；一切"变化"是可增删的修改源叠加；current = base 过修改源链算出。
## 仿 Attribute+buff 模型，复用 AttributeModifier（ADD/SUB/MULT/DIVIDE/PERCENTAGE/SET）。
## 支持可逆叠加：天赋加修改源 → 改变 current；天赋移除（按 source_id 移除修改源）→ current 自动还原。
##
## 这是特质系统的「属性层」，独立于角色的枚举制 Attribute（不侵入 AttributeSet）。

## 基础值 {name(String) → base(float)}。只由 set_base 写（声明属性时），modify 永不碰它。
var _base: Dictionary = {}

## 修改源 {name(String) → Array[Dictionary{source_id:String, mod:AttributeModifier}]}
## 按加入顺序结算；同 source_id 可批量移除（用于天赋/buff 撤销）。
var _modifiers: Dictionary = {}

## 声明/设置一个属性的基础值（特质 add 时灌入 declared_properties）。
func set_base(name: String, value: float) -> void:
	_base[name] = value

## 是否存在该属性（base 里有声明）。
func has(name: String) -> bool:
	return _base.has(name)

## 取当前值 = base 顺序过修改源链。无声明则返回 default（无声明属性 → 修改自然 no-op）。
func get_value(name: String, default: float = 0.0) -> float:
	if not _base.has(name):
		return default
	var v: float = _base[name]
	if _modifiers.has(name):
		for entry in _modifiers[name]:
			v = entry.mod.operate(v)
	return v

## 取基础值（不过修改源）。
func get_base(name: String, default: float = 0.0) -> float:
	return _base.get(name, default)

## 加一个修改源。op 用 AttributeModifier.OperationType；source_id 供成组移除（如某天赋/某buff）。
## 仅当该属性已被声明（base 存在）时才挂——保证"孤立修改无声明属性时 no-op"。
func add_modifier(name: String, op: int, value: float, source_id: String = "") -> void:
	if not _base.has(name):
		return  # 无声明属性 → 修改不生效（共享黑板语义）
	if not _modifiers.has(name):
		_modifiers[name] = []
	_modifiers[name].append({"source_id": source_id, "mod": AttributeModifier.create(op, value)})

## 按 source_id 移除该来源在所有属性上挂的修改源（天赋/buff 撤销时调，current 自动还原）。
func remove_modifiers_by_source(source_id: String) -> void:
	for name in _modifiers:
		var kept := []
		for entry in _modifiers[name]:
			if entry.source_id != source_id:
				kept.append(entry)
		_modifiers[name] = kept

## 移除某属性的全部修改源（保留 base）。
func clear_modifiers(name: String) -> void:
	_modifiers.erase(name)

## 直接改基础值（用于"运行时计数器"型属性，如弹射次数递减——它不是"修改源叠加"语义，
## 而是这颗子弹自己的状态消耗）。慎用：仅适合 holder 自身拥有的、非外部可逆的状态。
func set_base_raw(name: String, value: float) -> void:
	_base[name] = value

## 基础值递减（计数器型，如 bounce_count）。返回递减后的 base。
func decrement_base(name: String, by: float = 1.0) -> float:
	if not _base.has(name):
		return 0.0
	_base[name] = _base[name] - by
	return _base[name]

## 调试快照。
func to_dict() -> Dictionary:
	var out := {}
	for name in _base:
		out[name] = get_value(name)
	return out
