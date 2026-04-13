# GameplayFlow 系统说明文档

## 设计理念

GameplayFlow 是**可配置的行为脚本**，用于事件驱动的可复用行为。

**核心定位**：
- GameplayFlow 不是生命周期系统本身，而是模块在生命周期事件点上可配置的行为脚本
- 生命周期由各模块自行管理，模块在特定事件点调用配置的 GameplayFlow
- GameplayFlow 作为基类，可派生出 SkillFlow、BuffFlow、ActorFlow、LevelFlow 等子类

**两种触发模式**：
1. **直接触发模式**：Flow 绑定在模块资产上，模块直接调用 `flow.start(context)`
2. **事件触发模式**：Flow 由系统统一管理，根据 `trigger_event` 自动触发（适用于关卡初始化等）

---

## 目录结构

```
Scripts/GameBase/BattleSystemBase/GameplayFlow/
├── GameplayFlowBase.gd        # Flow 基类
├── GameplayFlowContext.gd     # 执行上下文
├── GameplayFlowRegistry.gd    # 注册表（Autoload）
├── FlowEffect/
│   ├── FlowEffectBase.gd      # 效果基类
│   ├── FE_Damage.gd           # 伤害效果
│   ├── FE_SpawnVfx.gd         # 生成特效效果
│   ├── FE_ApplyBuff.gd        # 应用 Buff 效果
│   ├── FE_ModifyAttribute.gd  # 修改属性效果
│   └── FE_SpawnEntity.gd      # 生成实体效果
└── FlowSubclass/              # Flow 子类（待实现）
    ├── SkillFlow.gd           # 技能系统 Flow
    ├── BuffFlow.gd            # Buff 系统 Flow
    ├── ActorFlow.gd           # 角色系统 Flow
    └── LevelFlow.gd           # 关卡系统 Flow
```

---

## GameplayFlowBase 基类

**文件路径**: [GameplayFlowBase.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowBase.gd)

### FlowEvent 枚举

```gdscript
enum FlowEvent {
    NONE,           # 无触发事件（直接触发模式）
    ON_LEVEL_START, # 关卡开始时（事件触发模式）
    ON_WAVE_START,  # 波次开始时（事件触发模式）
    ON_WAVE_END,    # 波次结束时（事件触发模式）
    ON_LEVEL_END,   # 关卡结束时（事件触发模式）
    ON_TIMER,       # 定时触发（事件触发模式）
    
    # 以下事件用于兼容旧代码，推荐改用子类直接触发
    ON_SPAWN,       # 实体生成时（建议用 ActorFlow 直接触发）
    ON_DEATH,       # 实体死亡时（建议用 ActorFlow 直接触发）
    ON_HIT,         # 受到伤害时（建议用 ActorFlow 直接触发）
    ON_KILL,        # 造成击杀时（建议用 ActorFlow 直接触发）
    ON_SKILL_USE,   # 使用技能时（建议用 SkillFlow 直接触发）
    ON_BUFF_APPLY,  # Buff 应用时（建议用 BuffFlow 直接触发）
    ON_BUFF_REMOVE, # Buff 移除时（建议用 BuffFlow 直接触发）
}
```

### 属性定义

```gdscript
class_name GameplayFlowBase extends Resource

@export var flow_id: String = ""                       # 唯一标识
@export var flow_name: String = ""                     # Flow 名称（显示用）

# trigger_event 仅在事件触发模式下使用
# 直接触发模式下此属性无效，应设为 NONE
@export var trigger_event: FlowEvent = FlowEvent.NONE  # 触发事件类型

@export var effects: Array[FlowEffectBase] = []        # 效果列表
@export var condition_expression: String = ""          # 条件表达式
@export var cooldown: float = 0.0                      # 触发冷却（秒）
```

**trigger_event 使用说明**：

| 触发模式 | trigger_event 值 | 说明 |
|----------|-----------------|------|
| 直接触发 | `NONE` | Flow 由模块直接调用，不需要触发事件 |
| 事件触发 | 非 `NONE` | Flow 由系统自动触发，需定义触发时机 |

### 执行流程

