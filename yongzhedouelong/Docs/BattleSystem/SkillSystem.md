# 技能系统说明文档

## 目录结构

```
Scripts/GameBase/BattleSystemBase/SkillSystem/
├── SkillConfig.gd          # 配置枚举定义
├── SkillBase.gd            # 技能基类
├── SkillCooldown.gd        # 冷却管理
├── SkillManager.gd         # 技能管理器
├── SkillTrigger.gd         # 触发条件系统
├── SkillRegistry.gd        # 技能注册表（Autoload）
└── SkillEffect/
    ├── SkillEffectBase.gd  # 效果基类
    ├── SE_Projectile.gd    # 投射物效果
    ├── SE_AreaEffect.gd    # 区域效果
    ├── SE_BuffApply.gd     # Buff 应用效果
    ├── SE_Damage.gd        # 直接伤害效果
    └── SE_Heal.gd          # 治疗效果
```

---

## SkillConfig 配置类

**文件路径**: [SkillConfig.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillConfig.gd)

### 枚举定义

#### SkillType - 技能类型

```gdscript
enum SkillType {
    ACTIVE,          # 主动技能（玩家手动触发）
    PASSIVE,         # 被动技能（自动生效，如属性加成）
    TRIGGERED,       # 触发技能（条件触发，如暴击触发）
    TOGGLE,          # 开关技能（持续效果，可开关）
}
```

| 类型 | 说明 | 使用场景 |
|------|------|---------|
| ACTIVE | 玩家主动触发 | 攻击技能、AOE 技能 |
| PASSIVE | 自动生效 | 属性加成、光环效果 |
| TRIGGERED | 条件触发 | 暴击触发、受伤触发、击杀触发 |
| TOGGLE | 开关状态 | 持续性效果、自动攻击 |

#### TargetType - 目标类型

```gdscript
enum TargetType {
    SELF,            # 自身
    ENEMY_SINGLE,    # 单个敌人
    ENEMY_AREA,      # 区域内的敌人
    ALLY_SINGLE,     # 单个友方
    ALLY_AREA,       # 区域内的友方
    DIRECTION,       # 指定方向
    POSITION,        # 指定位置
    NONEAREST_ENEMY, # 最近敌人
}
```

#### CostType - 消耗类型

```gdscript
enum CostType {
    MANA,            # 法力值
    ENERGY,          # 武器能量（弩枪系统）
    HP,              # 生命值（血祭类技能）
    COOLDOWN_ONLY,   # 仅冷却时间消耗
    NONE,            # 无消耗
}
```

#### TriggerMoment - 触发时机

```gdscript
enum TriggerMoment {
    ON_HIT,          # 受伤时
    ON_KILL,         # 击杀时
    ON_ATTACK,       # 攻击时
    ON_CRIT,         # 暴击时
    ON_BUFF_APPLY,   # Buff 应用时
    ON_BUFF_REMOVE,  # Buff 移除时
    ON_SKILL_USE,    # 使用技能时
    ON_TIMER,        # 定时触发
    ON_SPAWN,        # 生成时
    ON_DEATH,        # 死亡时
}
```

#### SkillSlot - 技能槽位

```gdscript
enum SkillSlot {
    PRIMARY,         # 主技能槽（通常绑定武器）
    SECONDARY,       # 副技能槽
    ULTIMATE,        # 终极技能槽
    PASSIVE_SLOT,    # 被动技能槽（可多个）
}
```

---

## SkillBase 基类

**文件路径**: [SkillBase.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillBase.gd)

### 属性说明

```gdscript
class_name SkillBase extends Resource

# === 基础属性 ===
@export var skill_id: String = ""           # 唯一标识
@export var skill_name: String = ""         # 技能名称
@export_multiline var skill_description: String = ""  # 技能描述

# === 类型配置 ===
@export var skill_type: SkillConfig.SkillType = SkillConfig.SkillType.ACTIVE
@export var target_type: SkillConfig.TargetType = SkillConfig.TargetType.ENEMY_SINGLE
@export var target_range: float = 100.0     # 目标范围（用于 AREA 类型）

# === 消耗配置 ===
@export var cost_type: SkillConfig.CostType = SkillConfig.CostType.MANA
@export var cost_value: float = 20.0

# === 冷却配置 ===
@export var cooldown_time: float = 5.0

# === 效果系统 ===
@export var effects: Array[SkillEffectBase] = []  # 技能效果列表
@export var triggers: Array[SkillTrigger] = []    # 触发条件列表（TRIGGERED 类型）

# === GameplayFlow 集成 ===
@export var on_use_flow_id: String = ""    # 关联的 GameplayFlow（可选）

# === UI 显示 ===
@export var icon_path: String = ""         # 技能图标路径

# === 运行时数据 ===
var cooldown: SkillCooldown                # 冷却管理器实例
var skill_owner: BattleActor = null        # 技能拥有者
var is_active: bool = false                # TOGGLE 类型状态标记
```

