# GameplayFlow 设计理念文档

## 设计理念概述

### GameplayFlow 的定位

**GameplayFlow 不是生命周期系统本身**，而是游戏内容模块在生命周期事件点上**可配置的行为脚本**。

- 生命周期由各模块（怪物、武器、技能、buff、角色）自行设计和管理
- GameplayFlow 作为可复用的行为脚本，被配置在模块的生命周期事件点上
- 模块在特定事件点暴露参数，调用配置的 GameplayFlow 执行逻辑

### GameplayFlow 是基类

GameplayFlow 作为基类，后续会根据功能业务生成子类，约束对应系统的固定上下文：

```
GameplayFlowBase (基类)
    ├── SkillFlow      # 技能系统 Flow，约束 skill_id, target_selection 等上下文
    ├── BuffFlow       # Buff 系统 Flow，约束 buff_id, duration 等上下文
    ├── ActorFlow      # 角色系统 Flow，约束 actor_id, position 等上下文
    └── LevelFlow      # 关卡系统 Flow，约束 level_id, wave_id 等上下文
```

**子类的意义**：
- 约束固定的上下文字段，减少配置错误
- 提供特定系统的便捷方法
- 编辑器插件可提供针对性的配置界面

### 两种触发模式

GameplayFlow 支持两种触发模式：

| 模式 | trigger_event | 触发方式 | 使用场景 |
|------|--------------|----------|----------|
| **直接触发** | 不需要（只有 `start`） | 模块直接调用 `flow.execute(context)` | Skill.on_use_flow_id, Actor.spawn_flow_id 等 |
| **事件触发** | 需要（定义触发时机） | FlowRegistry 或关卡系统自动触发 | 关卡初始化、波次生成、全局事件等 |

**直接触发模式**：
- Flow 绑定在代码或游戏资产上
- 模块在特定事件点直接调用 `flow.start()` 或 `flow.execute(context)`
- 无需 `trigger_event` 属性

**事件触发模式**：
- Flow 由系统统一管理（如关卡系统）
- 需要定义 `trigger_event` 来指定触发时机
- 适用于关卡初始化、波次生成等全局事件

### signal - condition - action 开发模式

游戏框架遵循 **signal - condition - action** 开发模式：

| 阶段 | 职责 | 说明 |
|------|------|------|
| **signal** | 模块负责 | 模块在生命周期事件点抛出信号，携带事件参数 |
| **condition** | GameplayFlow 负责 | Flow 通过 `condition_expression` 过滤是否执行 |
| **action** | FlowEffect 负责 | Flow 通过 `effects[]` 执行具体行为 |

**信号用途**：
1. 通知外部监听器（如 UI、调试工具）
2. 被 GameplayFlow 监听执行其他逻辑

---

## GameplayFlow 子类设计

### SkillFlow（技能 Flow）

约束技能系统的固定上下文：

```gdscript
class_name SkillFlow extends GameplayFlowBase

# 固定上下文字段
@export var skill_id: String = ""           # 关联技能 ID
@export var target_selection: TargetType    # 目标选择方式
@export var mana_cost_override: float = -1  # 覆盖技能消耗

# 便捷方法
func create_skill_context(skill: SkillBase, user: BattleActor, target: BattleActor) -> SkillFlowContext:
    var context = SkillFlowContext.new()
    context.skill = skill
    context.source = user
    context.target = target
    return context
```

### BuffFlow（Buff Flow）

约束 Buff 系统的固定上下文：

```gdscript
class_name BuffFlow extends GameplayFlowBase

# 固定上下文字段
@export var buff_id: String = ""            # 关联 Buff ID
@export var duration_override: float = -1   # 覆盖持续时间
@export var stack_policy: StackPolicy       # 叠加策略

# 便捷方法
func create_buff_context(buff: AttributeBuff, source: BattleActor, target: BattleActor) -> BuffFlowContext:
    var context = BuffFlowContext.new()
    context.buff = buff
    context.source = source
    context.target = target
    return context
```

### ActorFlow（角色 Flow）

约束角色系统的固定上下文：

```gdscript
class_name ActorFlow extends GameplayFlowBase

# 固定上下文字段
@export var actor_id: String = ""           # 关联角色 ID
@export var position_mode: PositionMode     # 位置模式（相对/绝对）

# 便捷方法
func create_actor_context(actor: BattleActor) -> ActorFlowContext:
    var context = ActorFlowContext.new()
    context.actor = actor
    context.position = actor.global_position
    return context
```