```gdscript
func start(context: GameplayFlowContext) -> bool:
    # 1. 检查冷却
    if not _check_cooldown():
        return false
    
    # 2. 检查条件表达式
    if not _check_condition(context):
        return false
    
    # 3. 按优先级执行效果
    var sorted_effects = effects.duplicate()
    sorted_effects.sort_custom(func(a, b): return a.priority < b.priority)
    
    for effect in sorted_effects:
        if effect:
            effect.apply(context)
    
    return true

# execute() 是 start() 的别名，兼容旧代码
func execute(context: GameplayFlowContext) -> bool:
    return start(context)
```

---

## GameplayFlowContext 执行上下文

**文件路径**: [GameplayFlowContext.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowContext.gd)

### 属性结构

```gdscript
class_name GameplayFlowContext extends RefCounted

var source: BattleActor = null       # 触发源
var target: BattleActor = null       # 目标
var event_data: Dictionary = {}      # 事件数据

# 常用 event_data 字段:
# - "damage": float      # 伤害值
# - "position": Vector2  # 位置
# - "skill_id": String   #技能 ID
# - "buff_id": String    # Buff ID
```

### 静态工厂方法

```gdscript
# 创建简单上下文
static func create_simple(source_actor: BattleActor) -> GameplayFlowContext

# 创建攻击上下文
static func create_attack(source_actor, target_actor, damage: float) -> GameplayFlowContext

# 创建位置上下文
static func create_at_position(pos: Vector2, source_actor) -> GameplayFlowContext
```

### 辅助方法

```gdscript
func get_damage() -> float:
    return event_data.get("damage", 0.0)

func get_position() -> Vector2:
    if event_data.has("position"):
        return event_data["position"]
    if target:
        return target.global_position
    return Vector2.ZERO

func get_skill_id() -> String:
    return event_data.get("skill_id", "")

func get_buff_id() -> String:
    return event_data.get("buff_id", "")
```

---

## FlowRegistry 注册表

**文件路径**: [GameplayFlowRegistry.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowRegistry.gd)

作为 Autoload 单例，管理 Flow 资源的加载、缓存和获取。

### 核心结构

```gdscript
# === Flow 缓存 ===
var _flow_cache: Dictionary = {}            # {flow_id: GameplayFlowBase}

# === 按事件分类 ===
var _flows_by_event: Dictionary = {}        # {FlowEvent: Array[GameplayFlowBase]}

signal flow_registry_initialized
```

### 核心 API

```gdscript
# 获取 Flow（返回深拷贝实例）
func get_flow(flow_id: String) -> GameplayFlowBase:
    if not _flow_cache.has(flow_id): return null
    var flow_template = _flow_cache[flow_id]
    return flow_template.deep_duplicate()

# 获取指定事件类型的所有 Flow
func get_flows_by_event(event: FlowEvent) -> Array[GameplayFlowBase]:
    var templates = _flows_by_event.get(event, [])
    var result = []
    for template in templates:
        result.append(template.deep_duplicate())
    return result

# 检查 Flow 是否存在
func has_flow(flow_id: String) -> bool:
    return _flow_cache.has(flow_id)

# 获取所有已注册的 Flow ID
func get_all_flow_ids() -> Array[String]
```

### 自动扫描注册

```gdscript
func _scan_and_register_flows() -> void:
    var flow_dir = "res://prefab/Flows/"
    
    var dir = DirAccess.open(flow_dir)
    if dir == null: return
    
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if not dir.current_is_dir() and file_name.ends_with(".tres"):
            var full_path = flow_dir + file_name
            _load_and_register_flow(full_path)
        file_name = dir.get_next()
    
    dir.list_dir_end()

func register_flow(flow: GameplayFlowBase) -> void:
    _flow_cache[flow.flow_id] = flow
    _flows_by_event[flow.trigger_event].append(flow)
```

---

## FlowEffect 效果系统

### FlowEffectBase 基类

**文件路径**: [FlowEffectBase.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FlowEffectBase.gd)