### 核心方法

#### 初始化流程

```gdscript
func initialize(owner: BattleActor) -> void:
    skill_owner = owner
    cooldown = SkillCooldown.new()
    cooldown.init(cooldown_time)
    
    # 被动技能立即激活
    if skill_type == SkillConfig.SkillType.PASSIVE:
        activate_passive()
```

#### 可用性检查

```gdscript
func can_use() -> bool:
    # 检查冷却
    if not cooldown.is_ready(): return false
    
    # 检查消耗
    if not _check_cost(): return false
    
    # TOGGLE 特殊处理（开关状态时也可用）
    if skill_type == SkillConfig.SkillType.TOGGLE and is_active:
        return true
    
    return true
```

#### 使用流程

```gdscript
func use(context: GameplayFlowContext = null) -> bool:
    if not can_use(): return false
    
    # 创建默认上下文
    if context == null:
        context = _create_default_context()
    
    # 消耗资源
    _consume_cost()
    
    # TOGGLE 特殊处理
    if skill_type == SkillConfig.SkillType.TOGGLE:
        is_active = not is_active
        if is_active: _execute_effects(context)
        else: _cleanup_effects(context)
        return true
    
    # 开始冷却
    cooldown.start()
    
    # 执行效果
    _execute_effects(context)
    
    # 触发关联 GameplayFlow
    if not on_use_flow_id.is_empty() and FlowRegistry.instance:
        var flow = FlowRegistry.instance.get_flow(on_use_flow_id)
        if flow: flow.execute(context)
    
    return true
```

#### 触发检查（TRIGGERED 类型）

```gdscript
func check_trigger(trigger_moment: SkillConfig.TriggerMoment, context: GameplayFlowContext) -> bool:
    if skill_type != SkillConfig.SkillType.TRIGGERED: return false
    
    for trigger in triggers:
        if trigger.trigger_moment == trigger_moment:
            var current_time = Time.get_ticks_msec() / 1000.0
            if trigger.check_trigger(context, current_time):
                return true
    return false
```

---

## SkillCooldown 冷却管理

**文件路径**: [SkillCooldown.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillCooldown.gd)

### 属性和方法

```gdscript
class_name SkillCooldown extends RefCounted

var cooldown_time: float = 0.0      # 冷却时间（秒）
var remaining_cooldown: float = 0.0 # 剩余冷却时间
var is_cooling: bool = false        # 是否正在冷却

signal cooldown_finished()          # 冷却完成信号

# === 核心方法 ===
func init(duration: float) -> void      # 初始化冷却时间
func start() -> void                     # 开始冷却
func update(delta: float) -> void        # 每帧更新（在 SkillManager 中调用）
func force_end() -> void                 # 强制结束冷却
func reset() -> void                     # 重置冷却
func is_ready() -> bool                  # 是否可用（冷却结束）
func get_progress() -> float             # 获取冷却进度 (0.0-1.0)
func get_remaining() -> float            # 获取剩余冷却时间
```

### 更新逻辑

```gdscript
func update(delta: float) -> void:
    if is_cooling:
        remaining_cooldown -= delta
        if remaining_cooldown <= 0.0:
            remaining_cooldown = 0.0
            is_cooling = false
            cooldown_finished.emit()
```

---

## SkillManager 技能管理器

**文件路径**: [SkillManager.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillManager.gd)

### 属性结构

```gdscript
class_name SkillManager extends Node

# === 技能存储 ===
var skills: Array[SkillBase] = []           # 所有技能
var active_skills: Array[SkillBase] = []    # 主动技能列表
var passive_skills: Array[SkillBase] = []   # 被动技能列表
var triggered_skills: Array[SkillBase] = [] # 触发技能列表
var toggle_skills: Array[SkillBase] = []    # 开关技能列表

# === 槽位管理 ===
var skill_slots: Dictionary = {}            # {SkillSlot: SkillBase}

var skill_owner: BattleActor = null         # 技能拥有者

# === 信号 ===
signal skill_used(skill: SkillBase)
signal skill_cooldown_finished(skill: SkillBase)
signal skill_triggered(skill: SkillBase, trigger_moment: SkillConfig.TriggerMoment)
```

