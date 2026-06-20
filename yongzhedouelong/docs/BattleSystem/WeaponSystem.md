# 武器系统说明文档

> ⚠️ **本文档已过时（2026/06/13）**。下文描述的 `WeaponBase` + `WeaponBow/Bottle/Crossbow`
> 子类模型已在第三期重构中**删除**。当前武器系统为 **Flow 驱动**：
> 武器 = `WeaponDefinition` 数据（持有 `input_mode` + `fire_flow`），开火逻辑写在继承
> `WeaponFireFlowBase` 的常驻 Flow 里，由通用节点 `WeaponDriver` + autoload `FlowRuntime` 驱动。
>
> **新增武器请看 → [AddNewWeapon.md](AddNewWeapon.md)**。
> 下文仅作历史参考，类继承图与 weapon_base 相关内容均已失效。

## 类继承关系图

```
Node2D
  └── WeaponBase (基类)
        ├── WeaponBow (弓箭 - 蓄力增加速度)
        ├── WeaponBottle (瓶子 - 蓄力触发散射)
        ├── WeaponCrossbow (弩枪 - 能量系统 + 蓄力连射)
        └── EnemyWeapon_First (敌人武器)
```

---

## WeaponBase 基类

**文件路径**: [weapon_base.gd](../../src/gameplay/weapons/weapon_base.gd)

### 信号定义

```gdscript
# 统一的武器发射信号
signal weapon_fired(
    bullet: PackedScene,         # 子弹场景
    spawn_position: Vector2,     # 发射位置
    direction: Vector2,          # 发射方向
    speed: float,                # 发射速度
    bullet_type: int,            # 子弹类型 (WeaponConfig.BulletType)
    owner: BattleActor           # 武器拥有者
)

# 能量变化信号（弩枪使用）
signal energy_changed(current: float, max_energy: float)

# 武器状态变化信号
signal weapon_state_changed(state: WeaponConfig.WeaponState)
```

### 属性说明

#### 基础属性

| 属性名 | 类型 | 默认值 | 说明 |
|-------|------|-------|------|
| `bullet` | PackedScene | null | 子弹场景预制体 |
| `owner_actor` | BattleActor | null | 武器拥有者（由 WeaponRoot 设置） |
| `weapon_type` | WeaponType | BOW | 武器类型 |
| `bullet_type` | BulletType | NORMAL | 子弹类型 |
| `base_speed` | float | 250.0 | 基础发射速度 |
| `damage_buff_id` | String | "1001" | 伤害 Buff ID |

#### 能量系统（弩枪专用）

| 属性名 | 类型 | 默认值 | 说明 |
|-------|------|-------|------|
| `max_energy` | float | 100.0 | 最大能量值 |
| `energy_cost` | float | 10.0 | 每次发射消耗能量 |
| `energy_regen` | float | 3.0 | 每秒恢复能量 |
| `current_energy` | float | 0.0 | 当前能量（运行时） |

#### 蓄力系统

| 属性名 | 类型 | 默认值 | 说明 |
|-------|------|-------|------|
| `max_charge_speed` | float | 650.0 | 最大蓄力速度加成 |
| `charge_rate` | float | 5.0 | 每帧增加的速度 |
| `charge_time` | float | 0.7 | 蓄力时间阈值（秒） |
| `hold_time` | float | 0.0 | 按住时间（运行时） |
| `charge_speed` | float | 0.0 | 当前蓄力速度（运行时） |

#### 技能关联

| 属性名 | 类型 | 默认值 | 说明 |
|-------|------|-------|------|
| `linked_skill_slot` | SkillSlot | SECONDARY | 关联的技能槽位 |

#### 运行时状态

| 属性名 | 类型 | 说明 |
|-------|------|------|
| `_aim_direction` | Vector2 | 当前瞄准方向 |
| `_aim_mouse_pos` | Vector2 | 鼠标位置 |
| `_is_holding` | bool | 是否正在蓄力 |
| `_weapon_state` | WeaponState | 当前武器状态 |