### LevelFlow（关卡 Flow）

约束关卡系统的固定上下文，需要 `trigger_event`：

```gdscript
class_name LevelFlow extends GameplayFlowBase

# 固定上下文字段
@export var level_id: String = ""           # 关联关卡 ID
@export var wave_id: int = -1               # 波次 ID（-1 表示所有波次）

# LevelFlow 需要触发事件
@export var trigger_event: LevelEvent = LevelEvent.ON_LEVEL_START

enum LevelEvent {
    ON_LEVEL_START,     # 关卡开始时
    ON_WAVE_START,      # 波次开始时
    ON_WAVE_END,        # 波次结束时
    ON_LEVEL_END,       # 关卡结束时
    ON_TIMER,           # 定时触发
}

# 便捷方法
func create_level_context(level: LevelManager, wave: int = -1) -> LevelFlowContext:
    var context = LevelFlowContext.new()
    context.level = level
    context.wave = wave
    return context
```

---

## 两种触发模式的实现

### 直接触发模式（Direct Trigger）

**适用场景**：Flow 绑定在模块资产上，模块直接调用触发

**实现方式**：

```gdscript
# 模块配置 Flow ID
@export var on_use_flow_id: String = ""

# 模块在事件点触发 Flow
func trigger_flow(flow_id: String, context: GameplayFlowContext) -> void:
    if flow_id.is_empty(): return
    
    var flow = FlowRegistry.instance.get_flow(flow_id)
    if flow:
        flow.start(context)  # 或 flow.execute(context)
```

**使用示例**：

```gdscript
# SkillBase.gd
func use(context: GameplayFlowContext) -> bool:
    # 执行技能效果...
    
    # 直接触发关联 Flow
    if not on_use_flow_id.is_empty():
        var flow = FlowRegistry.instance.get_flow(on_use_flow_id)
        if flow:
            flow.start(context)  # SkillFlow 或 GameplayFlowBase
    
    return true

# base_enemy.gd
func trigger_spawn_flow() -> void:
    if spawn_flow_id.is_empty(): return
    
    var flow = FlowRegistry.instance.get_flow(spawn_flow_id)
    if flow:
        var context = ActorFlowContext.create_simple(self)
        flow.start(context)  # ActorFlow 或 GameplayFlowBase
```

**特点**：
- 无需 `trigger_event` 属性
- Flow 由模块直接调用
- Context 由模块创建并填充参数

### 事件触发模式（Event Trigger）

**适用场景**：Flow 由系统统一管理，根据事件类型自动触发

**实现方式**：

```gdscript
# FlowRegistry 按事件类型缓存 Flow
var _flows_by_event: Dictionary = {}  # {LevelEvent: Array[LevelFlow]}

# 系统触发指定事件的所有 Flow
func trigger_event_flows(event: LevelEvent, context: GameplayFlowContext) -> void:
    var flows = get_flows_by_event(event)
    for flow in flows:
        if flow.can_trigger(context):
            flow.start(context)

# Flow 检查是否可触发
func can_trigger(context: GameplayFlowContext) -> bool:
    # 检查 condition_expression
    if not condition_expression.is_empty():
        return _check_condition(context)
    return true
```

**使用示例**：

```gdscript
# LevelManager.gd
func start_level() -> void:
    # 触发关卡开始 Flow
    var context = LevelFlowContext.create_simple(self)
    FlowRegistry.instance.trigger_event_flows(LevelEvent.ON_LEVEL_START, context)

func start_wave(wave_id: int) -> void:
    # 触发波次开始 Flow
    var context = LevelFlowContext.create_with_wave(self, wave_id)
    FlowRegistry.instance.trigger_event_flows(LevelEvent.ON_WAVE_START, context)
```

**特点**：
- 需要 `trigger_event` 属性定义触发时机
- Flow 由系统自动触发
- 适用于全局事件、关卡初始化等场景

---

## 事件触发链路

### 武器 → Skill → Flow 链路

武器的事件点通过 Skill 模块触发 GameplayFlow：

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        武器 → Skill → Flow 链路                          │
└─────────────────────────────────────────────────────────────────────────┘