### 核心功能

#### 技能添加与槽位管理

```gdscript
func add_skill(skill: SkillBase, slot: SkillConfig.SkillSlot = SkillConfig.SkillSlot.SECONDARY) -> void:
    if skill == null: return
    
    # 创建副本实例
    var instance = skill.duplicate(true)
    instance.initialize(skill_owner)
    
    skills.append(instance)
    
    # 按类型分类
    match instance.skill_type:
        SkillConfig.SkillType.ACTIVE: active_skills.append(instance)
        SkillConfig.SkillType.PASSIVE: passive_skills.append(instance)
        SkillConfig.SkillType.TRIGGERED: triggered_skills.append(instance)
        SkillConfig.SkillType.TOGGLE: toggle_skills.append(instance)
    
    # 设置槽位
    skill_slots[slot] = instance
    
    # 连接冷却完成信号
    instance.cooldown.cooldown_finished.connect(_on_skill_cooldown_finished.bind(instance))
```

#### 技能使用 API

```gdscript
# 按 ID 使用
func use_skill(skill_id: String, context: GameplayFlowContext = null) -> bool:
    for skill in active_skills:
        if skill.skill_id == skill_id:
            return _use_skill_internal(skill, context)
    for skill in toggle_skills:
        if skill.skill_id == skill_id:
            return _use_skill_internal(skill, context)
    return false

# 按槽位使用
func use_slot_skill(slot: SkillConfig.SkillSlot, context: GameplayFlowContext = null) -> bool:
    var skill = skill_slots.get(slot)
    if skill:
        return _use_skill_internal(skill, context)
    return false

# 检查可用性
func can_use_skill(skill_id: String) -> bool
func can_use_slot(slot: SkillConfig.SkillSlot) -> bool
```

#### 触发事件处理

```gdscript
func handle_trigger_event(trigger_moment: SkillConfig.TriggerMoment, context: GameplayFlowContext) -> void:
    for skill in triggered_skills:
        if skill.check_trigger(trigger_moment, context):
            # 触发技能自动使用
            if skill.use(context):
                skill_triggered.emit(skill, trigger_moment)
```

#### 冷却自动更新

```gdscript
func _physics_process(delta: float) -> void:
    # 更新所有技能的冷却
    for skill in skills:
        skill.update_cooldown(delta)
```

---

## SkillRegistry 技能注册表

**文件路径**: [SkillRegistry.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillRegistry.gd)

作为 Autoload 单例，管理技能资源的加载、缓存和获取。

### 核心结构

```gdscript
# === 技能缓存 ===
var _skill_cache: Dictionary = {}            # {skill_id: SkillBase}
var _active_skills: Array[SkillBase] = []    # 按类型分类缓存
var _passive_skills: Array[SkillBase] = []
var _triggered_skills: Array[SkillBase] = []

signal skill_registry_initialized
```

### 核心 API

```gdscript
# 获取技能（返回深拷贝实例）
func get_skill(skill_id: String) -> SkillBase:
    if not _skill_cache.has(skill_id): return null
    var skill_template = _skill_cache[skill_id]
    return skill_template.duplicate(true)

# 获取分类技能列表
func get_all_active_skills() -> Array[SkillBase]
func get_all_passive_skills() -> Array[SkillBase]
func get_all_triggered_skills() -> Array[SkillBase]

# 创建并初始化技能实例
func create_skill_instance(skill_id: String, owner: BattleActor) -> SkillBase:
    var skill_template = get_skill(skill_id)
    if skill_template == null: return null
    skill_template.initialize(owner)
    return skill_template

# 为 BattleActor 设置 SkillManager
func setup_skill_manager(actor: BattleActor, skill_ids: Array[String]) -> SkillManager:
    var manager = SkillManager.new()
    actor.add_child(manager)
    for skill_id in skill_ids:
        var skill = create_skill_instance(skill_id, actor)
        if skill: manager.add_skill(skill)
    return manager
```

### 自动扫描注册

