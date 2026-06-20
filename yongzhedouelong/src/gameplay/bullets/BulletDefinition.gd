class_name BulletDefinition extends Resource
## 子弹数据定义：把一颗子弹的可调项（外观、伤害、运动、命中行为）抽成资源。
## 一个 .tres = 一种子弹。运行时由 BulletManager 在子弹实例化后通过
## BulletBase.apply_definition() 应用。存放目录：res://resources/gameplay/bullets/

#region 标识
@export_group("标识")
## 【子弹ID】注册表主键，必填且唯一。BulletRegistry 以此索引这颗子弹，武器通过它引用。
@export var bullet_id: String = ""
## 【显示名称】编辑器与调试用的可读名称，例如「火焰箭」。不影响逻辑。
@export var display_name: String = ""
#endregion

#region 外观
@export_group("外观")
## 【子弹场景】这颗子弹的视觉/碰撞/动画来源（RigidBody2D 场景）。优先级最高，
## 武器发射时用它替换默认子弹场景。决定子弹「长什么样、用什么碰撞体」。
@export var bullet_scene: PackedScene
## 【动画帧】可选。覆盖子弹场景内 AnimatedSprite2D 的动画帧，用同一场景换皮肤。
@export var sprite_frames: SpriteFrames
## 【静态贴图】可选。无动画时的静态贴图回退（一般留空，走子弹场景自带）。
@export var texture: Texture2D
## 【染色】可选。非白色时给子弹精灵叠加颜色，可做「红色火弹/蓝色冰弹」等变体。
@export var modulate: Color = Color.WHITE
#endregion

#region 战斗数值
@export_group("战斗数值")
## 【基础伤害】命中目标造成的伤害值，注入子弹后经 DamageResolver 结算。
@export var base_damage: float = 10.0
## 【附带BuffID】命中时给目标附加的状态 Buff（如燃烧、减速）的 ID；留空则不附加。
@export var damage_buff_id: String = "1001"
## 【飞行速度】子弹速度参考值；实际初速由武器蓄力/BulletManager 决定，此处主要作元数据。
@export var speed: float = 250.0
## 【存活时间】秒。子弹生成后多久自动销毁（对应子弹场景里的 Timer）。防止飞出屏幕不回收。
@export var lifetime: float = 10.0
#endregion

#region 运动
@export_group("运动")
## 【运动方式】运动策略名（见 BulletMotionRegistry）：straight直线 / gravity抛物线 /
## homing追踪 / piercing穿透 / explosive爆炸。留空＝沿用引擎默认物理。
@export var motion_key: StringName = &""
## 【子弹类型】传给 BulletManager 的物理类型：NORMAL 受重力下坠 / STRAIGHT 无重力直射。
@export var bullet_type: WeaponConfig.BulletType = WeaponConfig.BulletType.NORMAL
## 【重力缩放覆盖】>=0 时强制设定子弹重力倍数（0＝完全无重力）；< 0＝不覆盖，沿用场景值。
@export var gravity_scale_override: float = -1.0
#endregion

#region 命中行为
@export_group("命中行为")
## 【穿透次数】0＝命中即销毁；>0＝可连续穿透 N 个目标后才销毁，做「贯穿箭」效果。
@export var pierce_count: int = 0
## 【范围伤害半径】>0 时命中点对周围 BoomArea 内的所有目标结算伤害（子弹场景需含 BoomArea）。
@export var aoe_radius: float = 0.0
## 【命中爆炸】命中时是否触发爆炸表现/范围结算，配合范围伤害半径使用。
@export var explode_on_hit: bool = false
#endregion

#region 特质
@export_group("特质")
## 【特质列表】此子弹携带的特质 id（按 TraitRegistry 名引用，如 "trait_bounce"）。
## 弹射/分裂/缩放等行为通过特质叠加；空 = 无特质（行为与改造前一致）。
@export var traits: Array[String] = []
#endregion

## 校验定义完整性，返回错误描述列表（空 = 通过）。供编辑器 Validate 用。
func validate() -> Array[String]:
	var errors: Array[String] = []
	if bullet_id.strip_edges().is_empty():
		errors.append("bullet_id 不能为空")
	if bullet_scene == null and sprite_frames == null and texture == null:
		errors.append("至少需要 bullet_scene / sprite_frames / texture 之一作为外观来源")
	if not String(motion_key).is_empty() and not BulletMotionRegistry.has(motion_key):
		errors.append("motion_key '%s' 未在 BulletMotionRegistry 注册" % motion_key)
	if not traits.is_empty():
		var reg = Engine.get_main_loop().root.get_node_or_null("TraitRegistry") if Engine.get_main_loop() else null
		if reg != null:
			for tid in traits:
				if not reg.has(tid):
					errors.append("trait '%s' 未在 TraitRegistry 注册" % tid)
	return errors

## 解析子弹场景：定义里有 bullet_scene 就用它，否则回退到武器原有的 PackedScene。
static func resolve_scene(def: BulletDefinition, fallback: PackedScene) -> PackedScene:
	if def != null and def.bullet_scene != null:
		return def.bullet_scene
	return fallback
