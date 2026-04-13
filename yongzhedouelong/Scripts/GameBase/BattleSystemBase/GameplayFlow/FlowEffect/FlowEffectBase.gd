class_name FlowEffectBase extends Resource
## GameplayFlow 效果基类
## 所有具体效果（伤害、特效、Buff 等）继承此类

## 效果执行
## 子类必须重写此方法实现具体效果
func apply(context: GameplayFlowContext) -> void:
	push_warning("FlowEffectBase.apply() 未被子类实现")

## 效果清理（可选）
## 当 Flow 结束或被移除时调用
func cleanup(context: GameplayFlowContext) -> void:
	# 默认无清理逻辑，子类可重写
	pass

## 获取效果描述（用于调试/显示）
func get_description() -> String:
	return "未知效果"