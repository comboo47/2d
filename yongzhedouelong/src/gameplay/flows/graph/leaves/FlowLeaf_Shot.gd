extends FlowLeaf
class_name FlowLeaf_Shot
## 武器发射脚本叶子（第十三期，取代 Flow_WeaponShotBase）。
## 读 context 的调用情况（trigger_kind/charge_ratio，WeaponDriver 门控后打包）决定发射形态。
## 子弹归 skill：bullet_scene 在叶子上。子类（BowShot/BottleShot）重写 _shoot 决定速度/散射。

@export var bullet_scene: PackedScene
@export var base_speed: float = 250.0
@export var bullet_type: int = 0

func run(ctx: GameplayFlowContext, _host = null) -> void:
	_shoot(ctx)

## 默认单发 base_speed。子类重写。
func _shoot(ctx: GameplayFlowContext) -> void:
	emit_shot(ctx, base_speed, 1, 0.0)

func emit_shot(ctx: GameplayFlowContext, speed: float, count: int = 1, spread: float = 0.0) -> void:
	FlowActions.fire_projectile(ctx, {
		"bullet": bullet_scene,
		"speed": speed,
		"bullet_type": bullet_type,
		"spread_count": count,
		"spread_angle": spread,
	})

func charge_ratio(ctx: GameplayFlowContext) -> float:
	return float(ctx.event_data.get("charge_ratio", 0.0))
