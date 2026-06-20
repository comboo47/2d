# Flow 系统关联文件索引

> 后续 flow 迭代的**只读速查表**。改 flow 相关功能时，直接读下表对应的具体文件，不必重新全局探索。
> 权威机制说明见 [FlowSystem.md](FlowSystem.md)（第十三期终态）。
> ⚠️ `GameplayFlow.md` / `GameplayFlowDesign.md` 已过时（旧 `GameplayFlowBase` 模型），勿照写。

## 工作约定：已实现功能默认不重构

燃烧 DoT、弓/瓶/弩/手枪发射、敌人出生/死亡延迟门控、弹射特质——这些已经跑通的 flow，以及它们依赖的解释器 / 动作库 / 叶子，**默认不动**。

新增能力时**优先用扩展方式**，而不是改既有结构：
- 加一个 `FlowLeaf` 子类（带计算的逻辑）
- 加一个 `FlowActions` 静态方法（纯调用型动作）
- 加一种节点类型 / 事件类型

只有当迭代本身明确要求改既有机制（如图模型重构）时才动核心引擎与既有 flow。

---

## 核心引擎（改 flow 机制时读）

| 文件 | 职责 |
|------|------|
| [FlowInterpreter.gd](../../src/gameplay/flows/graph/FlowInterpreter.gd) | per-instance 解释器，推进核心（`_advance_cursor`/`_enter_duration`/`deliver_event`/`cancel`/`run_oneshot`）。**改推进/分支逻辑在这** |
| [FlowGraph.gd](../../src/gameplay/flows/graph/FlowGraph.gd) | 根容器 `durations[]` + 静态拼装助手（single/instant/seconds/forever/action/leaf_action/trigger） |
| [GameplayFlowContext.gd](../../src/gameplay/flows/GameplayFlowContext.gd) | 执行上下文（source/target/skill/buff/event_data/stack），事实黑板 |
| [GameplayFlowRegistry.gd](../../src/gameplay/flows/GameplayFlowRegistry.gd) | flow 注册表，扫 `resources/gameplay/flows/`，string-id 路径用 |

## 节点类型（加/改节点类时读）

| 文件 | 职责 |
|------|------|
| [FlowNode.gd](../../src/gameplay/flows/graph/FlowNode.gd) | 抽象基类，只有 `node_name`，预留 Control 扩展位 |
| [FlowDuration.gd](../../src/gameplay/flows/graph/FlowDuration.gd) | 生命周期壳（INSTANT/FRAMES/SECONDS/FOREVER）+ `children[]` |
| [FlowTrigger.gd](../../src/gameplay/flows/graph/FlowTrigger.gd) | 事件监听器（ONCE/COUNT/NEVER）+ `filter_script` |
| [FlowAction.gd](../../src/gameplay/flows/graph/FlowAction.gd) | 瞬时动作（`action_name`+`opts` 或 `leaf`） |
| [FlowLeaf.gd](../../src/gameplay/flows/graph/FlowLeaf.gd) | 脚本叶子基类 `run(ctx,host)` |

## 动作库 + 叶子（加新动作/计算时读）

| 文件 | 职责 |
|------|------|
| [FlowActions.gd](../../src/gameplay/flows/FlowActions.gd) | 无状态静态动作库（fire_projectile/deal_damage/modify_attr/apply_buff/spawn_entity/play_vfx/finish）。**加纯调用型动作在这** |
| [leaves/](../../src/gameplay/flows/graph/leaves/) | Shot/BowShot/BottleShot（发射）、Bounce（弹射）、EnemySpawn/EnemyDeath（出生死亡）。**加计算型叶子在这** |

## 五类宿主（改接入方式时读对应那一个）

| 宿主 | 文件 | 接入点 |
|------|------|--------|
| Skill | [SkillBase.gd](../../src/gameplay/skills/SkillBase.gd) | `_run_graph` / `_execute_flows`（run_oneshot） |
| Buff | [AttributeBuff.gd](../../src/gameplay/attributes/AttributeSysscript/AttributeBuff.gd) | `on_applied`/`run_process`/`handle_gameplay_event`/`on_removed` |
| Actor | [BattleActor.gd](../../src/gameplay/actors/BattleActor.gd) | `setup_init_data`/`_physics_process`/`_start_death_flow`（spawn/death interp，death 靠 `is_finished()` 门控销毁） |
| Trait | [TraitContainer.gd](../../src/gameplay/traits/TraitContainer.gd) | `add_trait`/`tick`/`dispatch`/`remove_trait`/`stop_all` |
| Level | [LevelRunner.gd](../../src/gameplay/levels/LevelRunner.gd) | `_emit_level_event`（run_oneshot） |
| (旧 string-id) | [BattleManager.gd](../../src/gameplay/battle/BattleManager.gd) · [EnemyFactory.gd](../../src/gameplay/enemies/EnemyFactory.gd) | string-id run_oneshot |

## 数据资源（加新 flow 内容时仿写）

- [example_burn_tick_flow.tres](../../resources/gameplay/flows/example_burn_tick_flow.tres) — FOREVER+Trigger(BUFF_TICK,NEVER)→deal_damage（燃烧 DoT 范本）
- [WeaponTemplate_TickFlow.tres](../../resources/gameplay/flows/WeaponTemplate_TickFlow.tres) — 武器 tick 范本
- 内嵌 flow 的 .tres：`resources/gameplay/skills/`（弓/瓶/弩/手枪/firebolt）、`resources/gameplay/traits/trait_bounce.tres`、`resources/gameplay/actors/data/actor_init_sample.tres`（spawn_flow + death_flow）

## 测试（改动后必跑 / 仿写新用例）

| 文件 | 覆盖 |
|------|------|
| [FlowInterpreterTest.gd](../../tests/FlowInterpreterTest.gd) | 解释器核心（全脚本拼装，不加载 .tres） |
| [ActorFlowHostTest.gd](../../tests/ActorFlowHostTest.gd) | Actor spawn/death flow 宿主 |
| [EffectSystemTest.gd](../../tests/EffectSystemTest.gd) | Effect 体系 + buff_flow 生命周期 |
| [GameplayCoreTest.gd](../../tests/GameplayCoreTest.gd) | 闭环集成（skill graph_refs 驱动） |
| [TraitSystemTest.gd](../../tests/TraitSystemTest.gd) | TraitContainer 特质 flow |

```bash
godot --headless --path . -s res://tests/FlowInterpreterTest.gd
godot --headless --path . -s res://tests/GameplayCoreTest.gd
godot --headless --path . -s res://tests/GameplayExampleLevelSmokeTest.gd
godot --headless --editor --path . --quit   # parse check
```