Player.gd
    │
    ├─ Input.is_action_just_pressed("fire")
    │      │
    │      └─► weapon.hold_fire()
    │              │
    │              ├─ emit_signal("weapon_state_changed", CHARGING)
    │              │      └─► Flow 监听执行其他逻辑
    │              │
    │              └─► 触发 linked_skill_slots 中 ON_FIRE 类型技能
    │                      │
    │                      └─► Skill.use()
    │                              │
    │                              ├─ 执行 SkillEffect[]
    │                              │
    │                              └─► 触发 on_use_flow_id
    │                                      │
    │                                      └─► Flow.execute(context)
    │                                              │
    │                                              └─► FlowEffect[].apply()
    │
    ├─ Input.is_action_just_released("fire")
    │      │
    │      └─► weapon.fire()
    │              │
    │              ├─ emit_signal("weapon_fired", ...)
    │              │      └─► BulletManager 监听生成子弹
    │              │      └─► Flow 监听执行其他逻辑
    │              │
    │              └─► 触发 linked_skill_slots 中 ON_FIRE 类型技能
    │                      └─► Skill → Flow 链路（同上）
    │
    └─ 蓄力完成时（charge_speed >= max_charge_speed）
           │
           └─► emit_signal("charge_complete", ...)
                   │
                   └─► Flow 监听执行其他逻辑（如特效、声音）
                   │
                   └─► 触发 linked_skill_slots 中 ON_CHARGE_MAX 类型技能
                           └─► Skill → Flow 链路
```

### 武器信号与 Flow 监听

武器暴露的信号可被 Flow 直接监听：

| 信号 | 触发时机 | Flow 可监听用途 |
|------|----------|------------------|
| `weapon_fired` | 子弹发射时 | 播放发射特效、声音 |
| `weapon_state_changed` | 状态切换时（IDLE→CHARGING→EMPTY） | UI 状态反馈 |
| `charge_complete` | 蓄力达到最大值时 | 播放蓄力完成特效 |
| `energy_changed` | 能量变化时（弩枪） | UI 能量条更新 |
| `energy_empty` | 能量耗尽时 | UI 提示、自动切换武器 |

---

## 各模块职责分工

### 模块职责矩阵

| 模块 | 生命周期管理 | 信号暴露 | Flow 触发 | Flow 配置 |
|------|-------------|----------|----------|----------|
| **BattleActor** | spawn, death, hit, kill | actor_spawned/died/hit/kill | `trigger_xxx_flow()` | spawn_flow_id, death_flow_id, hit_flow_id, kill_flow_id |
| **Weapon** | fire, charge, energy | weapon_fired, state_changed, charge_complete | 触发 Skill | linked_skill_slots[] |
| **Skill** | use, cooldown | skill_used, triggered | `flow.execute()` | on_use_flow_id |
| **Buff** | apply, remove, tick | buff_added/buff_removed | 通过 Attribute 信号 | 无直接配置 |
| **Enemy** | 继承 BattleActor | 同 BattleActor | 同 BattleActor | 数据驱动（EnemyConfig.json） |

### 模块详细说明

#### BattleActor（战斗实体基类）

**文件路径**: [BattleActor.gd](Scripts/GameBase/BattleSystemBase/BattleActor/BattleActor.gd)

生命周期事件：
- `spawn` - `_ready()` 中调用 `trigger_spawn_flow()`
- `death` - `setDead()` 中调用 `trigger_death_flow()`
- `hit` - `_beHurt()` 中调用 `trigger_hit_flow(damage, source)`
- `kill` - 击杀目标时调用 `trigger_kill_flow(target)`

信号定义：
```gdscript
signal actor_spawned(actor: BattleActor)
signal actor_died(actor: BattleActor)
signal actor_hit(actor: BattleActor, damage: float, source: BattleActor)
signal actor_kill(actor: BattleActor, target: BattleActor)
```

#### Weapon（武器）

**文件路径**: [weapon_base.gd](Scripts/GameBase/BattleSystemBase/WeaponScripts/weapon_base.gd)

生命周期事件：
- `fire` - `fire()` 方法中触发 Skill
- `hold_fire` - `hold_fire()` 方法中触发 Skill
- `charge_complete` - 蓄力达到最大值时 emit 信号
- `energy_empty` - 能量耗尽时 emit 信号

信号定义：
```gdscript
signal weapon_fired(bullet, spawn_position, direction, speed, bullet_type, owner)
signal weapon_state_changed(state: WeaponConfig.WeaponState)
signal energy_changed(current: float, max_energy: float)
```

配置属性：
```gdscript
@export var linked_skill_slots: Array[WeaponSkillSlot] = []  # 待实现
```

#### Skill（技能）

**文件路径**: [SkillBase.gd](Scripts/GameBase/BattleSystemBase/SkillSystem/SkillBase.gd)

生命周期事件：
- `use` - `use()` 方法中执行效果并触发 Flow
- `cooldown_ready` - 冷却完成时（通过 SkillManager 信号）

信号定义：
```gdscript
signal skill_used(skill: SkillBase)
signal skill_triggered(skill: SkillBase, trigger_moment)
```

配置属性：
```gdscript
@export var on_use_flow_id: String = ""  # 技能使用时触发的 Flow
```

#### Buff（增益效果）

**文件路径**: [Attribute.gd](Scripts/GameBase/BattleSystemBase/AttributeSystem/AttributeSysscript/Attribute.gd)

Buff 的生命周期事件通过 Attribute 信号传递：
```gdscript
signal buff_added(attribute: Attribute, buff: AttributeBuff)
signal buff_removed(attribute: Attribute, buff: AttributeBuff)
```

Flow 监听这些信号执行关联逻辑。

---

## WeaponSkillSlot 资源类

**文件路径**: [WeaponSkillSlot.gd](Scripts/GameBase/BattleSystemBase/WeaponScripts/WeaponSkillSlot.gd)

### TriggerType 枚举

```gdscript
enum TriggerType {
    ON_FIRE,        # 发射时触发
    ON_HIT,         # 命中时触发
    ON_KILL,        # 击杀时触发
    ON_CHARGE_MAX,  # 蓄力满时触发
    ON_ENERGY_EMPTY, # 能量耗尽时触发
}
```

### 属性定义

```gdscript
@export var skill: SkillBase              # 关联技能
@export var trigger_type: TriggerType     # 触发时机
@export var trigger_chance: float = 1.0   # 触发概率 (0.0-1.0)
```

### 核心方法

```gdscript
# 检查是否满足触发条件
func can_trigger(context: GameplayFlowContext, trigger: TriggerType) -> bool:
    if trigger_type != trigger: return false
    if skill == null or not skill.can_use(): return false
    if trigger_chance < 1.0 and randf() > trigger_chance: return false
    return true

