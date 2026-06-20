extends FlowLeaf_Shot
class_name FlowLeaf_BottleShot
## 瓶发射叶子：蓄满（charge_ratio≥1）散射三发，否则单发。速度恒定 base_speed。

## 散射半角（弧度），散射时总角 = 2*spread_angle。
@export var spread_angle: float = 0.25

func _shoot(ctx: GameplayFlowContext) -> void:
	if charge_ratio(ctx) >= 1.0:
		emit_shot(ctx, base_speed, 3, spread_angle * 2.0)
	else:
		emit_shot(ctx, base_speed, 1, 0.0)
