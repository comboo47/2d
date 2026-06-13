# 战斗系统架构概览

## 系统关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                           战斗系统架构                               │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Weapon     │────▶│   Bullet     │────▶│    Buff      │
│   System     │     │   Manager    │     │   System     │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                    │
       │                    │                    │
       ▼                    ▼                    ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Skill      │     │   Vfx        │     │  Attribute   │
│   System     │     │   Manager    │     │   System     │
└──────────────┘     └──────────────┘     └──────────────┘
       │                                         │
       │                                         │
       ▼                                         ▼
┌──────────────┐                           ┌──────────────┐
│   UI         │                           │  BattleActor │
│   Manager    │                           │   (Player/   │
└──────────────┘                           │    Enemy)    │
                                           └──────────────┘
```

## 数据流向图

```
用户输入 (fire)
      │
      ▼
┌─────────────────┐
│   Player.gd     │ hold_fire() / fire()
│                 │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│   WeaponBase    │ emit_signal("weapon_fired")
│                 │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ WeaponRoot      │ 连接信号到 BulletManager
│                 │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ BulletManager   │ instantiate() + 设置物理
│                 │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│   Bullet        │ 碰撞检测
│   (RigidBody2D) │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ BattleManager   │ ApplyBuff(bulletOwner, target, buffID)
│                 │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│  BuffManager    │ 添加 Buff 到目标
│                 │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ E_Damage        │ EffectGo() → 修改 Attribute
│                 │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│  Attribute      │ attribute_changed 信号
│   (Hp)          │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│   UIManager     │ show_damage() + update HPBar
│                 │
└─────────────────┘
```

## Autoload 单例列表

| 单例名称 | 脚本路径 | 功能说明 |
|---------|---------|---------|
| GameManager | [GameManager.gd](../../src/app/GameManager.gd) | 游戏状态管理、场景切换 |
| InputManager | [InputManager.gd](../../src/app/InputManager.gd) | 输入锁定管理 |
| BattleManager | [BattleManager.gd](../../src/gameplay/battle/BattleManager.gd) | Buff 应用、战斗静态方法 |
| BulletManager | [BulletManager.gd](../../src/gameplay/battle/BulletManager.gd) | 子弹生成和生命周期 |
| VfxManager | [VfxManager.gd](../../src/gameplay/vfx/VfxManager.gd) | 特效播放和池化管理 |
| UIManager | [UIManager.gd](../../src/ui/UIManager.gd) | UI 层管理、伤害数字显示 |
| DataRegistry | [DataManager.gd](../../src/gameplay/data/DataManager.gd) | Buff 资源注册表 |
| SkillRegistry | [SkillRegistry.gd](../../src/gameplay/skills/SkillRegistry.gd) | 技能资源注册表 |
| FlowRegistry | [GameplayFlowRegistry.gd](../../src/gameplay/flows/GameplayFlowRegistry.gd) | Flow 资源注册表 |
| DropManager | [DropManager.gd](../../src/gameplay/drops/DropManager.gd) | 掉落物品管理 |
| EnemyFactory | [EnemyFactory.gd](../../src/gameplay/enemies/EnemyFactory.gd) | 敌人动态创建 |

## 模块依赖关系

### 核心依赖链

```
BattleActor (角色基类)
    │
    ├── AttributeComponent (属性组件)
    │       └── AttributeSet (属性集合)
    │               └── Attribute (单个属性)
    │
    ├── BuffManager (Buff 管理)
    │       └── AttributeBuff (Buff 实例)
    │               └── AttributeBuffEffect (Buff 效果)
    │
    ├── SkillManager (技能管理) [可选]
    │       └── SkillBase (技能实例)
    │               └── SkillEffectBase (技能效果)
    │
    └── WeaponRoot (武器组件)
            └── WeaponBase (武器实例)
                    └── Bullet (子弹场景)
```

### 信号依赖链

```
Attribute.attribute_changed
    └── BuffManager 监听 → 更新属性
    └── UIManager 监听 → 显示伤害数字

WeaponBase.weapon_fired
    └── WeaponRoot 连接 → BulletManager.handle_bullet_spawn

SkillBase.on_use_flow_id
    └── FlowRegistry.get_flow → GameplayFlowBase.execute
```

## 关键设计决策

### 1. 武器系统架构

- **统一基类**：所有武器继承 `WeaponBase`，统一 `weapon_fired` 信号格式
- **蓄力系统**：弓箭蓄力增加速度，瓶子蓄力触发散射，弩枪蓄力触发连射
- **能量系统**：弩枪独有能量消耗和恢复机制
- **信号连接**：WeaponRoot 管理武器切换和信号连接

### 2. 技能系统架构

- **组合模式**：技能效果通过 `SkillEffect` 数组组合，按优先级执行
- **槽位管理**：SkillManager 管理 PRIMARY/SECONDARY/ULTIMATE/PASSIVE 槽位
- **触发技能**：支持 ON_HIT/ON_KILL/ON_ATTACK 等事件触发
- **资源注册**：SkillRegistry 自动扫描 `resources/gameplay/skills/` 目录

### 3. 子弹系统架构

- **信号驱动**：武器发射信号 → BulletManager 处理生成
- **格式兼容**：支持新旧两种信号格式
- **物理类型**：NORMAL（有重力）和 STRAIGHT（无重力）
- **伤害传递**：通过 `bulletOwner` 和 `damagebuffid` 应用 Buff

### 4. UI 系统架构

- **三层结构**：Battle（战斗HUD）→ Menu（菜单）→ Overlay（叠加层）
- **池化机制**：PopDamageWidget 预创建池，避免频繁创建销毁
- **信号绑定**：Attribute.attribute_changed → UIManager 更新 UI
- **Meta 存储**：武器引用通过 `player.set_meta("CurrentWeapon")` 存储

### 5. Buff/Attribute 系统

- **数据驱动**：Buff 通过 `.tres` 资源定义
- **效果组合**：AttributeBuffEffect 可组合多种效果
- **属性依赖**：Attribute 支持衍生属性（如 MaxHP 依赖 Strength）
- **实时更新**：AttributeComponent._physics_process 驱动属性计算

---

## 相关文档

- [WeaponSystem.md](WeaponSystem.md) - 武器系统详细说明
- [SkillSystem.md](SkillSystem.md) - 技能系统详细说明
- [BulletSystem.md](BulletSystem.md) - 子弹系统详细说明
- [UISystem.md](UISystem.md) - UI系统详细说明