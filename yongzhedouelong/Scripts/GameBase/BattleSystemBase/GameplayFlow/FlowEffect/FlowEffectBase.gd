class_name FlowEffectBase extends Resource

@export var priority: int = 0

func apply(context: GameplayFlowContext) -> void:
	push_warning("FlowEffectBase.apply() should be implemented by subclasses.")

func cleanup(context: GameplayFlowContext) -> void:
	pass

func get_description() -> String:
	return "Flow effect"
