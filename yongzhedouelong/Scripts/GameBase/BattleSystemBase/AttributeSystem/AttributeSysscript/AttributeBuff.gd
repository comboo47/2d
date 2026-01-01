@tool
class_name AttributeBuff extends Resource
@export var name:String
@export var buff_id:String

@export var buff_name: String
@export var operation := AttributeModifier.OperationType.ADD
@export var value := 0.0
@export var policy := DurationPolicy.Infinite

var buffeffect = []

@export var BuffEffects:Array[AttributeBuffEffect]
		
func write_all_children_data():
	buffeffect = []
	for item in BuffEffects:
		buffeffect.append(item.duplicate(true))
	for item in BuffEffects:
		print(item.expression)

func ensure_children_loaded() -> void:
	if BuffEffects.is_empty():
		print("检测到子资源数组为空，尝试强制重新加载属性...")
		# 1. 通知引擎属性列表需要刷新（这是关键触发点）
		notify_property_list_changed()
		# 2. 强制让引擎重新获取此属性，通常会触发正确的反序列化

func _init() -> void:
	print("buff资源加载结束")
	pass
## duration_policy == HasDuration生效
## 单位：秒
@export var duration: float = 0.0
@export var merging := DurationMerging.Restart

var BuffSource:BattleActor 
var BuffTarget:BattleActor

enum DurationPolicy {
	Infinite,		## 持久地
	HasDuration,	## 有时效性地
	Period,			## 周期性地
}

enum DurationMerging {
	Restart,	## 重新开始计算时长
	Addtion,	## 新的时长叠加到现有时效上
	NoEffect,	## 对现有时效无任何影响
}

var attribute_modifier: AttributeModifier
var remaining_time: float
var is_pending_remove := false
var applied_attribute:
	get():
		return applied_attribute.get_ref() if is_instance_valid(applied_attribute) else null

#func _init(_operation := AttributeModifier.OperationType.ADD, _value: float = 0.0, _name := ""):
	#attribute_modifier = AttributeModifier.new(_operation, _value)
	#operation = _operation
	#value = _value
	#buff_name = _name
func Create(_source:BattleActor,_target:BattleActor):
	BuffSource = _source
	BuffTarget = _target

func deep_duplicate() -> AttributeBuff:
	var duplicated_buff = self.duplicate(true)
	for effect in buffeffect:
		if effect:
			duplicated_buff.buffeffect.append(effect.duplicate(true))
	return duplicated_buff


## 由应用目标属性驱动
func run_process(delta: float):
	if has_duration() and not is_pending_remove:
		remaining_time = max(remaining_time - delta, 0.0)
		if is_zero_approx(remaining_time):
			is_pending_remove = true


#static func add(_value: float = 0.0, _name := "") -> AttributeBuff:
	#return AttributeBuff.new(AttributeModifier.OperationType.ADD, _value, _name)
#
#
#static func sub(_value: float = 0.0, _name := "") -> AttributeBuff:
	#return AttributeBuff.new(AttributeModifier.OperationType.SUB, _value, _name)
#
#
#static func mult(_value: float = 0.0, _name := "") -> AttributeBuff:
	#return AttributeBuff.new(AttributeModifier.OperationType.MULT, _value, _name)
#
#
#static func div(_value: float = 0.0, _name := "") -> AttributeBuff:
	#return AttributeBuff.new(AttributeModifier.OperationType.DIVIDE, _value, _name)


func operate(base_value: float) -> float:
	return attribute_modifier.operate(base_value)


func has_duration() -> bool:
	return policy == DurationPolicy.HasDuration


func set_merging(_mergin: DurationMerging):
	merging = _mergin


func set_duration(_time: float) -> AttributeBuff:
	duration = _time
	remaining_time = duration
	if duration > 0.0:
		policy = DurationPolicy.HasDuration
	return self
func buff_excute()->void:
	print(buffeffect.size())
	for effect in buffeffect:
		effect.EffectGo()

func restart_duration():
	remaining_time = duration


func extend_duration(_time: float):
	remaining_time += _time
