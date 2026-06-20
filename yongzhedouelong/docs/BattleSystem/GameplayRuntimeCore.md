# Gameplay Runtime Core Baseline

> **第十三期更新（2026/06/15）**：Flow 已从「脚本类 `GameplayFlowBase`」重构为 **Duration/Trigger/Action 节点树（`FlowGraph`）+ per-instance `FlowInterpreter`**。`GameplayFlowBase` 与 `FlowRuntime` autoload 已删除。**Flow 的权威文档见 [`FlowSystem.md`](FlowSystem.md)**（终态架构 + 设计取舍 + 待办）。下文「运行时协议」中关于 `GameplayFlowBase`/`_execute_flow`/`is_persistent`/`FlowRuntime` 的描述为旧态；`FlowActions` 动作库静态实现不变，被解释器与 `FlowLeaf` 叶子复用。
>
> 现态要点：`FlowGraph.durations`（主线串行）→ `FlowDuration`（生命周期壳 INSTANT/FRAMES/SECONDS/FOREVER，children 并行）→ `FlowTrigger`（事件监听，EndMode ONCE/COUNT/NEVER，可 finish_parent）/ `FlowAction`（瞬时，action_name+opts 调 FlowActions，或 `FlowLeaf` 脚本叶子）。`FlowInterpreter`（RefCounted，per-host，不进树不订阅总线）：`start/advance(delta)/deliver_event(event)/cancel()`；`run_oneshot(graph,ctx,host)` 供一次性宿主。六类宿主（skill `graph_refs`、buff `buff_flow`、actor `spawn/death_flow`、trait `trait_flow`、level `event_flows`、weapon 已转 skill）均 per-instance 持解释器。

本文档记录 Gameplay 运行时核心的使用方式和验收边界。`Flow / Effect / Buff` 经第八期重构为清晰三层：**Flow = gameplay 编排**，**Effect = 挂在 buff 上的逻辑承载**，**Buff = 生命周期数据 + buff_flow + effects 双轨**。Level、Actor、Skill、Buff 都通过这套统一协议执行玩法逻辑。

## 运行时协议

- `GameplayFlowBase` 是流程基类。一次性 flow 重写 `_execute_flow(ctx)`；常驻 flow（`is_persistent=true`）重写 `on_start/on_tick/on_event/on_stop`，由 `FlowRuntime` 承载。**已无 `effects` 数据拼装数组**（第八期删除旧 `FlowEffectBase`/`FE_*`）。
- **Flow 动作库**：逻辑写在脚本里，用 `GameplayFlowBase` 上的薄方法 `fire_projectile`/`deal_damage`/`apply_buff`/`modify_attr`/`spawn_entity`/`play_vfx`（委托无状态静态类 `FlowActions`，`src/gameplay/flows/FlowActions.gd`）。
- `GameplayFlowContext` 是执行上下文，传递 `source`、`target`、`skill`、`buff`、`level`、`gameplay_event`、`damage_request`、`stack`、`event_data`。
- **Effect**（`src/gameplay/effects/`）：`EffectBase` 提供 `apply(ctx, buff)`/`remove(ctx, buff)`。`ModifierEffect` 改面板属性（走 Attribute 修改源栈，按 buff runtime id 可逆）；`StateEffect` 管高维状态（无敌/隐身/视野，apply 设、remove 清）。Effect 只挂 buff。
- `GameplayEventBus` 作为静态事件总线，不依赖 autoload，避免核心和 `project.godot` 的项目级改动耦合。

## Skill -> Flow

策划创建或编辑 `SkillBase` Resource 时，技能本体只保留冷却、消耗、等级和目标选择等施放信息。

- 直接引用 Flow：把 `GameplayFlowBase` 脚本类实例（.tres 壳）填入 `flow_refs`。
- 通过注册表引用 Flow：填写 `on_use_flow_id`，运行时会从 `/root/FlowRegistry` 查找。
- skill 不再有 `effects` 字段（第八期删除 `SkillEffectBase`/`SE_*`）——技能逻辑一律走 flow 脚本 + 动作库。

调用 `skill.use(context)` 后，系统会写入 `context.skill`、`skill_id`、`skill_level`，消耗资源并启动冷却，然后执行 Flow，最后广播 `GameplayEvent.EventType.SKILL_USED`。

## Buff = buff_flow + effects（双轨）

`AttributeBuff` 自带生命周期数据（`duration`/`buffPeriod`/`stack`/`merging`），并有两条挂逻辑的轨道：