#### 场景节点引用

| 属性名 | 类型 | 说明 |
|-------|------|------|
| `trajectory_line` | Line2D | 弹道预览线 |
| `marker` | Marker2D | 发射位置标记 |

### 公共 API 方法

#### 发射控制

```gdscript
func hold_fire() -> void        # 开始蓄力（设置 _is_holding = true）
func fire() -> void             # 发射（子类重写实现具体逻辑）
func release_fire() -> void     # 强制释放蓄力状态
```

#### 能量系统

```gdscript
func consume_energy(amount: float) -> bool   # 消耗能量，返回是否成功
func has_energy(amount: float) -> bool       # 检查能量是否足够
func get_current_energy() -> float           # 获取当前能量值
func get_energy_percent() -> float           # 获取能量百分比 (0.0-1.0)
func getWeaponEnergy() -> float              # 兼容旧接口
```

#### 状态查询

```gdscript
func get_state() -> WeaponConfig.WeaponState  # 获取当前状态
func is_charging() -> bool                    # 是否正在蓄力
func get_hold_time() -> float                 # 获取蓄力时间
func get_current_speed() -> float             # 获取当前发射速度
func get_aim_direction() -> Vector2           # 获取瞄准方向
func get_spawn_position() -> Vector2          # 获取发射位置
```

#### 发射辅助（内部使用）

```gdscript
func emit_bullet(direction: Vector2, speed: float = -1.0) -> void
    # 发射单颗子弹，触发 weapon_fired 信号

func emit_bullets(directions: Array[Vector2], speed: float = -1.0) -> void
    # 发射多颗子弹（用于散射）
```

---

## WeaponConfig 配置类

**文件路径**: [WeaponConfig.gd](../../src/gameplay/weapons/WeaponConfig.gd)

### 枚举定义

#### WeaponType - 武器类型

```gdscript
enum WeaponType {
    BOW,        # 弓箭（蓄力增加速度）
    BOTTLE,     # 瓶子（蓄力触发散射）
    CROSSBOW,   # 弩枪（能量系统 + 蓄力连射）
    ENEMY,      # 敌人武器
}
```

#### BulletType - 子弹类型

```gdscript
enum BulletType {
    NORMAL,     # 普通子弹（受重力影响）
    STRAIGHT,   # 直射子弹（无重力）
    HOMING,     # 追踪子弹
    EXPLOSIVE,  # 爆炸子弹
}
```

#### WeaponState - 武器状态

```gdscript
enum WeaponState {
    IDLE,       # 待机
    CHARGING,   # 蓄力中
    FIRING,     # 发射中
    COOLDOWN,   # 冷却中
    EMPTY,      # 能量耗尽（弩枪）
}
```

### 默认参数配置

```gdscript
const DEFAULT_PARAMS := {
    WeaponType.BOW: {
        "base_speed": 250.0,
        "max_charge_speed": 650.0,
        "charge_rate": 5.0,
        "bullet_type": BulletType.NORMAL,
    },
    WeaponType.BOTTLE: {
        "base_speed": 300.0,
        "spread_angle": 0.25,
        "charge_time": 0.7,
        "bullet_type": BulletType.NORMAL,
    },
    WeaponType.CROSSBOW: {
        "base_speed": 250.0,
        "max_energy": 100.0,
        "energy_cost": 10.0,
        "energy_regen": 3.0,
        "fire_interval": 0.1,
        "charge_time": 0.7,
        "bullet_type": BulletType.STRAIGHT,
    },
}
```

---

## 子武器实现

### WeaponBow（弓箭）

**文件路径**: [Weapon_Bow.gd](../../src/gameplay/weapons/bow/Weapon_Bow.gd)
**场景路径**: [weapon_Bow.tscn](../../scenes/weapons/Bow/weapon_Bow.tscn)

**特性**: 蓄力增加发射速度

