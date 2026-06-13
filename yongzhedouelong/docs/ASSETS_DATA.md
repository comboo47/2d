# 游戏资产数据结构文档

本文档定义了 Battle Editor 管理的所有游戏资产数据结构。当更新资产结构时，请运行 `/battle-editor-sync` Skill 同步编辑器代码。

---

## 数据分离原则

每种资产类型分为两部分：
1. **JSON 数值配置** - 条目多、数值型、由 Excel 导出，左侧面板编辑
2. **Resource 属性** - 资源引用型（Icon、VfxPrefab、Flow 等），右侧 Inspector 自动编辑

---

## 1. Skill 资产

### 1.1 JSON 数值配置

**文件路径**: `data/tables/Json/Skill/SkillConfig.json`

**ID 格式**: `10{index}{enemy_id}` 例如 `1011001`

```json
{
    "1011001": {
        "damage": 10.0,
        "level": 1,
        "cooldown": 3.0,
        "range": 100.0,
        "description": "基础攻击技能"
    }
}
```

**字段定义**:

| 字段 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `damage` | float | 基础伤害值 | 10.0 |
| `level` | int | 技能等级 | 1 |
| `cooldown` | float | 冷却时间（秒） | 3.0 |
| `range` | float | 技能范围 | 100.0 |
| `description` | string | 描述文本 | "" |

### 1.2 Resource 属性

**文件路径**: `resources/gameplay/skills/{skill_id}_Skill.tres`

**脚本**: `src/gameplay/skills/SkillBase.gd`

**@export 属性** (Inspector 自动编辑):

| 属性 | 类型 | 说明 |
|------|------|------|
| `skill_id` | String | 唯一标识 |
| `skill_name` | String | 技能名称 |
| `skill_description` | String (multiline) | 技能描述 |
| `skill_type` | SkillConfig.SkillType | 技能类型枚举 |
| `target_type` | SkillConfig.TargetType | 目标类型枚举 |
| `target_range` | float | 目标范围 |
| `cost_type` | SkillConfig.CostType | 消耗类型枚举 |
| `cost_value` | float | 消耗值 |
| `cooldown_time` | float | 冷却时间 |
| `effects` | Array[SkillEffectBase] | 技能效果列表 |
| `triggers` | Array[SkillTrigger] | 触发条件列表 |
| `on_use_flow_id` | String | 关联的 Flow ID |
| `icon_path` | String | 技能图标路径 |

---

## 2. Buff 资产

### 2.1 JSON 数值配置

**文件路径**: `data/tables/Json/Buff/BuffConfig.json`

**ID 格式**: `20{index}{enemy_id}` 例如 `2011001`

```json
{
    "2011001": {
        "duration": 5.0,
        "tick_interval": 1.0,
        "damage_per_tick": 2.0,
        "stack_limit": 3,
        "description": "持续伤害 Buff"
    }
}
```

**字段定义**:

| 字段 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `duration` | float | 总持续时间（秒） | 5.0 |
| `tick_interval` | float | Tick 间隔（秒） | 1.0 |
| `damage_per_tick` | float | 每 Tick 伤害（伤害 Buff） | 0.0 |
| `heal_per_tick` | float | 每 Tick 治疗（治疗 Buff） | 0.0 |
| `stack_limit` | int | 最大叠加层数 | 1 |
| `description` | string | 描述文本 | "" |

### 2.2 Resource 属性

**文件路径**: `resources/gameplay/buffs/{buff_id}.tres`

**脚本**: `src/gameplay/attributes/AttributeSysscript/AttributeBuff.gd`

**@export 属性** (Inspector 自动编辑):

| 属性 | 类型 | 说明 |
|------|------|------|
| `buff_id` | String | 唯一标识 |
| `buff_name` | String | Buff 名称 |
| `buffDuration` | float | 持续时间 |
| `buffPeriod` | int | 执行周期 |
| `isLeaveReset` | bool | 离开时是否重置 |
| `BuffEffects` | Array[AttributeBuffEffect] | Buff 效果列表 |
| `duration` | float | 持续时间（秒） |
| `merging` | DurationMerging | 合并策略枚举 |

---

## 3. Enemy 资产

### 3.1 JSON 配置

**文件路径**: `data/tables/Json/Enemy/EnemyConfig.json`

**ID 格式**: 数字 ID 如 `1001`, `1002`

