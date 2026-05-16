class_name SkillEffectBase extends Resource
## 技能效果基类
## 所有技能效果继承此类，定义技能执行的具体效果

## 效果优先级（用于排序执行）
@export var priority: int = 0

## 执行效果
## 子类必须重写此方法
func apply(context: GameplayFlowContext, skill: SkillBase) -> void:
	push_warning("SkillEffectBase.apply() 未被子类实现")

## 效果清理（可选）
func cleanup(context: GameplayFlowContext, skill: SkillBase) -> void:
	pass

## 获取效果描述（调试用）
func get_description() -> String:
	return "未知技能效果"