```gdscript
class_name WeaponBow extends WeaponBase

func _ready() -> void:
    super._ready()
    weapon_type = WeaponConfig.WeaponType.BOW
    bullet_type = WeaponConfig.BulletType.NORMAL
    max_charge_speed = 650.0  # base 250 + max 400
    charge_rate = 5.0

func fire() -> void:
    # 计算最终速度 = 基础速度 + 蓄力速度
    var final_speed = base_speed + charge_speed
    emit_bullet(_aim_direction, final_speed)
    # 重置蓄力状态
    hold_time = 0.0
    charge_speed = 0.0
    _is_holding = false
    _set_state(WeaponConfig.WeaponState.IDLE)
```

**场景结构**:
```
weapon_Bow (Node2D)
├── Sprite2D2        # 武器精灵
├── Marker2D         # 发射位置标记
└── Line2D           # 弹道预览线
```

---

### WeaponBottle（瓶子）

**文件路径**: [Weapon_Bottle.gd](../../src/gameplay/weapons/bottle/Weapon_Bottle.gd)
**场景路径**: [weapon_Bottle.tscn](../../scenes/weapons/Bottle/weapon_Bottle.tscn)

**特性**: 蓄力触发散射（三颗子弹）

```gdscript
class_name WeaponBottle extends WeaponBase

@export var spread_angle: float = 0.25  # 散射角度（弧度）

func fire() -> void:
    if hold_time >= charge_time:
        # 蓄力足够：散射三颗子弹
        var dir2 = _aim_direction.rotated(spread_angle)   # 左
        var dir3 = _aim_direction.rotated(-spread_angle)  # 右
        emit_bullet(dir2, base_speed)
        emit_bullet(dir3, base_speed)
    else:
        # 蓄力不足：单颗子弹
        emit_bullet(_aim_direction, base_speed)
    # 重置状态
    hold_time = 0.0
    _is_holding = false
    _set_state(WeaponConfig.WeaponState.IDLE)
```

**场景结构**:
```
weapon_Bottle (Node2D)
├── AnimatedSprite2D  # 瓶子精灵（有 shake 动画）
├── Marker2D         # 发射位置标记
├── Line2D           # 主弹道预览线
├── Line2D2          # 左散射预览线
└── Line2D3          # 右散射预览线
```

---

### WeaponCrossbow（弩枪）

**文件路径**: [Weapon_Crossbow.gd](../../src/gameplay/weapons/crossbow/Weapon_Crossbow.gd)
**场景路径**: [weapon_Crossbow.tscn](../../scenes/weapons/CrossBow/weapon_Crossbow.tscn)

**特性**: 能量系统 + 蓄力连射

```gdscript
class_name WeaponCrossbow extends WeaponBase

@export var fire_interval: float = 0.1  # 连射间隔（秒）

func _ready() -> void:
    super._ready()
    weapon_type = WeaponConfig.WeaponType.CROSSBOW
    bullet_type = WeaponConfig.BulletType.STRAIGHT  # 无重力直射
    max_energy = 100.0
    energy_cost = 10.0
    energy_regen = 3.0

func _process(delta: float) -> void:
    super._process(delta)
    # 蓄力连射逻辑（蓄力足够时自动连射）
    if _is_holding and hold_time >= charge_time:
        _fire_accumulator += delta
        if _fire_accumulator >= fire_interval:
            _fire_accumulator = 0.0
            _try_fire_continuous()

func _try_fire_continuous() -> void:
    if has_energy(energy_cost):
        consume_energy(energy_cost)
        emit_bullet(_aim_direction, base_speed)

func fire() -> void:
    # 蓄力时间不足时单发射击
    if hold_time < charge_time:
        if has_energy(energy_cost):
            consume_energy(energy_cost)
            emit_bullet(_aim_direction, base_speed)
    # 重置状态
    _is_holding = false
    hold_time = 0.0
    _fire_accumulator = 0.0
    _set_state(WeaponConfig.WeaponState.IDLE)
```

**场景结构**:
```
weapon_Crossbow (Node2D)
├── Sprite2D2        # 武器精灵
├── Marker2D         # 发射位置标记
├── RefreshTimer     # 能量恢复定时器（wait_time = 0.1）
└── SubTimer         # 连射定时器（wait_time = 0.1）
```

