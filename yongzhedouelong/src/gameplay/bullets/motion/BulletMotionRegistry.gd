class_name BulletMotionRegistry
## 子弹运动策略注册表（纯静态类，不进 autoload，避免加载顺序耦合）。
## 新增运动：在 TABLE 加一行 key -> 脚本路径即可（详见 BulletMotionBase 注释）。

const TABLE := {
	&"straight": "res://src/gameplay/bullets/motion/BulletMotionStraight.gd",
	&"gravity": "res://src/gameplay/bullets/motion/BulletMotionGravity.gd",
	&"homing": "res://src/gameplay/bullets/motion/BulletMotionHoming.gd",
	&"piercing": "res://src/gameplay/bullets/motion/BulletMotionPiercing.gd",
	&"explosive": "res://src/gameplay/bullets/motion/BulletMotionExplosive.gd",
}

## key 是否已注册（接受 String 或 StringName）。
static func has(key) -> bool:
	return TABLE.has(StringName(key))

## 按 key 创建运动策略实例；未注册返回 null。
static func create(key) -> BulletMotionBase:
	var k := StringName(key)
	if not TABLE.has(k):
		return null
	var motion_script = load(TABLE[k])
	if motion_script == null:
		return null
	return motion_script.new()

## 所有已注册的 key（供编辑器下拉/校验用）。
static func keys() -> Array:
	return TABLE.keys()