```gdscript
class_name FlowEffectBase extends Resource

@export var priority: int = 0        # 效果优先级（用于排序执行）

# === 核心方法（子类必须重写）===
func apply(context: GameplayFlowContext) -> void
func get_description() -> String     # 效果描述
```

---

### FE_Damage 伤害效果

**文件路径**: [FE_Damage.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_Damage.gd)

```gdscript
class_name FE_Damage extends FlowEffectBase

@export var base_damage: float = 10.0
@export var use_source_attack: bool = true      # 使用 source 的攻击力
@export var use_target_armor: bool = true       # 使用 target 的护甲减免
@export var damage_multiplier: float = 1.0      # 伤害倍率

func apply(context: GameplayFlowContext) -> void:
    if context.target == null: return
    
    var damage = base_damage * damage_multiplier
    
    # 攻击力加成
    if use_source_attack and context.source:
        var atk_attr = context.source.GetAttributes().find_attribute(AttributeConfig.AttributeName.Atk)
        if atk_attr: damage += atk_attr.computed_value
    
    # 护甲减免
    if use_target_armor and context.target:
        var armor_attr = context.target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Armor)
        if armor_attr: damage -= armor_attr.computed_value
    
    damage = max(0.0, damage)
    
    # 应用伤害
    var hp_attr = context.target.GetAttributes().find_attribute(AttributeConfig.AttributeName.Hp)
    if hp_attr: hp_attr.sub(damage)
```

---

### FE_SpawnVfx 生成特效效果

**文件路径**: [FE_SpawnVfx.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_SpawnVfx.gd)

```gdscript
class_name FE_SpawnVfx extends FlowEffectBase

@export var vfx_type: VfxConfig.VfxType = VfxConfig.VfxType.HIT_IMPACT
@export var position_offset: Vector2 = Vector2.ZERO
@export var follow_target: bool = false

func apply(context: GameplayFlowContext) -> void:
    if VfxManager.instance == null: return
    
    var spawn_position = context.get_position() + position_offset
    
    if follow_target and context.target:
        VfxManager.instance.play_vfx_follow(vfx_type, context.target, position_offset)
    else:
        VfxManager.instance.play_vfx(vfx_type, spawn_position)
```

---

### FE_ApplyBuff 应用 Buff 效果

**文件路径**: [FE_ApplyBuff.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_ApplyBuff.gd)

```gdscript
class_name FE_ApplyBuff extends FlowEffectBase

@export var buff_id: String = ""
@export var use_source_as_owner: bool = true

func apply(context: GameplayFlowContext) -> void:
    if buff_id.is_empty(): return
    if context.target == null: return
    
    var source = context.source if use_source_as_owner else context.target
    BattleManager.ApplyBuff(source, context.target, buff_id)
```

---

### FE_ModifyAttribute 修改属性效果

**文件路径**: [FE_ModifyAttribute.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_ModifyAttribute.gd)

```gdscript
class_name FE_ModifyAttribute extends FlowEffectBase

@export var attribute_name: AttributeConfig.AttributeName = AttributeConfig.AttributeName.Hp
@export var modification_type: ModificationType = ModificationType.ADD
@export var value: float = 0.0

enum ModificationType {
    ADD,        # 加值
    MULTIPLY,   #乘值
    SET,        # 设值
}

func apply(context: GameplayFlowContext) -> void:
    if context.target == null: return
    
    var attr = context.target.GetAttributes().find_attribute(attribute_name)
    if attr == null: return
    
    match modification_type:
        ModificationType.ADD:
            if attribute_name == AttributeConfig.AttributeName.Hp:
                attr.add(value)
            else:
                attr.base_value += value
        ModificationType.MULTIPLY:
            attr.base_value *= value
        ModificationType.SET:
            attr.base_value = value
```

---

### FE_SpawnEntity 生成实体效果

**文件路径**: [FE_SpawnEntity.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_SpawnEntity.gd)