---

### EnemyWeapon_First（敌人武器）

**文件路径**: [EnemyWeapon_First.gd](../../scenes/weapons/EnemyWeapon/EnemyWeapon_First.gd)
**场景路径**: [Weapon_Base.tscn](../../scenes/weapons/EnemyWeapon/Weapon_Base.tscn)

**实现**: 仅继承 WeaponBase，无额外逻辑

```gdscript
extends WeaponBase
```

---

## WeaponRoot 组件

**文件路径**: [WeaponRoot.gd](../../scenes/components/WeaponRoot.gd)

### 武器切换流程

```gdscript
@export var weaponOwner: BattleActor        # 武器拥有者
@export_range(0, 2) var currentWeapon: int  # 当前武器索引

func updateWeapon():
    var weapon = get_child(currentWeapon)
    
    # 1. 更新 meta 数据
    weaponOwner.set_meta("CurrentWeapon", weapon)
    
    # 2. 设置 owner_actor
    if "owner_actor" in weapon:
        weapon.owner_actor = weaponOwner
    
    # 3. 连接 BulletManager 信号
    var bullet_manager = get_node("/root/BulletManager")
    if weapon.has_signal("weapon_fired"):
        if not weapon.is_connected("weapon_fired", ...):
            weapon.connect("weapon_fired", Callable(bullet_manager, "handle_bullet_spawn"))
    
    # 4. 显示/隐藏武器
    for i in get_children():
        if i == weapon: i.show()
        else: i.hide()

func setCurrentWeapon(i: int):
    currentWeapon = i
    updateWeapon()
    # 通知能量条更新
    if weaponOwner.has_meta("weaponEnergyBar"):
        weaponOwner.get_meta("weaponEnergyBar").updateEnergyBarvisible()
```

### 信号连接机制

```
WeaponRoot.updateWeapon()
    │
    ├── 获取当前武器节点
    │
    ├── 设置 weapon.owner_actor = player
    │
    ├── 连接信号:
    │   weapon.weapon_fired ──▶ BulletManager.handle_bullet_spawn
    │
    └── 更新 UI:
        weaponEnergyBar.updateEnergyBarvisible()
```

---

## 蓄力系统工作原理

### 流程图

```
用户按下 fire 键
      │
      ▼
Player.gd: weapon.hold_fire()
      │
      ▼
WeaponBase:
  _is_holding = true
  hold_time = 0.0
  charge_speed = 0.0
  _set_state(CHARGING)
      │
      ▼
WeaponBase._process(delta):
  if _is_holding:
      _update_charge(delta)
          │
          ├── hold_time += delta
          ├── charge_speed += charge_rate
          └── clamp charge_speed
      │
      ▼
用户释放 fire 键
      │
      ▼
Player.gd: weapon.fire()
      │
      ▼
子类 fire() 实现:
  - Bow: speed = base_speed + charge_speed
  - Bottle: hold_time >= charge_time ? 三连射 : 单发
  - Crossbow: 自动连射已触发，释放停止
      │
      ▼
emit_bullet() / emit_bullets()
      │
      ▼
emit_signal("weapon_fired", ...)
      │
      ▼
重置状态: _is_holding = false, hold_time = 0
```

### 各武器蓄力特性

| 武器 | 蓄力效果 | charge_time | 特殊逻辑 |
|------|---------|-------------|---------|
| Bow | 速度加成 | 无限制 | 蓄力越久速度越高 |
| Bottle | 触发散射 | 0.7秒 | 蓄力足够发射三颗子弹 |
| Crossbow | 触发连射 | 0.7秒 | 蓄力期间自动连射 |

---

## 能量系统工作原理

### 流程图

