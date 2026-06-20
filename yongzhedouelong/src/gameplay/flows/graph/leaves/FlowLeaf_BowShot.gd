extends FlowLeaf_Shot
class_name FlowLeaf_BowShot
## 弓发射叶子：速度随 charge_ratio 在 base..max lerp，单发。

@export var max_charge_speed: float = 650.0

func _shoot(ctx: GameplayFlowContext) -> void:
	emit_shot(ctx, _speed_for(ctx), 1, 0.0)

## 蓄力程度→速度（base..max lerp）。抽出供测试。
func _speed_for(ctx: GameplayFlowContext) -> float:
	return lerpf(base_speed, max_charge_speed, charge_ratio(ctx))
