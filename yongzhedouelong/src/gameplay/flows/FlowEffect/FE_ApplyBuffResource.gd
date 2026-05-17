class_name FE_ApplyBuffResource extends FlowEffectBase

@export var buff: AttributeBuff
@export var use_source_as_buff_owner: bool = true
@export var apply_to_source: bool = false

func apply(context: GameplayFlowContext) -> void:
	if context == null or buff == null:
		return

	var target := context.source if apply_to_source else context.target
	if target == null or target.buffManager == null:
		return

	var source := context.source if use_source_as_buff_owner else target
	var runtime_buff := target.buffManager.apply_buff(buff, source, target)
	if runtime_buff:
		context.buff = runtime_buff
		context.event_data["applied_buff_id"] = runtime_buff.get_runtime_id()

func get_description() -> String:
	if buff == null:
		return "Apply buff resource"
	return "Apply buff resource: %s" % buff.get_runtime_id()
