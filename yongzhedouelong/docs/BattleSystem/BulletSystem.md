# 子弹系统说明文档

## BulletManager 单例架构

**核心文件**: [BulletManager.gd](../../src/gameplay/battle/BulletManager.gd)
**场景文件**: [bullet_manager.tscn](../../scenes/autoload/bullet_manager.tscn)

BulletManager 是一个简单的 Node2D 单例，负责处理子弹生成。它通过信号连接机制接收武器发射事件。

### 信号处理逻辑

```gdscript
func handle_bullet_spawn(bullet_packed, spawn_position, arg2, arg3, arg4, arg5=null, arg6=null):
    # 1. 实例化子弹
    var bullet = bullet_packed.instantiate() if bullet_packed is PackedScene else bullet_packed
    add_child(bullet)
    
    # 2. 设置位置
    bullet.global_position = spawn_position
    
    # 3. 新格式判断: arg2 是 direction(Vector2), arg3 是 speed(float)
    if arg2 is Vector2 and arg3 is float:
        bullet.rotation = arg2.angle()
        var bullet_type = arg4 if arg4 is int else 0
        var owner = arg5 if arg5 is BattleActor else null
        
        # 设置 owner
        if "bulletOwner" in bullet:
            bullet.bulletOwner = owner
        
        # 根据子弹类型设置物理
        if bullet_type == WeaponConfig.BulletType.STRAIGHT:
            # 无重力直射
            bullet.gravity_scale = 0
            bullet.linear_velocity = arg2.normalized() * arg3
        else:
            # 有重力
            bullet.set_axis_velocity(arg2.normalized() * arg3)
    
    # 4. 旧格式兼容处理...
```

### 新旧格式兼容

| 格式 | arg2 | arg3 | arg4 | arg5 | arg6 |
|------|------|------|------|------|------|
| 新格式 | direction (Vector2) | speed (float) | bullet_type (int) | owner (BattleActor) | - |
| 旧格式1 | rotation (float) | direction (Vector2) | type (int) | owner (BattleActor) | owner |
| 旧格式2 | rotation (float) | direction (Vector2) | speed (float) | - | - |

---

## 子弹生成流程图

```
用户按下 fire 键
      │
      ▼
Player.gd:
  weapon.hold_fire()  →  开始蓄力
      │
      ▼
用户释放 fire 键
      │
      ▼
Player.gd:
  weapon.fire()  →  子类实现发射逻辑
      │
      ▼
WeaponBase.emit_bullet():
  emit_signal("weapon_fired", bullet, position, direction, speed, type, owner)
      │
      ▼
WeaponRoot (已连接信号):
  weapon_fired ──▶ BulletManager.handle_bullet_spawn
      │
      ▼
BulletManager:
  ├── instantiate() 子弹场景
  ├── add_child() 添加到场景树
  ├── 设置 global_position
  ├── 设置 bulletOwner
  ├── 设置 rotation (方向)
  └── 设置物理属性 (重力/速度)
      │
      ▼
Bullet (RigidBody2D):
  ├── 运动（受重力或直射）
  └── 等待碰撞检测
```

---

## 子弹场景结构

### 基础子弹属性

所有子弹都是 `RigidBody2D`，共享以下属性：

| 属性名 | 类型 | 说明 |
|-------|------|------|
| `damagebuffid` | String | 伤害 Buff ID（默认 "1001"） |
| `speed` | float | 子弹初始速度 |
| `bulletOwner` | BattleActor | 子弹拥有者（用于 Buff 应用） |

### 碰撞配置

| 子弹类型 | collision_layer | collision_mask | 说明 |
|---------|----------------|----------------|------|
| 玩家子弹 | 256 | 16 | 敌人层 |
| 玩家子弹 Area | 0 | 2 | 子弹阻挡层 |
| 敌人子弹 | 256 | 4096 | 玩家层 |

---

### bow_bullet（弓箭子弹）

**脚本路径**: [bow_bullet.gd](../../src/gameplay/weapons/bow/bow_bullet.gd)
**场景路径**: [bullet_bow.tscn](../../scenes/weapons/Bow/bullet_bow.tscn)

```gdscript
extends RigidBody2D

@export var damagebuffid: String = "1001"
@export var speed = 250
var bulletOwner: BattleActor

func _on_bullet_hit(body: Node):
    hurt_somebody(body)
    _releaseSelf()

func hurt_somebody(body: Node):
    if body.has_method("_beHurt"):
        BattleManager.ApplyBuff(bulletOwner, body, damagebuffid)
```