```gdscript
func _scan_and_register_skills() -> void:
    var skill_dir = "res://prefab/Skills/"
    
    var dir = DirAccess.open(skill_dir)
    if dir == null: return
    
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if not dir.current_is_dir() and file_name.ends_with(".tres"):
            var full_path = skill_dir + file_name
            _load_and_register_skill(full_path)
        file_name = dir.get_next()
    
    dir.list_dir_end()

func _load_and_register_skill(path: String) -> void:
    var resource = load(path)
    if resource is SkillBase:
        register_skill(resource)
```

---

## SkillTrigger 触发条件系统

**文件路径**: [SkillTrigger.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillTrigger.gd)

### 属性定义

```gdscript
class_name SkillTrigger extends Resource

@export var trigger_moment: SkillConfig.TriggerMoment = SkillConfig.TriggerMoment.ON_ATTACK
@export var trigger_chance: float = 1.0                     # 触发概率 (0.0-1.0)
@export var condition_expression: String = ""               # 条件表达式
@export var trigger_interval: float = 0.0                   # 触发间隔（秒）

var _last_trigger_time: float = 0.0                         # 上次触发时间
```

### 触发检查逻辑

```gdscript
func check_trigger(context: GameplayFlowContext, current_time: float) -> bool:
    # 1. 检查触发间隔
    if trigger_interval > 0.0 and current_time - _last_trigger_time < trigger_interval:
        return false
    
    # 2. 检查触发概率
    if trigger_chance < 1.0 and randf() > trigger_chance:
        return false
    
    # 3. 检查条件表达式
    if not condition_expression.is_empty():
        if not _check_expression(context):
            return false
    
    _last_trigger_time = current_time
    return true
```

---

## SkillEffect 效果系统

### SkillEffectBase 基类

**文件路径**: [SkillEffectBase.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SkillEffectBase.gd)

```gdscript
class_name SkillEffectBase extends Resource

@export var priority: int = 0        # 效果优先级（用于排序执行）

# === 核心方法（子类必须重写）===
func apply(context: GameplayFlowContext, skill: SkillBase) -> void
func cleanup(context: GameplayFlowContext, skill: SkillBase) -> void  # 效果清理
func get_description() -> String                                     # 效果描述
```

---

### SE_Projectile 投射物效果

**文件路径**: [SE_Projectile.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_Projectile.gd)

```gdscript
class_name SE_Projectile extends SkillEffectBase

@export var bullet_prefab: PackedScene
@export var speed: float = 400.0

enum DirectionType {
    TARGET_DIRECTION,    # 朝目标方向
    FIXED_DIRECTION,     # 固定方向
    SPREAD,              # 扇形散射
    HOMING,              # 追踪目标
}

@export var direction_type: DirectionType = DirectionType.TARGET_DIRECTION
@export var spread_count: int = 1          # 散射数量
@export var spread_angle: float = 30.0     # 散射角度范围
@export var bullet_type: int = 0
@export var damage_buff_id: String = "1001"
```

---

### SE_AreaEffect 区域效果

**文件路径**: [SE_AreaEffect.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_AreaEffect.gd)

```gdscript
class_name SE_AreaEffect extends SkillEffectBase

@export var area_radius: float = 100.0
@export var duration: float = 1.0

enum AreaShape { CIRCLE, RECTANGLE }
enum CenterType { TARGET_POSITION, SOURCE_POSITION, MANUAL_OFFSET }

@export var show_vfx: bool = true
@export var vfx_type: VfxConfig.VfxType = VfxConfig.VfxType.SKILL_EFFECT

@export var per_frame_effects: Array[FlowEffectBase] = []     # 区域内每帧效果
@export var on_enter_effects: Array[FlowEffectBase] = []      # 进入时一次性效果
```

---

### SE_BuffApply Buff 应用效果

**文件路径**: [SE_BuffApply.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_BuffApply.gd)

```gdscript
class_name SE_BuffApply extends SkillEffectBase

@export var buff_id: String = ""
@export var use_source_as_owner: bool = true
@export var duration_override: float = -1.0

enum TargetSelection {
    SKILL_TARGET,      # 使用技能的目标
    SELF,              # 自身
    AREA_TARGETS,      # 区域内的目标
    ALL_ENEMIES,       # 所有敌人
    ALL_ALLIES,        # 所有友方
}

@export var target_selection: TargetSelection = TargetSelection.SKILL_TARGET
@export var selection_radius: float = 100.0
@export var max_targets: int = 5
```