```json
{
    "1001": {
        "display_name": "初级敌人",
        "enemy_name": "FirstEnemy",
        "description": "基础敌人，无护甲，移动速度较快",
        "prefab_path": "res://scenes/actors/enemies/First_Enemy.tscn",
        "behavior_tree": "res://src/gameplay/ai/HSM&BT/BehaviorTree/BTTree/FirstEnemyTree.tres",
        "drop_table_id": "drop_001",
        "spawn_flow_id": "",
        "death_flow_id": "",
        "skills": ["1011001", "1021001"],
        "buffs": ["2011001"],
        "attributes": {
            "max_hp": 12.0,
            "attack": 2.0,
            "armor": 0.0,
            "speed": 50.0,
            "jump_power": 30.0
        }
    }
}
```

**字段定义**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `display_name` | string | 显示名称（UI） |
| `enemy_name` | string | 内部标识名 |
| `description` | string | 描述文本 |
| `prefab_path` | string | 预制体路径 |
| `behavior_tree` | string | BehaviorTree 资源路径 |
| `drop_table_id` | string | 掉落表 ID |
| `spawn_flow_id` | string | 生成时触发的 Flow ID |
| `death_flow_id` | string | 死亡时触发的 Flow ID |
| `skills` | Array[string] | 关联的 Skill ID 列表 |
| `buffs` | Array[string] | 关联的 Buff ID 列表 |
| `attributes` | Dictionary | 属性配置字典 |

**Attributes 子字段**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `max_hp` | float | 最大生命值 |
| `attack` | float | 攻击力 |
| `armor` | float | 护甲值 |
| `speed` | float | 移动速度 |
| `jump_power` | float | 跳跃力 |

---

## 4. 文件结构

```
data/tables/
├── Excel/
│   ├── SkillConfig.xlsx      # Excel 源文件（导出 Skill JSON）
│   ├── BuffConfig.xlsx       # Excel 源文件（导出 Buff JSON）
│   └── EnemyConfig.xlsx      # Excel 源文件（导出 Enemy JSON）
│
└── Json/
    ├── Skill/
    │   └── SkillConfig.json  # Skill 数值配置
    ├── Buff/
    │   └── BuffConfig.json   # Buff 数值配置
    └── Enemy/
        ├── EnemyConfig.json  # Enemy 配置
        └── DropConfig.json   # 掉落配置

resources/gameplay/
├── skills/
│   └── {skill_id}_Skill.tres # Skill Resource 文件
├── buffs/
│   └── {buff_id}.tres        # Buff Resource 文件
└── enemies/
    └── {enemy_name}.tres     # Enemy 配置 Resource（预制体场景在 scenes/actors/enemies/）

src/gameplay/
├── skills/
│   └── SkillBase.gd  # Skill Resource 脚本
└── attributes/
    └── AttributeSysscript/
        └── AttributeBuff.gd  # Buff Resource 脚本
```

---

## 5. ID 编码规则

| 资产类型 | ID 格式 | 示例 |
|----------|---------|------|
| Enemy | `{enemy_id}` | `1001`, `1002` |
| Skill | `10{index}{enemy_id}` | `1011001` (Enemy 1001 的第1个 Skill) |
| Buff | `20{index}{enemy_id}` | `2011001` (Enemy 1001 的第1个 Buff) |

**说明**:
- Skill ID 以 `10` 开头
- Buff ID 以 `20` 开头
- `{index}` 表示在 Enemy 中的序号（从 1 开始）
- `{enemy_id}` 为所属 Enemy 的 ID

---

## 6. 编辑器代码同步点

当资产数据结构变更时，以下编辑器代码需要同步更新：

| 变更类型 | 需要更新的文件 |
|----------|----------------|
| Skill JSON 新增字段 | `BattleEditorPanel.gd` → `_skill_json_config` 默认模板 |
| Buff JSON 新增字段 | `BattleEditorPanel.gd` → `_buff_json_config` 默认模板 |
| Enemy JSON 新增字段 | `BattleEditorPanel.gd` → `_create_new_enemy()` 模板 |
| SkillBase 新增 @export | 自动同步（Inspector 自动扫描） |
| AttributeBuff 新增 @export | 自动同步（Inspector 自动扫描） |

---

## 更新日志

| 日期 | 变更内容 |
|------|----------|
| 2025-04-19 | 初始版本，定义 Skill/Buff/Enemy 数据结构，创建编辑器同步流程 |