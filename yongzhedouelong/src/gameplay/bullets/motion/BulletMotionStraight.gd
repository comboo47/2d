extends BulletMotionBase
## 直线无重力运动（对应旧 BulletType.STRAIGHT）。
## 初速由 BulletManager 设置，这里只关闭重力，不每帧干预。

func setup(bullet: RigidBody2D, _def) -> void:
	bullet.gravity_scale = 0.0