---

### SE_Damage 直接伤害效果

**文件路径**: [SE_Damage.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_Damage.gd)

```gdscript
class_name SE_Damage extends SkillEffectBase

@export var base_damage: float = 10.0
@export var use_attack_bonus: bool = true      # 是否使用攻击力加成
@export var use_armor_reduction: bool = true   # 是否受护甲减免
@export var damage_multiplier: float = 1.0     # 伤害倍率
```

---

### SE_Heal 治疗效果

**文件路径**: [SE_Heal.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_Heal.gd)

```gdscript
class_name SE_Heal extends SkillEffectBase

@export var base_heal: float = 20.0
@export var heal_multiplier: float = 1.0

enum HealTarget { SKILL_TARGET, SELF, ALL_ALLIES }

@export var heal_target: HealTarget = HealTarget.SELF
@export var max_targets: int = 5
```

---

## 效果组合模式

### 效果执行顺序

在 `SkillBase._execute_effects()` 中，效果按优先级排序执行：

```gdscript
func _execute_effects(context: GameplayFlowContext) -> void:
    var sorted_effects = effects.duplicate()
    sorted_effects.sort_custom(func(a, b): return a.priority < b.priority)
    
    for effect in sorted_effects:
        if effect:
            effect.apply(context, self)
```

### 组合示例

一个完整的技能可以组合多个效果：

```
效果优先级排序:
├── SE_Projectile (priority=0)    # 发射子弹
├── SE_AreaEffect (priority=10)   # 创建区域效果
├── SE_BuffApply (priority=20)    # 对目标应用 Buff
├── SE_Damage (priority=30)       # 造成直接伤害
└── SE_Heal (priority=40)         # 治疗自身
```

---

## GameplayFlow 集成

技能系统与 GameplayFlow 系统深度集成：

- `SkillBase.on_use_flow_id`: 技能使用时可触发关联的 GameplayFlow
- `SE_AreaEffect.on_enter_effects`: 使用 `FlowEffectBase` 定义区域效果
- `GameplayFlowContext`: 统一的执行上下文对象

### GameplayFlowContext

**文件路径**: [GameplayFlowContext.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowContext.gd)

```gdscript
class_name GameplayFlowContext extends RefCounted

var source: BattleActor = null       # 触发源
var target: BattleActor = null       # 目标
var event_data: Dictionary = {}      # 事件数据

# === 静态工厂方法 ===
static func create_simple(source_actor: BattleActor) -> GameplayFlowContext
static func create_attack(source_actor, target_actor, damage: float) -> GameplayFlowContext
static func create_at_position(pos: Vector2, source_actor) -> GameplayFlowContext

# === 辅助方法 ===
func get_damage() -> float
func get_position() -> Vector2
func get_skill_id() -> String
```

---

## 关键代码路径汇总表

| 类/文件 | 路径 |
|--------|------|
| SkillConfig | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillConfig.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillConfig.gd) |
| SkillBase | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillBase.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillBase.gd) |
| SkillCooldown | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillCooldown.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillCooldown.gd) |
| SkillManager | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillManager.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillManager.gd) |
| SkillRegistry | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillRegistry.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillRegistry.gd) |
| SkillTrigger | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillTrigger.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillTrigger.gd) |
| SkillEffectBase | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SkillEffectBase.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SkillEffectBase.gd) |
| SE_Projectile | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_Projectile.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_Projectile.gd) |
| SE_AreaEffect | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_AreaEffect.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_AreaEffect.gd) |
| SE_BuffApply | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_BuffApply.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_BuffApply.gd) |
| SE_Damage | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_Damage.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_Damage.gd) |
| SE_Heal | [Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_Heal.gd](../Scripts/GameBase/BattleSystemBase/SkillSystem/SkillEffect/SE_Heal.gd) |
| GameplayFlowContext | [Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowContext.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowContext.gd) |
| FlowRegistry | [Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowRegistry.gd](../Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowRegistry.gd) |
| BattleActor | [Scripts/GameBase/BattleSystemBase/BattleActor/BattleActor.gd](../Scripts/GameBase/BattleSystemBase/BattleActor/BattleActor.gd) |

---

## 相关文档

- [Architecture.md](Architecture.md) - 整体架构概览
- [WeaponSystem.md](WeaponSystem.md) - 武器系统详细说明
- [BulletSystem.md](BulletSystem.md) - 子弹系统详细说明