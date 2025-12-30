class_name AttributeBuffEffect extends Resource


@export var expression:String
var _compilation_successful: bool = false
var _last_evaluation: float = 0.0

var source:BattleActor
var target:BattleActor

var param_names:PackedStringArray =[
	"source",
	"target",
	"atk",
	"armor",
	"hp"
]

func _init(_source:BattleActor,_target:BattleActor) -> void:
	source = _source
	target = _target
	_compile_expression()
func EffectGo():
	pass
	
func EffectRemove():
	pass
	
func Create():
	pass

func _compile_expression():
	var expr
	if not expression:
		expr = Expression.new()
		var error = expr.parse(expression, param_names)
		_compilation_successful = error == OK
		if not _compilation_successful:
			push_error("表达式编译失败: %s" % expr.get_error_text())
## 评估表达式
func evaluate(expr:Expression) -> float:
	# 准备变量
	var source_dict = source.get_all_attributes() if source else {}
	var target_dict = target.get_all_attributes() if target else {}
	
	# 执行表达式
	var result = expr.execute(
		[source_dict, target_dict],	
		null,
		true
	)
	
	if expr.has_execute_failed():
		push_error("表达式执行失败")
		return 0.0
	
	_last_evaluation = float(result)
	return _last_evaluation
