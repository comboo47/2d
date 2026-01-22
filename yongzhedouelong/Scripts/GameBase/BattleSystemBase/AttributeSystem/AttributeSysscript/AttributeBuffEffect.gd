class_name AttributeBuffEffect extends Resource

@export var expression:String
var _compilation_successful: bool = false
var _last_evaluation: float = 0.0

var source:BattleActor
var target:BattleActor
var buff:AttributeBuff

# 简化参数列表，只传递对象引用
var param_names:PackedStringArray =[
	"source",
	"target",
	"buff"
]

var _cached_expression: Expression = null
var _cached_expression_string: String = ""

func EffectGo():
	print("effectGo")	
	pass
	
func EffectRemove():
	pass
	
func Create(_source:BattleActor,_target:BattleActor,_buff:AttributeBuff = null):
	source = _source
	target = _target
	if _buff:
		buff = _buff
	pass

# 添加表达式预处理方法
func _preprocess_expression(expr_string: String) -> String:
	var processed = expr_string
	
	# 清理表达式中的多余空格
	while processed.find("  ") != -1:
		processed = processed.replace("  ", " ")
	
	# 手动去除首尾空格
	while processed.begins_with(" "):
		processed = processed.substr(1)
	while processed.ends_with(" "):
		processed = processed.substr(0, processed.length() - 1)
	
	return processed

# 解析表达式并计算结果
func _compile_expression():
	if not expression:
		return
	
	# 预处理表达式，清理空格
	var processed_expression = _preprocess_expression(expression)
	
	# 检查是否需要重新编译
	if _cached_expression and _cached_expression_string == processed_expression:
		# 使用缓存的表达式
		_last_evaluation = evaluate(_cached_expression)
		return
	
	# 尝试直接编译表达式
	var expr = Expression.new()
	var error = expr.parse(processed_expression, param_names)
	_compilation_successful = error == OK
	
	if not _compilation_successful:
		# 如果编译失败，尝试简化处理
		_compilation_successful = _try_simplified_expression(processed_expression)
	else:
		# 缓存表达式
		_cached_expression = expr
		_cached_expression_string = processed_expression
		_last_evaluation = evaluate(expr)

# 尝试使用简化的表达式处理
func _try_simplified_expression(expr_string: String) -> bool:
	# 检查是否是基本的条件表达式格式
	if expr_string.find(" ? ") != -1:
		var parts = expr_string.split(" ? ")
		if parts.size() == 2:
			var condition = parts[0]
			var result_parts = parts[1].split(" : ")
			if result_parts.size() == 2:
				var true_value = result_parts[0]
				var false_value = result_parts[1]
				
				# 尝试直接计算结果
				if _evaluate_conditional(condition, true_value, false_value):
					return true
	
	# 尝试直接计算数值表达式
	if _evaluate_numeric_expression(expr_string):
		return true
	
	# 编译失败
	var buff_name = buff.buff_Name if buff else "Unknown"
	push_error("表达式编译失败: 无法处理表达式格式 (Expression: %s)" % [expression])
	return false

# 计算条件表达式
func _evaluate_conditional(condition_str: String, true_value_str: String, false_value_str: String) -> bool:
	# 编译条件表达式
	var condition_expr = Expression.new()
	var error = condition_expr.parse(condition_str, param_names)
	if error != OK:
		return false
	
	# 执行条件表达式
	var params = [source, target, buff]
	var condition_result = condition_expr.execute(params, self)
	if condition_expr.has_execute_failed():
		return false
	
	# 确定使用哪个值
	var value_str = true_value_str if condition_result else false_value_str
	
	# 编译并执行值表达式
	var value_expr = Expression.new()
	error = value_expr.parse(value_str, param_names)
	if error != OK:
		# 尝试将值解析为常量
		var value = float(value_str)
		if not is_nan(value):
			_last_evaluation = value
			_compilation_successful = true
			return true
		return false
	
	# 执行值表达式
	var value_result = value_expr.execute(params, self)
	if value_expr.has_execute_failed():
		return false
	
	_last_evaluation = float(value_result)
	_compilation_successful = true
	return true

# 计算数值表达式
func _evaluate_numeric_expression(expr_string: String) -> bool:
	var expr = Expression.new()
	var error = expr.parse(expr_string, param_names)
	if error != OK:
		return false
	
	var params = [source, target, buff]
	var result = expr.execute(params, self)
	if expr.has_execute_failed():
		return false
	
	_last_evaluation = float(result)
	_compilation_successful = true
	return true

## 评估表达式
func evaluate(expr:Expression) -> float:
	# 验证对象是否有效
	if not source:
		push_error("表达式执行失败: source对象为空 (Expression: %s)" % expression)
		return 0.0
	if not target:
		push_error("表达式执行失败: target对象为空 (Expression: %s)" % expression)
		return 0.0
	if not buff:
		push_error("表达式执行失败: buff对象为空 (Expression: %s)" % expression)
		return 0.0
	
	# 准备参数
	var params = [source, target, buff]
	
	# 执行表达式，传递self作为this_instance参数
	var result = expr.execute(params, self)
	
	if expr.has_execute_failed():
		var error_msg = "表达式执行失败: %s" % expr.get_error_text()
		var buff_name = buff.buff_Name if buff else "Unknown"
		push_error("%s (Buff: %s, Expression: %s)" % [error_msg, buff_name, expression])
		return 0.0
	
	_last_evaluation = float(result)
	return _last_evaluation

# 验证表达式是否有效
func validate_expression() -> bool:
	if not expression:
		push_error("表达式为空")
		return false
	
	# 预处理表达式，清理空格
	var processed_expression = _preprocess_expression(expression)
	
	# 尝试直接编译
	var expr = Expression.new()
	var error = expr.parse(processed_expression, param_names)
	if error == OK:
		return true
	
	# 尝试简化处理
	if _try_simplified_expression(processed_expression):
		return true
	
	return false

# 预览表达式结果
func preview_expression() -> float:
	if not validate_expression():
		return 0.0
	
	# 重新编译以获取最新结果
	_compile_expression()
	return _last_evaluation
