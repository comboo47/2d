class_name BulletMotionBase extends RefCounted
## 子弹运动策略基类（隔离扩展点）。
##
## 新增一种运动类型，三步即可，不需改 BulletManager / BulletBase / 武器子类：
##   1. 新建 BulletMotionXxx.gd extends BulletMotionBase，重写 setup()/process()。
##   2. 在 BulletMotionRegistry.TABLE 注册 &"xxx" -> 脚本路径。
##   3. 在某个 BulletDefinition.tres 里把 motion_key 设为 "xxx"。
##
## bullet 参数静态类型为 RigidBody2D；子弹自定义属性（bulletOwner 等）请用
## bullet.get("bulletOwner") 访问，避免静态类型检查报错。def 用弱类型以断开
## BulletDefinition <-> Registry <-> Motion 的静态引用环。

## 子弹生成后调用一次：读取定义、初始化重力/朝向等。
func setup(_bullet: RigidBody2D, _def) -> void:
	pass

## 每物理帧调用：驱动子弹运动（转向、加速等）。
func process(_bullet: RigidBody2D, _delta: float) -> void:
	pass