# 触发技能
func trigger(skill_manager: SkillManager, context: GameplayFlowContext) -> bool:
    if not can_trigger(context, trigger_type): return false
    return skill_manager.use_skill(skill.skill_id, context)
```

### 使用示例

在武器发射时触发技能：
```gdscript
# WeaponBase.fire()
var context = GameplayFlowContext.create_simple(owner_actor)
context.event_data["weapon"] = self
context.event_data["position"] = get_spawn_position()

for slot in linked_skill_slots:
    if slot.trigger_type == WeaponSkillSlot.TriggerType.ON_FIRE:
        slot.trigger(owner_actor.skill_manager, context)
```

---

## 信号监听机制

### FlowRegistry 信号订阅接口

**文件路径**: [FlowRegistry.gd](Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowRegistry.gd)

FlowRegistry 提供信号订阅接口，让 Flow 可以监听模块信号：

```gdscript
# 订阅信号并关联 Flow
func subscribe_to_signal(source: Object, signal_name: String, flow_id: String) -> void:
    if not source.has_signal(signal_name):
        push_warning("FlowRegistry: %s 没有 %s 信号" % [source, signal_name])
        return
    
    if not has_flow(flow_id):
        push_warning("FlowRegistry: 未找到 Flow ID='%s'" % flow_id)
        return
    
    source.connect(signal_name, _on_signal_triggered.bind(flow_id))

# 信号触发时执行 Flow
func _on_signal_triggered(flow_id: String, ...args...) -> void:
    var flow = get_flow(flow_id)
    if flow == null: return
    
    var context = GameplayFlowContext.create_from_signal_args(args)
    flow.execute(context)