```
WeaponCrossbow._ready():
  current_energy = max_energy (100)
      │
      ▼
WeaponBase._process(delta):
  if not _is_holding:
      _regen_energy(delta)
          │
          ├── current_energy += energy_regen * delta
          └── emit_signal("energy_changed")
      │
      ▼
蓄力连射期间:
  if has_energy(energy_cost):
      consume_energy(energy_cost)
          │
          ├── current_energy -= energy_cost
          ├── emit_signal("energy_changed")
          └── if current_energy <= 0: _set_state(EMPTY)
```

### 能量 UI 更新

```
WeaponRoot.setCurrentWeapon()
    │
    ▼
weaponEnergyBar.updateEnergyBarvisible()
    │
    ├── 检查武器是否有 getWeaponEnergy 方法
    │
    └── weaponEnergy._process():
        energy = weapon.getWeaponEnergy()
        $ProgressBar.value = energy
```

---

## 弹道预览系统

### 工作原理

```gdscript
func _update_trajectory(delta: float) -> void:
    if trajectory_line == null: return
    
    trajectory_line.clear_points()
    
    if _is_holding:
        _draw_trajectory(delta)  # 绘制预测轨迹

func _draw_trajectory(delta: float) -> void:
    var speed = get_current_speed()
    var dir = _aim_direction
    
    # 计算轨迹点（考虑重力）
    var gravity = 490.0
    for i in range(30):
        var point = Vector2(
            dir.x * speed * i * delta,
            (dir.y * speed + gravity * i * delta) * i * delta
        )
        trajectory_line.add_point(point)
```

### 各武器预览线数量

| 武器 | 预览线数量 | 说明 |
|------|----------|------|
| Bow | 1条 | 单条主弹道 |
| Bottle | 1-3条 | 蓄力足够时显示三条散射弹道 |
| Crossbow | 0条 | 无预览（直射） |

---

## 关键代码路径汇总表

| 类/文件 | 路径 |
|--------|------|
| WeaponBase | [src/gameplay/weapons/weapon_base.gd](../../src/gameplay/weapons/weapon_base.gd) |
| WeaponConfig | [src/gameplay/weapons/WeaponConfig.gd](../../src/gameplay/weapons/WeaponConfig.gd) |
| WeaponBow | [src/gameplay/weapons/bow/Weapon_Bow.gd](../../src/gameplay/weapons/bow/Weapon_Bow.gd) |
| WeaponBottle | [src/gameplay/weapons/bottle/Weapon_Bottle.gd](../../src/gameplay/weapons/bottle/Weapon_Bottle.gd) |
| WeaponCrossbow | [src/gameplay/weapons/crossbow/Weapon_Crossbow.gd](../../src/gameplay/weapons/crossbow/Weapon_Crossbow.gd) |
| EnemyWeapon_First | [scenes/weapons/EnemyWeapon/EnemyWeapon_First.gd](../../scenes/weapons/EnemyWeapon/EnemyWeapon_First.gd) |
| WeaponRoot | [scenes/components/WeaponRoot.gd](../../scenes/components/WeaponRoot.gd) |
| BulletManager | [src/gameplay/battle/BulletManager.gd](../../src/gameplay/battle/BulletManager.gd) |
| Player.gd | [src/gameplay/actors/Player.gd](../../src/gameplay/actors/Player.gd) |
| weaponEnergy UI | [src/interaction/weaponEnergy.gd](../../src/interaction/weaponEnergy.gd) |
| weapon_Bow.tscn | [scenes/weapons/Bow/weapon_Bow.tscn](../../scenes/weapons/Bow/weapon_Bow.tscn) |
| weapon_Bottle.tscn | [scenes/weapons/Bottle/weapon_Bottle.tscn](../../scenes/weapons/Bottle/weapon_Bottle.tscn) |
| weapon_Crossbow.tscn | [scenes/weapons/CrossBow/weapon_Crossbow.tscn](../../scenes/weapons/CrossBow/weapon_Crossbow.tscn) |

---

## 相关文档

- [Architecture.md](Architecture.md) - 整体架构概览
- [BulletSystem.md](BulletSystem.md) - 子弹系统详细说明
- [SkillSystem.md](SkillSystem.md) - 技能系统详细说明