**场景结构**:
```
RigidBody2D (bow_bullet)
├── CollisionShape2D   # 碰撞形状 (CapsuleShape2D)
├── AnimatedSprite2D   # 子弹精灵
├── Timer              # 生命周期定时器 (10秒)
└── Area2D             # 碰撞检测区域
    └── CollisionShape2D
```

---

### bottle_bullet（瓶子子弹 - 爆炸型）

**脚本路径**: [bottle_bullet.gd](../../src/gameplay/weapons/bottle/bottle_bullet.gd)
**场景路径**: [bullet_bottle.tscn](../../scenes/weapons/Bottle/bullet_bottle.tscn)

```gdscript
extends RigidBody2D

@export var damagebuffid: String = "1001"
@export var speed = 300
var bulletOwner: BattleActor

func _on_bullet_hit(body: Node):
    # 获取爆炸范围内的所有物体
    var boomBody = $BoomArea.get_overlapping_bodies()
    for i in boomBody:
        hurt_somebody(i)
    boomDisplay()  # 播放爆炸动画

func boomDisplay():
    # 冻结物理
    $".".set_deferred("freeze_mode", 1)
    $".".set_deferred("freeze", true)
    
    # 显示爆炸动画
    $BoomAnimated.visible = true
    $BoomAnimated.play("default")
    $AnimatedSprite2D.visible = false
    
    # Tween 动画效果
    var tween = create_tween()
    tween.tween_property($BoomAnimated, "scale", Vector2(2, 2), 0.35)
    tween.tween_property($BoomAnimated, "modulate:a", 0.2, 0.25)
    await tween.finished
    _releaseSelf()
```

**场景结构**:
```
RigidBody2D (bottle_bullet)
├── CollisionShape2D      # 主碰撞形状
├── AnimatedSprite2D      # 瓶子精灵
├── BoomAnimated          # 爆炸动画精灵
├── BoomArea (Area2D)     # 爆炸范围检测
│   └── CollisionShape2D
└── Timer                 # 生命周期定时器
```

**特点**: 
- 碰撞时检测 `BoomArea` 内的所有物体
- 对范围内所有目标造成伤害
- 播放爆炸动画后销毁

---

### crossbow_bullet（弩枪子弹）

**场景路径**: [bullet_crossbow.tscn](../../scenes/weapons/CrossBow/bullet_crossbow.tscn)

使用 `bow_bullet.gd` 脚本，但配置为无重力直射（STRAIGHT 类型）。

**物理配置**:
- `gravity_scale = 0`（无重力）
- `linear_velocity = direction * speed`（直线运动）

---

### Bullet_Base（敌人子弹）

**场景路径**: [Bullet_Base.tscn](../../scenes/weapons/EnemyWeapon/Bullet_Base.tscn)

敌人武器发射的基础子弹，使用 `EnemyWeapon_First.gd` 继承 WeaponBase。

---

## 子弹属性配置

### WeaponConfig.BulletType

**文件路径**: [WeaponConfig.gd](../../src/gameplay/weapons/WeaponConfig.gd)

```gdscript
enum BulletType {
    NORMAL,     # 普通子弹（受重力影响）
    STRAIGHT,   # 直射子弹（无重力）
    HOMING,     # 追踪子弹
    EXPLOSIVE,  # 爆炸子弹
}
```

### 各类型物理特性

| BulletType | gravity_scale | 运动方式 | 使用场景 |
|------------|--------------|---------|---------|
| NORMAL | 1.0 | `set_axis_velocity()` | 弓箭、瓶子 |
| STRAIGHT | 0 | `linear_velocity` | 弩枪 |
| HOMING | 0 | 追踪目标（未实现） | 追踪类武器 |
| EXPLOSIVE | 1.0 | 碰撞后爆炸（未实现） | 爆炸类武器 |

---

## 子弹碰撞处理

### 碰撞检测流程

```
Bullet (RigidBody2D)
      │
      ├── body_entered 信号
      │       └── _on_body_entered() → _releaseSelf()
      │
      └── Area2D.body_entered 信号
              └── _on_bullet_hit() → hurt_somebody() → _releaseSelf()
```

### 伤害应用流程

```
hurt_somebody(body: Node)
      │
      ▼
检查 body.has_method("_beHurt")
      │
      ▼
BattleManager.ApplyBuff(bulletOwner, body, damagebuffid)
      │
      ▼
DataRegistry.get_buff(buff_id)
      │
      ▼
AttributeBuff.deep_duplicate(source, target)
      │
      ▼
buffTarget.buffManager.buffList.append(buff_instance)
      │
      ▼
AttributeBuff.buff_execute()
      │
      ▼
E_Damage.EffectGo()
      ├── 获取 source.ATK
      ├── 获取 target.ARMOR
      ├── 计算 damage = base + ATK - ARMOR
      └── target.HP.sub(damage)
```

