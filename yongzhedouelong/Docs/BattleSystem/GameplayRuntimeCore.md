# Gameplay Runtime Core Baseline

本文档记录第一版 Gameplay 运行时核心的使用方式和验收边界。当前目标是把 `Flow -> Effect -> Context` 作为统一协议，让 Level、Actor、Skill、Buff 都通过同一套 Flow/Effect 执行玩法逻辑。

## 运行时协议

- `GameplayFlowBase` 是流程容器，持有 `effects: Array[FlowEffectBase]`，按 `priority` 从小到大执行。
- `GameplayFlowContext` 是执行上下文，传递 `source`、`target`、`skill`、`buff`、`level`、`gameplay_event`、`damage_request`、`stack`、`event_data`。
- `FlowEffectBase` 是新 Effect 基类。新玩法效果优先继承它，旧 `SkillEffectBase` 和 `AttributeBuffEffect` 只作为兼容层保留。
- `GameplayEventBus` 当前作为静态事件总线使用，不依赖 autoload，避免第一版核心和 `project.godot` 的项目级改动耦合。

## Skill -> Flow

策划创建或编辑 `SkillBase` Resource 时，技能本体只保留冷却、消耗、等级和目标选择等施放信息。

- 直接引用 Flow：把 `GameplayFlowBase` Resource 填入 `flow_refs`。
- 通过注册表引用 Flow：填写 `on_use_flow_id`，运行时会从 `/root/FlowRegistry` 查找。
- 兼容旧内容：`effects: Array[SkillEffectBase]` 仍会先执行，但新内容应优先迁移到 `FlowEffectBase`。

调用 `skill.use(context)` 后，系统会写入 `context.skill`、`skill_id`、`skill_level`，消耗资源并启动冷却，然后执行 Flow，最后广播 `GameplayEvent.EventType.SKILL_USED`。

## Buff Event -> Flow

`AttributeBuff` 现在由事件驱动。Buff Resource 上的 `event_flows` 字典把事件类型映射到 Flow 列表，例如：

```gdscript
buff.event_flows = {
	GameplayEvent.EventType.BUFF_TICK: [burn_tick_flow],
	GameplayEvent.EventType.DAMAGE_REQUESTED: [damage_modify_flow],
}
```

常用事件入口：

- `BUFF_APPLIED`：Buff 应用时触发。
- `BUFF_REMOVED`：Buff 移除时触发。
- `BUFF_TICK`：`BuffManager` 根据 `buffPeriod` 触发。
- `BUFF_STACK_CHANGED`：层数变化时触发。
- `DAMAGE_REQUESTED`：伤害结算前触发，可修改 `DamageRequest`。
- `DAMAGE_APPLIED`：伤害扣血后触发，可读取最终伤害和目标血量变化。
- `SKILL_USED`：技能使用后触发。

旧 Buff 字段已做兼容映射：`id -> buff_id`，`name/buff_Name -> buff_name`，`buffDuration -> duration`。新资源建议直接填写 `buff_id`、`buff_name`、`duration`。

## FE_Damage -> DamageRequest

`FE_Damage` 不直接扣血，而是创建 `DamageRequest` 并交给 `DamageResolver.resolve()`。

伤害流程：

1. `FE_Damage` 根据 `base_damage`、攻击属性、护甲属性得到初始 `amount`。
2. `DamageResolver` 广播 `DAMAGE_REQUESTED`，Buff 可在这个阶段修改 `damage_request.amount`、`tags` 或 `event_data`。
3. `DamageRequest.evaluate_amount()` 执行表达式公式。
4. `DamageResolver` 统一扣除目标 HP，并广播 `DAMAGE_APPLIED`。

公式白名单变量：

- `source`、`target`、`skill`、`buff`
- `event_data`
- `damage`，即当前 `DamageRequest`
- `level`，当前为技能等级数值
- `stack`，当前 Buff 层数

公式辅助函数：

```gdscript
source_attr("Atk")
target_attr("Armor")
event_value("key", 0.0)
has_tag("fire")
```

## LevelDefinition -> LevelRunner

`LevelDefinition` 是关卡初始化数据源：

- `initial_actors`：生成初始 Actor，可带初始技能和初始 Buff。
- `initial_buffs`：按 Actor 索引给指定目标施加 Buff。
- `event_flows`：关卡事件到 Flow 列表的映射。

场景中挂 `LevelRunner`，设置 `level_definition`，启动时调用：

```gdscript
$LevelRunner.start_level()
```

执行顺序：

1. 生成 `initial_actors`。
2. 给 Actor 添加初始技能和初始 Buff。
3. 应用 `LevelDefinition.initial_buffs`。
4. 广播 `LEVEL_START` 并执行对应 Flow。

## 验收范围

本轮 Gameplay 核心验收范围包括：

- `Scripts/GameBase/BattleSystemBase/GameplayFlow/`
- `Scripts/GameBase/BattleSystemBase/GameplayCore/`
- `Scripts/GameBase/BattleSystemBase/DamageSystem/`
- `Scripts/GameBase/BattleSystemBase/LevelSystem/`
- `Scripts/GameBase/BattleSystemBase/AttributeSystem/`
- `Scripts/GameBase/BattleSystemBase/SkillSystem/SkillBase.gd`
- `Scripts/GameBase/BattleSystemBase/BattleSystem/BattleManager.gd`
- `Scripts/GameBase/GameDataBase/DataManager.gd`
- `Scripts/GameBase/GameDataBase/DataAutoScanner.gd`
- `Tests/GameplayCoreTest.gd`
- 新脚本对应的 `.uid` 文件

当前工作树里已有 UI、菜单、MCP、`project.godot` 等改动不属于本轮 Gameplay 验收范围，提交时应单独隔离。

## 测试与已知噪声

核心回归测试：

```powershell
godot --headless --path . -s res://Tests/GameplayCoreTest.gd
```

覆盖：

- Flow 执行顺序
- DamageRequest 结算与事件广播
- Buff tick 触发 Flow
- Skill 触发 Flow
- LevelRunner 初始化 Actor、Buff 和关卡开始 Flow

编译检查：

```powershell
godot --headless --editor --path . --quit
```

已知：Godot headless 退出阶段可能仍打印项目级 RID/resource leak 或现有资源 UID 重复日志。只要 `Tests/GameplayCoreTest.gd` 5/5 PASS 且进程退出码为 0，本轮先把它记录为环境/测试清理噪声，不和核心行为测试混在一起。
