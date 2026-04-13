class_name FE_ApplyBuff extends FlowEffectBase
## 应用 Buff 效果
## 对目标应用指定的 Buff

## Buff ID（从 DataRegistry 获取）
@export var buff_id: String = ""

## 是否使用 source 作为 Buff 来源
@export var use_source_as_buff_owner: bool = true

## Buff 持续时间覆盖（可选，-1 表示使用 Buff 默认时长）
@export var duration_override: float = -1.0

## 执行 Buff 应用
func apply(context: GameplayFlowContext) -> void:
	if context.target == null:
		push_warning("FE_ApplyBuff: 目标为空，无法应用 Buff")
		return

	if buff_id.is_empty():
		push_warning("FE_ApplyBuff: buff_id 为空")
		return

	# 确定 Buff 来源
	var buff_source = context.source if use_source_as_buff_owner else null

	# 通过 BattleManager 应用 Buff
	BattleManager.ApplyBuff(buff_source, context.target, buff_id)

func get_description() -> String:
	if buff_id.is_empty():
		return "应用 Buff（未配置 ID）"
	return "应用 Buff: %s" % buff_id