### base_enemy 受伤处理

**文件路径**: [base_enemy.gd](../../src/gameplay/actors/base_enemy.gd)

```gdscript
func _beHurt(_attribute: Attribute, _oldvalue: float, _newvalue: float):
    var dmg = _oldvalue - _newvalue
    if dmg > 0:
        # 显示伤害数字
        UIManager.instance.show_damage(self, dmg)
        
        # 触发受伤 Flow
        trigger_hit_flow(dmg)
        
        # 视觉反馈
        hitDisplay()
```

---

## 爆炸效果实现

### 瓶子子弹爆炸流程

```
bottle_bullet 碰撞
      │
      ▼
_on_bullet_hit() / _on_body_entered()
      │
      ▼
$BoomArea.get_overlapping_bodies()
      │
      ▼
遍历范围内的所有物体:
  hurt_somebody(i)
      │
      ▼
boomDisplay()
      │
      ├── freeze_mode = 1 (冻结模式)
      ├── freeze = true (停止物理)
      ├── $BoomAnimated.visible = true
      ├── $AnimatedSprite2D.visible = false
      └── Tween 动画:
          ├── scale → Vector2(2, 2)
          └── modulate.a → 0.2
      │
      ▼
await tween.finished
      │
      ▼
_releaseSelf() → queue_free()
```

---

## 武器发射机制

### WeaponBase.emit_bullet()

**文件路径**: [weapon_base.gd](../../src/gameplay/weapons/weapon_base.gd)

```gdscript
func emit_bullet(direction: Vector2, speed: float = -1.0) -> void:
    if speed < 0:
        speed = get_current_speed()
    
    var spawn_pos = get_spawn_position()
    emit_signal("weapon_fired", bullet, spawn_pos, direction, speed, bullet_type, owner_actor)

func emit_bullets(directions: Array[Vector2], speed: float = -1.0) -> void:
    if speed < 0:
        speed = get_current_speed()
    
    for dir in directions:
        emit_bullet(dir, speed)
```

### 各武器发射特性

| 武器 | 发射方式 | 子弹数量 | 特殊逻辑 |
|------|---------|---------|---------|
| Bow | emit_bullet() | 1 | 速度 = base + charge_speed |
| Bottle | emit_bullets() | 1-3 | 蓄力足够发射三颗散射 |
| Crossbow | emit_bullet() | 多（连射） | 蓄力期间自动连射 |

---

## 关键代码路径汇总表

| 类/文件 | 路径 |
|--------|------|
| BulletManager | [src/gameplay/battle/BulletManager.gd](../../src/gameplay/battle/BulletManager.gd) |
| WeaponBase | [src/gameplay/weapons/weapon_base.gd](../../src/gameplay/weapons/weapon_base.gd) |
| WeaponConfig | [src/gameplay/weapons/WeaponConfig.gd](../../src/gameplay/weapons/WeaponConfig.gd) |
| bow_bullet | [src/gameplay/weapons/bow/bow_bullet.gd](../../src/gameplay/weapons/bow/bow_bullet.gd) |
| bottle_bullet | [src/gameplay/weapons/bottle/bottle_bullet.gd](../../src/gameplay/weapons/bottle/bottle_bullet.gd) |
| bullet_bow.tscn | [scenes/weapons/Bow/bullet_bow.tscn](../../scenes/weapons/Bow/bullet_bow.tscn) |
| bullet_bottle.tscn | [scenes/weapons/Bottle/bullet_bottle.tscn](../../scenes/weapons/Bottle/bullet_bottle.tscn) |
| bullet_crossbow.tscn | [scenes/weapons/CrossBow/bullet_crossbow.tscn](../../scenes/weapons/CrossBow/bullet_crossbow.tscn) |
| Bullet_Base.tscn | [scenes/weapons/EnemyWeapon/Bullet_Base.tscn](../../scenes/weapons/EnemyWeapon/Bullet_Base.tscn) |
| WeaponRoot | [scenes/components/WeaponRoot.gd](../../scenes/components/WeaponRoot.gd) |
| BattleManager | [src/gameplay/battle/BattleManager.gd](../../src/gameplay/battle/BattleManager.gd) |
| base_enemy | [src/gameplay/actors/base_enemy.gd](../../src/gameplay/actors/base_enemy.gd) |
| UIManager | [src/ui/UIManager.gd](../../src/ui/UIManager.gd) |

---

## 相关文档

- [Architecture.md](Architecture.md) - 整体架构概览
- [WeaponSystem.md](WeaponSystem.md) - 武器系统详细说明
- [UISystem.md](UISystem.md) - UI系统详细说明