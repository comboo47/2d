extends BulletMotionBase
## 爆炸弹运动（脚手架）：运动为受重力抛射（保持基类空实现）。
## 命中时的范围伤害由 BulletDefinition.aoe_radius / explode_on_hit 在 BulletBase 处理
## （需要子弹场景内有 BoomArea 节点，参考 bullet_bottle.tscn）。