```

### 使用示例

让 Flow 监听武器的 charge_complete 信号：
```gdscript
# 在武器初始化或 Flow 配置时
FlowRegistry.subscribe_to_signal(weapon, "charge_complete", "flow_charge_feedback_001")
```

当武器蓄力完成时：
```
weapon.emit_signal("charge_complete", charge_speed)
      │
      ▼
FlowRegistry._on_signal_triggered("flow_charge_feedback_001", charge_speed)
      │
      ▼
flow.execute(context)  # context.event_data["charge_speed"] = charge_speed
      │
      ▼
FlowEffect[].apply()  # 播放蓄力完成特效
```

---

## 武器框架调整方案

### 当前问题

| 问题 | 位置 | 描述 |
|------|------|------|
| `trigger_linked_skill()` 未调用 | weapon_base.gd | 方法定义存在但从未被调用 |
| `linked_skill_slot` 无效 | weapon_base.gd | 默认值 `SECONDARY` 永不触发 |
| `WeaponSkillSlot` 未使用 | WeaponSkillSlot.gd | 更丰富的 TriggerType 枚举未被采用 |

### 调整方案

#### 1. 改用 linked_skill_slots 数组

```gdscript
# weapon_base.gd
# 旧代码（移除）
@export var linked_skill_slot: SkillConfig.SkillSlot = SkillConfig.SkillSlot.SECONDARY

# 新代码（添加）
@export var linked_skill_slots: Array[WeaponSkillSlot] = []
```

#### 2. 添加触发技能的方法

```gdscript
# weapon_base.gd
# 触发指定类型的关联技能
func trigger_skill_by_type(trigger_type: WeaponSkillSlot.TriggerType, context: GameplayFlowContext = null) -> void:
    if owner_actor == null or owner_actor.skill_manager == null:
        return
    
    if context == null:
        context = GameplayFlowContext.create_simple(owner_actor)
    
    context.event_data["weapon"] = self
    
    for slot in linked_skill_slots:
        if slot.trigger_type == trigger_type:
            slot.trigger(owner_actor.skill_manager, context)
```

#### 3. 在 fire() 和 hold_fire() 中触发

```gdscript
# weapon_base.gd
func fire() -> void:
    # ... 现有发射逻辑 ...
    
    # 触发 ON_FIRE 类型技能
    trigger_skill_by_type(WeaponSkillSlot.TriggerType.ON_FIRE)

func hold_fire() -> void:
    _is_holding = true
    _set_state(WeaponConfig.WeaponState.CHARGING)
    
    # 触发 ON_FIRE 类型技能（蓄力开始）
    trigger_skill_by_type(WeaponSkillSlot.TriggerType.ON_FIRE)
```

#### 4. 添加 charge_complete 信号

```gdscript
# weapon_base.gd
signal charge_complete(charge_speed: float)

func _update_charge(delta: float) -> void:
    # ... 现有蓄力逻辑 ...
    
    if charge_speed >= max_charge_speed:
        emit_signal("charge_complete", charge_speed)
        # 触发 ON_CHARGE_MAX 类型技能
        trigger_skill_by_type(WeaponSkillSlot.TriggerType.ON_CHARGE_MAX)
```

#### 5. 添加 energy_empty 信号

```gdscript
# weapon_base.gd
signal energy_empty()

func consume_energy(amount: float) -> bool:
    if not has_energy(amount):
        emit_signal("energy_empty")
        # 触发 ON_ENERGY_EMPTY 类型技能
        trigger_skill_by_type(WeaponSkillSlot.TriggerType.ON_ENERGY_EMPTY)
        return false
    
    current_energy -= amount
    emit_signal("energy_changed", current_energy, max_energy)
    return true
