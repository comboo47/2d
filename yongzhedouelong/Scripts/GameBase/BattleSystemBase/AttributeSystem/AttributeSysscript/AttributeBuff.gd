@tool
class_name AttributeBuff extends Resource
@export var buff_id:String

@export var buff_name: String
@export var buffDuration := 0.0
@export var buffPeriod := 0
@export var isLeaveReset := false


@export var BuffEffects:Array[AttributeBuffEffect]
		
func write_all_children_data():
	
	pass


func _init() -> void:
	pass
## duration_policy == HasDuration生效
## 单位：秒
@export var duration: float = 0.0
@export var merging := DurationMerging.Restart

var BuffSource:BattleActor 
var BuffTarget:BattleActor


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
	for effect in BuffEffects:
		effect.Create(_source,_target,self)
	buff_execute()
	execute_type()
func execute_type():
	match duration:
		0:
			is_pending_remove = true
	pass


func deep_duplicate(_source:BattleActor,_target:BattleActor) -> AttributeBuff:
	var duplicated_buff = self.duplicate(true)
	duplicated_buff.BuffSource = _source as BattleActor
	duplicated_buff.BuffTarget = _target as BattleActor
	#for effect in BuffEffects:
		#if effect:
			#duplicated_buff.BuffEffects.append(effect.duplicate(true))
	duplicated_buff.Create(_source,_target)
	return duplicated_buff


## 由应用目标属性驱动
func run_process(delta: float):
	if not is_pending_remove:
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



func set_merging(_mergin: DurationMerging):
	merging = _mergin


func set_duration(_time: float) -> AttributeBuff:
	return self
func buff_execute()->void:
	for effect in BuffEffects:
		effect.EffectGo()

func restart_duration():
	remaining_time = duration


func extend_duration(_time: float):
	remaining_time += _time
