class_name FE_SpawnVfx extends FlowEffectBase
## 生成特效效果
## 在指定位置播放特效

## 特效类型
@export var vfx_type: VfxConfig.VfxType = VfxConfig.VfxType.HIT_IMPACT

## 位置偏移
@export var position_offset: Vector2 = Vector2.ZERO

## 是否跟随目标
@export var follow_target: bool = false

## 执行特效播放
func apply(context: GameplayFlowContext) -> void:
	if VfxManager.instance == null:
		push_warning("FE_SpawnVfx: VfxManager 未初始化")
		return

	# 检查特效是否可用
	if not VfxManager.instance.is_vfx_available(vfx_type):
		push_warning("FE_SpawnVfx: 特效类型 %s 不可用" % VfxConfig.get_type_name(vfx_type))
		return

	# 计算位置
	var spawn_position = context.get_position() + position_offset

	# 播放特效
	if follow_target and context.target:
		VfxManager.instance.play_vfx_follow(vfx_type, context.target, position_offset)
	else:
		VfxManager.instance.play_vfx(vfx_type, spawn_position)

func get_description() -> String:
	return "播放特效: %s" % VfxConfig.get_type_name(vfx_type)