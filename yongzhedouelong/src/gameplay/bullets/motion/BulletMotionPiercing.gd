extends BulletMotionBase
## 穿透弹运动（脚手架）：运动本身为直线无重力；
## 真正的"穿透 N 个目标不销毁"由 BulletDefinition.pierce_count 在 BulletBase 命中时消耗
## （见 BulletBase._consume_pierce）。这里只负责关闭重力让弹道笔直。

func setup(bullet: RigidBody2D, _def) -> void:
	bullet.gravity_scale = 0.0