```gdscript
class_name FE_SpawnEntity extends FlowEffectBase

@export var entity_prefab: PackedScene
@export var position_offset: Vector2 = Vector2.ZERO
@export var inherit_owner: bool = true

func apply(context: GameplayFlowContext) -> void:
    if entity_prefab == null: return
    
    var spawn_position = context.get_position() + position_offset
    
    var entity = entity_prefab.instantiate()
    
    # 设置 owner
    if inherit_owner and context.source and "owner_actor" in entity:
        entity.owner_actor = context.source
    
    # 添加到场景
    var tree = context.source.get_tree() if context.source else null
    if tree and tree.current_scene:
        tree.current_scene.add_child(entity)
    
    entity.global_position = spawn_position
```

---

## 效果组合模式

### Flow 执行流程图

```
GameplayFlowBase.execute(context)
      │
      ▼
检查冷却: _check_cooldown()
      │
      ▼
检查条件: _check_condition(context)
      │
      ▼
按优先级排序效果:
  effects.sort_custom(priority)
      │
      ▼
依次执行效果:
  ├── FE_SpawnVfx (priority=0)     # 播放特效
  ├── FE_Damage (priority=10)      # 造成伤害
  ├── FE_ApplyBuff (priority=20)   # 应用 Buff
  └── FE_ModifyAttribute (priority=30) # 修改属性
```

### 组合示例

一个完整的 Flow 可以组合多个效果：

```
敌人死亡 Flow (flow_enemy_death_001):
├── trigger_event: ON_DEATH
├── effects:
│   ├── FE_SpawnVfx (priority=0)      # 播放死亡特效
│   ├── FE_ApplyBuff (priority=10)    # 对周围敌人应用 Buff
│   └── FE_SpawnEntity (priority=20)  #生成掉落物
└── condition_expression: "target.level >= 5"
```

---

## 使用场景

### 1. Enemy 生命周期

```gdscript
# base_enemy.gd
@export var spawn_flow_id: String = ""
@export var death_flow_id: String = ""
@export var hit_flow_id: String = ""

func _ready():
    trigger_spawn_flow()

func setDead():
    trigger_death_flow()

func trigger_spawn_flow():
    if spawn_flow_id.is_empty(): return
    var flow = FlowRegistry.instance.get_flow(spawn_flow_id)
    if flow:
        var context = GameplayFlowContext.create_simple(self)
        flow.execute(context)

func trigger_death_flow():
    if death_flow_id.is_empty(): return
    var flow = FlowRegistry.instance.get_flow(death_flow_id)
    if flow:
        var context = GameplayFlowContext.create_simple(self)
        context.event_data["position"] = global_position
        flow.execute(context)

func trigger_hit_flow(damage: float):
    if hit_flow_id.is_empty(): return
    var flow = FlowRegistry.instance.get_flow(hit_flow_id)
    if flow:
        var context = GameplayFlowContext.create_attack(null, self, damage)
        flow.execute(context)
```

### 2. Skill 效果关联

```gdscript
# SkillBase.gd
@export var on_use_flow_id: String = ""

func use(context: GameplayFlowContext) -> bool:
    # ... 执行技能效果
    
    # 触发关联 Flow
    if not on_use_flow_id.is_empty():
        var flow = FlowRegistry.instance.get_flow(on_use_flow_id)
        if flow: flow.execute(context)
```

### 3. Buff 效果关联

```gdscript
# AttributeBuff.gd
@export var on_apply_flow_id: String = ""
@export var on_remove_flow_id: String = ""
```

---

## BattleManager Flow API

**文件路径**: [BattleManager.gd](../Scripts/GameBase/BattleSystemBase/BattleSystem/BattleManager.gd)

```gdscript
# 执行指定 Flow（直接触发模式）
static func ExecuteFlow(flow_id: String, context: GameplayFlowContext) -> void:
    if FlowRegistry.instance == null: return
    var flow = FlowRegistry.instance.get_flow(flow_id)
    if flow: flow.start(context)

# 触发指定事件的所有 Flow（事件触发模式）
static func TriggerFlowEvent(event: GameplayFlowBase.FlowEvent, context: GameplayFlowContext) -> void:
    if FlowRegistry.instance == null: return
    var flows = FlowRegistry.instance.get_flows_by_event(event)
    for flow in flows:
        flow.start(context)
```

---