- **buff_flow**（轨道一）：单个常驻 flow，buff apply 时 `deep_duplicate` 拉起并 `on_start`，每帧 `on_tick`，每 `buffPeriod` 收到 `BUFF_TICK` 经 `on_event` 响应，remove 时 `on_stop`。燃烧/标记跳伤这类周期逻辑写在 buff_flow 里（见 `Flow_BurnTick`）。
- **effects**（轨道二）：`Array[EffectBase]`，apply 时 `apply()` 生效、remove 时逆序 `remove()` 还原。属性加成用 `ModifierEffect`（可逆），状态用 `StateEffect`。

```gdscript
buff.buff_flow = preload("res://.../Flow_BurnTick.gd").new()   # 周期伤害逻辑
buff.effects = [modifier_effect]                                # +攻击力等可逆加成
```

驱动入口：`BuffManager.apply_buff` → `runtime_buff.on_applied()`（拉 buff_flow + apply effects）；`remove_buff` → `on_removed()`（revert effects + stop buff_flow）。buff 把与自身 source/target 相关的总线事件转发给 `buff_flow.on_event`。

> 注：旧的 `event_flows` 字典 / `BuffEffects` / `attribute_modifier` 已删除。`LevelDefinition.event_flows`（关卡级 `{事件→flows}`）与此无关，仍保留。

旧 Buff 字段仍做兼容映射：`id -> buff_id`，`name/buff_Name -> buff_name`，`buffDuration -> duration`。

## 伤害动作 -> DamageRequest

`FE_Damage` 不直接扣血，而是创建 `DamageRequest` 并交给 `DamageResolver.resolve()`。

伤害流程：

1. `FlowActions.deal_damage` 根据 `base`、攻击属性、护甲属性得到初始 `amount`（攻防加成折进 amount）。
2. `DamageResolver` 广播 `DAMAGE_REQUESTED`，Buff 可在这个阶段修改 `damage_request.amount`、`tags` 或 `event_data`。
3. `DamageRequest.evaluate_amount()` 执行表达式公式。
4. `DamageResolver` 统一扣除目标 HP，并广播 `DAMAGE_APPLIED`。
5. **生命周期收口**（第七期）：扣血后 `DamageResolver` 全权判定并广播 `ACTOR_HIT`（final_amount>0，带 source）/ `ACTOR_DIED`（HP≤0，event_data 带 killer）/ `ACTOR_KILL`（致命一击且 source 非空）；同时直接调 `target.trigger_hit_flow/kill()` 与 `source.trigger_kill_flow()` 驱动 actor 配置的生命周期 flow。

### 伤害管线终态（唯一收口）

**所有伤害都必须走 `DamageResolver.resolve()`，不得直接 `hp.sub()`。** 这是判死与 `ACTOR_*` 事件的唯一来源：

- 入口：子弹/武器走 `BattleManager.resolve_bullet_hit()`；flow/skill/buff 的伤害走动作库 `FlowActions.deal_damage`（或 `modify_attr` 对 Hp 做 SUB 时收口，其余属性变更直接操作）。全部内部构建 `DamageRequest` 交给 `resolve()`。
- 判死唯一化：`resolve()` 用 `was_dead` 守卫 + `BattleActor.is_dead`（基类防重入），HP≤0 只触发一次 `ACTOR_DIED` 与 `kill()`。`BattleManager.resolve_bullet_hit` 用 resolve **前** 的 `was_dead` 快照判武器 ON_KILL 槽，避免被 resolver 内部置位的 `is_dead` 破坏。
- 死亡驱动：`BattleActor.kill(killer)` 是通用死亡入口（防重入 + 跑 death_flow + 调虚方法 `_on_death`）。敌人 `base_enemy._on_death` 做掉落+消失动画+queue_free；玩家死亡未纳入（见 GameplayLifecycle.md 待补清单）。
- 旧的 `BattleActor` Godot signal（`actor_hit/died/kill/spawned`）已删除——一律走 `GameplayEventBus`。
- 自身消耗（如技能血祭 `SkillBase._subtract_attribute`）**不**收口为伤害：无攻击者，不应触发受击/死亡事件。

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

- `src/gameplay/flows/`
- `src/gameplay/core/`
- `src/gameplay/damage/`
- `src/gameplay/levels/`
- `src/gameplay/attributes/`
- `src/gameplay/skills/SkillBase.gd`
- `src/gameplay/battle/BattleManager.gd`
- `src/gameplay/data/DataManager.gd`
- `src/gameplay/data/DataAutoScanner.gd`
- `Tests/GameplayCoreTest.gd`
- 新脚本对应的 `.uid` 文件

当前工作树里已有 UI、菜单、MCP、`project.godot` 等改动不属于本轮 Gameplay 验收范围，提交时应单独隔离。

## 测试与已知噪声

核心回归测试：

```powershell
godot --headless --path . -s res://tests/GameplayCoreTest.gd
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