```

### 修改文件汇总

| 文件 | 修改内容 |
|------|----------|
| [weapon_base.gd](Scripts/GameBase/BattleSystemBase/WeaponScripts/weapon_base.gd) | 改用 `linked_skill_slots[]`，添加 `trigger_skill_by_type()`，添加 `charge_complete/energy_empty` 信号 |
| [WeaponSkillSlot.gd](Scripts/GameBase/BattleSystemBase/WeaponScripts/WeaponSkillSlot.gd) | 已有完整实现，无需修改 |
| [FlowRegistry.gd](Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowRegistry.gd) | 添加 `subscribe_to_signal()` 信号订阅接口 |

---

## 配置方式

### 资源文件配置 (.tres)

Flow 定义为 `.tres` 资源文件，存放在 `prefab/Flows/` 目录：

```
prefab/Flows/
├── flow_enemy_spawn_001.tres    # 怪物生成时播放特效
├── flow_enemy_death_001.tres    # 怪物死亡时播放特效
├── flow_charge_feedback.tres    # 蓄力完成时播放特效（新增）
└── flow_energy_alert.tres       # 能量耗尽时 UI 提示（新增）
```

### JSON 数据表配置 (EnemyConfig.json)

敌人配置通过 JSON 数据表驱动：

```json
{
    "enemy_001": {
        "spawn_flow_id": "flow_enemy_spawn_001",
        "death_flow_id": "flow_enemy_death_001"
    }
}
```

### 模块内 Flow ID 属性

模块通过导出属性配置 Flow：

```gdscript
# BattleActor
var spawn_flow_id: String = ""
var death_flow_id: String = ""
var hit_flow_id: String = ""
var kill_flow_id: String = ""

# SkillBase
@export var on_use_flow_id: String = ""

# WeaponBase（建议添加）
@export var charge_complete_flow_id: String = ""  # 蓄力完成时 Flow
@export var energy_empty_flow_id: String = ""     # 能量耗尽时 Flow
```

---

## 执行流程图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     GameplayFlow 执行流程                                │
└─────────────────────────────────────────────────────────────────────────┘

模块事件触发
      │
      ├─ BattleActor.trigger_xxx_flow()
      │      │
      │      └─► FlowRegistry.get_flow(flow_id)
      │              │
      │              └─► flow.deep_duplicate()
      │
      ├─ Weapon.trigger_skill_by_type()
      │      │
      │      └─► SkillManager.use_skill(skill_id)
      │              │
      │              └─► Skill.use()
      │                      │
      │                      ├─ 执行 SkillEffect[]
      │                      │
      │                      └─► FlowRegistry.get_flow(on_use_flow_id)
      │                              │
      │                              └─► flow.execute(context)
      │
      └─ FlowRegistry 监听信号
              │
              └─► _on_signal_triggered(flow_id, args)
                      │
                      └─► flow.execute(context)

flow.execute(context)
      │
      ├─ _check_condition(context)  # 检查条件表达式
      │      │
      │      └─► Expression.execute([source, target, damage, position])
      │
      └─ for effect in effects:
              effect.apply(context)
```

---

## 相关文档

- [Architecture.md](Architecture.md) - 整体架构概览
- [WeaponSystem.md](WeaponSystem.md) - 武器系统详细说明
- [SkillSystem.md](SkillSystem.md) - 技能系统详细说明
- [GameplayFlow.md](GameplayFlow.md) - GameplayFlow 系统实现说明

---

## trigger_event 属性说明

### 属性定义调整

`trigger_event` 属性应调整为可选，仅在事件触发模式下使用：

```gdscript
# GameplayFlowBase.gd
# trigger_event 仅在事件触发模式下需要
# 直接触发模式下，此属性无效
@export var trigger_event: FlowEvent = FlowEvent.NONE  # 无默认值

enum FlowEvent {
    NONE,           # 无触发事件（直接触发模式）
    ON_LEVEL_START, # 关卡开始时
    ON_WAVE_START,  # 波次开始时
    ON_WAVE_END,    # 波次结束时
    ON_LEVEL_END,   # 关卡结束时
    ON_TIMER,       # 定时触发
    # 保留原有事件（兼容旧代码）
    ON_SPAWN,       # 实体生成时（已废弃，改用 ActorFlow 直接触发）
    ON_DEATH,       # 实体死亡时（已废弃，改用 ActorFlow 直接触发）
    ON_HIT,         # 受到伤害时（已废弃，改用 ActorFlow 直接触发）
    ON_KILL,        # 造成击杀时（已废弃，改用 ActorFlow 直接触发）
}
```

### 使用建议

| Flow 类型 | trigger_event | 触发模式 |
|-----------|--------------|----------|
| SkillFlow | NONE（不需要） | 直接触发 |
| BuffFlow | NONE（不需要） | 直接触发 |
| ActorFlow | NONE（不需要） | 直接触发 |
| LevelFlow | 必须定义 | 事件触发 |
| GameplayFlowBase | 可选 | 视使用场景而定 |