## GameplayFlow 子类

### 设计目的

GameplayFlowBase 作为基类，派生出特定系统的子类：

- 约束固定的上下文字段，减少配置错误
- 提供特定系统的便捷方法
- 编辑器插件可提供针对性的配置界面

### SkillFlow（技能 Flow）

约束技能系统的固定上下文：

```gdscript
class_name SkillFlow extends GameplayFlowBase

@export var skill_id: String = ""           # 关联技能 ID
@export var target_selection: TargetType    # 目标选择方式

func create_context(skill: SkillBase, user: BattleActor, target: BattleActor) -> SkillFlowContext
```

### BuffFlow（Buff Flow）

约束 Buff 系统的固定上下文：

```gdscript
class_name BuffFlow extends GameplayFlowBase

@export var buff_id: String = ""            # 关联 Buff ID
@export var duration_override: float = -1   # 覆盖持续时间

func create_context(buff: AttributeBuff, source: BattleActor, target: BattleActor) -> BuffFlowContext
```

### ActorFlow（角色 Flow）

约束角色系统的固定上下文：

```gdscript
class_name ActorFlow extends GameplayFlowBase

@export var actor_id: String = ""           # 关联角色 ID
@export var position_mode: PositionMode     # 位置模式

func create_context(actor: BattleActor) -> ActorFlowContext
```

### LevelFlow（关卡 Flow）

约束关卡系统的固定上下文，需要 `trigger_event`：

```gdscript
class_name LevelFlow extends GameplayFlowBase

@export var level_id: String = ""           # 关联关卡 ID
@export var wave_id: int = -1               # 波次 ID
@export var trigger_event: LevelEvent       # 触发事件（必须定义）

enum LevelEvent {
    ON_LEVEL_START,     # 关卡开始时
    ON_WAVE_START,      # 波次开始时
    ON_WAVE_END,        # 波次结束时
    ON_LEVEL_END,       # 关卡结束时
}
```

---

## 关键代码路径汇总表

| 类/文件 | 路径 |
|--------|------|
| GameplayFlowBase | [Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowBase.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowBase.gd) |
| GameplayFlowContext | [Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowContext.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowContext.gd) |
| FlowRegistry | [Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowRegistry.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowRegistry.gd) |
| FlowEffectBase | [Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FlowEffectBase.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FlowEffectBase.gd) |
| FE_Damage | [Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_Damage.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_Damage.gd) |
| FE_SpawnVfx | [Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_SpawnVfx.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_SpawnVfx.gd) |
| FE_ApplyBuff | [Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_ApplyBuff.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_ApplyBuff.gd) |
| FE_ModifyAttribute | [Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_ModifyAttribute.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_ModifyAttribute.gd) |
| FE_SpawnEntity | [Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_SpawnEntity.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/FlowEffect/FE_SpawnEntity.gd) |
| BattleManager | [Scripts/GameBase/BattleSystemBase/BattleSystem/BattleManager.gd](../Scripts/GameBase/BattleSystemBase/BattleSystem/BattleManager.gd) |
| base_enemy | [Scripts/GameBase/BattleSystemBase/BattleActor/base_enemy.gd](../Scripts/GameBase/BattleSystemBase/BattleActor/base_enemy.gd) |
| VfxManager | [Scripts/GameBase/BattleSystemBase/VfxSystem/VfxManager.gd](../Scripts/GameBase/BattleSystemBase/VfxSystem/VfxManager.gd) |
| VfxConfig | [Scripts/GameBase/BattleSystemBase/VfxSystem/VfxConfig.gd](../Scripts/GameBase/BattleSystemBase/VfxSystem/VfxConfig.gd) |

---

## 相关文档

- [Architecture.md](Architecture.md) - 整体架构概览
- [SkillSystem.md](SkillSystem.md) - 技能系统（SkillBase.on_use_flow_id 关联）
- [WeaponSystem.md](WeaponSystem.md) - 武器系统
- [BulletSystem.md](BulletSystem.md) - 子弹系统
- [GameplayFlowDesign.md](GameplayFlowDesign.md) - GameplayFlow 设计理念详细说明