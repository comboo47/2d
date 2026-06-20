# Flow 系统（节点树 + 解释器）

> 本文是 Flow 系统的**权威文档**，沉淀第十三期（2026/06/15）落地的终态架构与一路讨论得出的设计取舍。
> 旧的 `GameplayFlow.md` / `GameplayFlowDesign.md` 描述的是已删除的 `GameplayFlowBase` 脚本类 + `effects[]` 数据拼装模型，仅留作历史脉络，**不要按它们写代码**。
> 配套：运行时核心 `GameplayRuntimeCore.md`、生命周期 `GameplayLifecycle.md`、伤害收口见 `CLAUDE.md`「Damage never bypasses the resolver」。

---

## 1. 一句话定位

**Flow = 一棵 Duration / Trigger / Action 数据节点树，由一个 per-instance 的解释器 `FlowInterpreter` 驱动。**

Level、Skill、Buff、Actor、Trait 五类宿主都用同一套节点树 + 同一个解释器表达"流程逻辑"，武器开火已在第十二期改走 skill（不再直接持 flow）。节点树是**数据**（`.tres` 可编辑、可被未来编辑器拼装），需要计算的叶子是**脚本**（`FlowLeaf`）。

---

## 2. 为什么是这个形态（设计取舍）

这一节是讨论的沉淀——记录"为什么这么定"，比"是什么"更难从代码反推。

### 2.1 Flow 要表达的是"流程编排"，不是"重逻辑"
Flow 的职责是把已有的动作（发射、造成伤害、上 buff、播特效）按**时序与条件**串起来，而不是承载复杂计算。典型流程：
- `发射子弹（带上下文）→ 直接结束`（子弹自己的命中逻辑交给子弹的特质容器）
- `发射 → 等命中 → 给目标上 buff`
- `每隔 period 掉一次血（燃烧）`
- `死亡逻辑 → 等动画/延时跑完 → 通知可销毁`

### 2.2 主线串行、支线并行 → Duration 作为生命周期壳
- **主线（串行）**：`FlowGraph.durations` 是一串 `FlowDuration`，逐个推进，全部跑完 = flow 结束。
- **支线（并行）**：一个 `FlowDuration` 内部 `children` 并行存活（多个 Trigger，或 Trigger + Action 同时）。
- `FlowDuration` 本身只是**生命周期壳**，用 `LifetimeMode` 表达它活多久：`INSTANT`(0帧，进入即跑完直属 Action) / `FRAMES`(定长N帧) / `SECONDS`(定长N秒) / `FOREVER`(永久，靠内部 Trigger 的 `finish_parent` 或宿主 `cancel` 才结束)。

### 2.3 "等待"用 Trigger，不用协程
GDScript 的 `await` **杀不掉**——宿主中途死亡时挂起的协程会泄漏。所以"等命中"不写成 `await hit_signal`，而是：
- `FlowTrigger` 是一个**持续监听器**，声明它关心的 `event_type`，宿主把事件喂进来（`deliver_event`）触发它。
- 结束语义 `EndMode`：`ONCE`(触发一次即结束) / `COUNT`(触发N次后结束) / `NEVER`(永不结束——穿透弹"每次命中都上buff"就是这个，**不是 while、不是协程**)。
- 触发后两个**正交**开关：① 执行哪些 `actions` ② 是否 `finish_parent`（推进主线）。
- 宿主死亡 → 解释器 `cancel()` → 同步清掉所有 Trigger 监听态。**确定性清理，零泄漏窗口**——这是放弃协程换来的核心收益。

### 2.4 结构是数据、计算是脚本叶子（行为树通行做法）
- 流程的**结构**（哪些 Duration、什么 Trigger、调什么 Action）是数据节点，未来可被编辑器可视化拼装。
- 需要**计算**的地方（弓的"速度 = lerp(base, max, 蓄力比)"、瓶的"蓄满散射三发"、弹射的"反射方向 + 递减次数"）放进 `FlowLeaf` 脚本叶子，由 `FlowAction.leaf` 引用。
- 这样既保住了数据可编辑性，又不强行把计算塞进数据格子。

### 2.5 解释器 per-instance、不进场景树、不订阅总线
- 每个宿主 `new` 一个 `FlowInterpreter` 自己持有，生命周期**严绑宿主**。不是 autoload、没有全局注册表 → 宿主死直接 `cancel()`，零全局状态泄漏。（取代了旧的 `FlowRuntime` autoload——那是个全局 `_instances` 表 + 订阅总线转发，宿主忘记 `stop_flow` 就泄漏。）
- 解释器**不订阅** `GameplayEventBus`，只暴露 `deliver_event(event)`。事件来源（全局总线 / 特质容器私有事件 / buff 周期 tick）由**各宿主自己桥接**进来——事件来源不变，只把末端的"调用 flow"换成"喂给解释器"。

### 2.6 "发射 → 命中 → 上 buff" = 交棒（A 方案），不是跨宿主长活
skill 发子弹后**当帧结束**（INSTANT Duration），不跨子弹长活。命中监听交给**子弹自己**的 `TraitContainer` 里的 graph：`Duration(FOREVER) + Trigger(BULLET_HIT, ONCE/NEVER) → apply_buff`。
- 单发命中上 buff = `ONCE`；穿透弹每次命中都上 = `NEVER`。
- 否决了 B 方案（skill 跨子弹长活 + 跨宿主监听命中），因为那会重新引入协程泄漏风险和跨宿主生命周期耦合。

---

## 3. 节点数据结构（`src/gameplay/flows/graph/`）

```
FlowGraph (根容器)
  flow_id, flow_name
  durations: Array[FlowDuration]          # 主线，串行
  deep_duplicate()                        # 宿主取独立实例（禁止写回共享 .tres）
  静态拼装助手: single/instant/seconds/forever/action/leaf_action/trigger

FlowNode (抽象基类 extends Resource)        # 类型根 + Control 扩展位（branch/loop 留待后续）
  node_name

FlowDuration extends FlowNode               # 生命周期壳
  enum LifetimeMode { INSTANT, FRAMES, SECONDS, FOREVER }
  lifetime_mode, lifetime_value: float
  children: Array[FlowNode]                # 并行：Trigger / Action

FlowTrigger extends FlowNode                # 持续事件监听器（替代 await）
  enum EndMode { ONCE, COUNT, NEVER }
  event_type: int                          # GameplayEvent.EventType 的 int 值
  end_mode, count: int
  actions: Array[FlowNode]                 # 触发时执行
  finish_parent: bool                      # 触发后是否推进主线
  filter_script: GDScript                  # 可选过滤（run(ctx,host)->bool）

FlowAction extends FlowNode                 # 瞬时动作
  action_name: String                      # 调 FlowActions.<name>(ctx, opts)
  opts: Dictionary
  buff_res: AttributeBuff                  # apply_buff 用（资源引用比 opts 塞 Resource 直观）
  leaf: FlowLeaf                           # 非空时优先：脚本叶子承载计算

FlowLeaf extends Resource                   # 脚本叶子基类
  run(ctx, host=null)                      # 子类重写，内部调 FlowActions.* 静态库
```

现有叶子（`graph/leaves/`）：
- `FlowLeaf_Shot`（基类，单发 base_speed）/ `FlowLeaf_BowShot`（速度随蓄力 lerp）/ `FlowLeaf_BottleShot`（蓄满散射三发）
- `FlowLeaf_Bounce`（弹射：veto 销毁 + 递减 bounce_count + 反射方向）
- `FlowLeaf_EnemySpawn` / `FlowLeaf_EnemyDeath`（样例出生/死亡表现）

---

## 4. 解释器 `FlowInterpreter`（`extends RefCounted`，per-instance）

```gdscript
start(graph, ctx, host=null)    # _cursor=-1 → _advance_cursor 进入首个 Duration
advance(delta)                  # 宿主喂帧：FRAMES累加帧/SECONDS累加秒；到期或被 finish_requested → 推进游标
deliver_event(event)            # 宿主桥接事件：分发给当前 Duration 未结束的匹配 Trigger，
                                #   执行 actions、按 ONCE/COUNT/NEVER 更新结束态、finish_parent→推进
cancel()                        # 确定性同步清理（宿主死/移除）：_finished=true + 清 Trigger 态，无协程
is_finished()                   # 游标越界 = 结束
active_trigger_count()          # 当前未结束 Trigger 数

# 静态便捷：把 graph 一次性跑到 finished（含 256 次迭代守卫，防误配 FOREVER/SECONDS 死循环）
static run_oneshot(graph, ctx, host=null)
```

**进入一个 Duration**（`_enter_duration`）：建 Trigger 监听态 + 立即跑直属 Action；若是 INSTANT 且无未结束 Trigger → 当帧推进游标。
**动作分派**（`_run_action`）：`leaf` 非空优先 `leaf.run(ctx, host)`；否则 `match action_name` 调 `FlowActions.fire_projectile/deal_damage/modify_attr/apply_buff/spawn_entity/play_vfx/finish`。

---

## 5. 五类宿主接入方式

| 宿主 | 持有 | 启动 | 推进 / 事件 | 结束 |
|------|------|------|-------------|------|
| **Skill** | `graph_refs: Array[FlowGraph]` | `_run_graph` 用 `run_oneshot`（技能 flow 多为 INSTANT 动作链） | — | 一次性跑完 |
| **Buff** | `buff_flow: FlowGraph` + `_buff_interp` | `on_applied`→`start` | `run_process`→`advance`(每帧)；`handle_gameplay_event`→`deliver_event`（周期 `BUFF_TICK` 由 BuffManager 喂） | `on_removed`→`cancel` |
| **Actor** | `ActorInitData.spawn_flow/death_flow` + `_spawn_interp/_death_interp` | `setup_init_data`→spawn 启动；`kill()`→death 启动 | `_physics_process` 自喂帧 `advance` | spawn 随 actor 死；**death 的 SECONDS Duration 跑完 → `is_finished()` → `_on_death_flow_finished` → 最终销毁** |
| **Trait** | `TraitDefinition.trait_flow` + `_active[].interp` | `add_trait`→`start` | `dispatch`→`deliver_event`；`tick`→`advance` | `stop_all`/`remove_trait`→`cancel` |
| **Level** | `event_flows: {EventType → FlowGraph[]}` | `_emit_level_event`→`run_oneshot` | — | 一次性跑完 |

**旧 string-id 路径**（`BattleActor.trigger_spawn/death/hit/kill_flow`、`BattleManager.ExecuteFlow`、`EnemyFactory` spawn flow）：经 `FlowRegistry.get_flow(id)→FlowGraph` 后 `run_oneshot`。`FlowRegistry`（`GameplayFlowRegistry.gd`）现在只扫 `resources/gameplay/flows/*.tres`，`get_flow` 返回 `deep_duplicate()` 副本（不再扫脚本类）。

---

## 6. 复用与边界

- **`FlowActions`（`src/gameplay/flows/FlowActions.gd`）不变**：无状态静态动作库，解释器和叶子都复用。新增一种动作 = 在此加一个静态方法 + 在 `_run_action` 的 match 里加一行（或写叶子）。
- **伤害收口铁律不破**：`deal_damage` 与 `modify_attr`(Hp-SUB) 必须走 `DamageResolver.resolve`，不绕过。见 `actor-lifecycle-damage-chokepoint`。
- **`GameplayFlowContext` 不变**：`source/target/skill/buff/level/gameplay_event/damage_request/stack/event_data`。
- **`deep_duplicate` 只拷 `@export`**：叶子/flow 的运行时状态若需要在副本里保留，必须是 `@export` 字段（测试桩多次踩此坑——非 export 的计数器在 duplicate 后丢失）。
- **节点树只改 script 行、不动 .tscn、不手改 .uid**。

---

## 7. 数据样例

**燃烧 DoT**（`resources/gameplay/flows/example_burn_tick_flow.tres`，挂在 buff 的 `buff_flow`）：
```
FlowGraph
└─ FlowDuration(FOREVER)
   └─ FlowTrigger(event_type=BUFF_TICK, end_mode=NEVER)
      └─ FlowAction("deal_damage", {base:1, formula:"source_attr(\"Atk\")+stack", tags:[fire,dot,burn]})
```

**弓蓄力发射**（`resources/gameplay/skills/skill_bow_fire.tres` 的 `graph_refs[0]`）：
```
FlowGraph
└─ FlowDuration(INSTANT)
   └─ FlowAction(leaf=FlowLeaf_BowShot{bullet_scene, base_speed=250, max_charge_speed=650})
```

**敌人死亡延迟**（`resources/gameplay/actors/data/actor_init_sample.tres` 的 `death_flow`）：
```
FlowGraph
├─ FlowDuration(INSTANT)  → FlowAction(leaf=FlowLeaf_EnemyDeath)   # 死亡表现/特效
└─ FlowDuration(SECONDS, 1.0)                                       # 延时门控：跑完才允许销毁
```

**弹射特质**（`resources/gameplay/traits/trait_bounce.tres` 的 `trait_flow`）：
```
FlowGraph
└─ FlowDuration(FOREVER)
   └─ FlowTrigger(event_type=BULLET_HIT, end_mode=NEVER)
      └─ FlowAction(leaf=FlowLeaf_Bounce)   # veto 销毁 + 递减 bounce_count + 反射
```

---

## 8. 演进史（简）

- **第八期**：删三套旧 effect 基类（`FlowEffectBase`/`SkillEffectBase`/`AttributeBuffEffect` + 全部 `FE_*`/`SE_*`/`E_*`），flow 改"脚本编排 + `FlowActions` 动作库"，buff 改 `buff_flow + effects` 双轨，Attribute 加可逆修改源栈。
- **第十一期**：actor 成为 spawn/death flow 宿主（当时经 FlowRuntime + 协程 await 延迟）。
- **第十二期**：武器开火改为"激活 skill"，武器不再直接持 fire flow。
- **第十三期（本次终态）**：flow 从脚本类 `GameplayFlowBase` 整体换成 **Duration/Trigger/Action 节点树 + per-instance `FlowInterpreter`**。**删除** `GameplayFlowBase.gd`、`FlowRuntime.gd`(autoload)、`Flow_*` 脚本类、`TraitFlow_Bounce`。死亡延迟从协程 await 改为 SECONDS Duration + `is_finished()` 门控（消灭最后一个 await 泄漏源）。6 类宿主全迁，56 个单测 + MCP 实跑（燃烧/武器/死亡门控/弹射）验证通过。

---

## 9. 已知未做 / 留待后续优化（下一会话的起点）

> 本节是"flow 组织方式优化"会话的清单。这些是**有意推迟**的，不是遗漏。

1. **Control 节点（判断/循环/分支）未做**：`FlowNode` 预留了类型根扩展位，但 branch / switch / random / loop 控制节点本期没做。当前条件分支只能靠 `FlowTrigger.filter_script` 或写进叶子。需要时按节点树扩展。
2. **两类入口尚未统一**：一次性宿主（skill/level/actor string-id）用 `run_oneshot`，常驻宿主（buff/trait/actor spawn-death）用 `start`+宿主喂帧。两者底层都是同一个解释器，但调用约定不同。是否合并、怎么合并待定。
3. **宿主子类约束未做**：旧设计设想过 `SkillFlow`/`BuffFlow`/`ActorFlow`/`LevelFlow` 子类来约束各自上下文字段——节点树模型下没有做（所有宿主共用 `FlowGraph` + `GameplayFlowContext`）。是否需要"按宿主约束的 graph 模板/校验"待定。
4. **编辑器拼装**：节点树是数据，但 GPManager 目前只展示 buff 的 `buff_flow` / skill 的 `graph_refs` 引用，**不能可视化拼/改节点树**。可视化 flow 编辑器是节点树模型最大的潜在收益，未做。
5. **叶子 vs 数据 Action 的边界**：什么逻辑该进 `FlowLeaf` 脚本、什么该是 `FlowActions` 数据动作，目前靠经验（有计算→叶子，纯调用→数据）。可考虑沉淀成约定或让叶子也参数化。
6. **`FlowRegistry` 与内联 graph 的关系**：skill/buff/trait 多用内联 graph（.tres 里直接拼），`FlowRegistry` 只服务 string-id 路径（actor 旧路径 + 关卡）。两条来源是否要收敛待定。

---

## 关联文件索引

迭代 flow 时的只读速查表（核心引擎 / 节点类 / 动作库 / 五类宿主 / 数据资源 / 测试的完整文件清单 + 「已实现功能默认不重构」约定）见 **[FlowFileIndex.md](FlowFileIndex.md)**。

## 关键文件

| 路径 | 角色 |
|------|------|
| `src/gameplay/flows/graph/FlowGraph.gd` | 根容器 + 静态拼装助手 |
| `src/gameplay/flows/graph/FlowNode/FlowDuration/FlowTrigger/FlowAction/FlowLeaf.gd` | 节点类 |
| `src/gameplay/flows/graph/FlowInterpreter.gd` | per-instance 解释器（含 `run_oneshot`） |
| `src/gameplay/flows/graph/leaves/*` | 脚本叶子（发射/弹射/出生死亡） |
| `src/gameplay/flows/FlowActions.gd` | 无状态动作库静态实现（复用，未变） |
| `src/gameplay/flows/GameplayFlowContext.gd` | 执行上下文 |
| `src/gameplay/flows/GameplayFlowRegistry.gd` | FlowGraph 注册表（扫 `resources/gameplay/flows/`，string-id 路径用） |
| `tests/FlowInterpreterTest.gd` | 解释器核心单测 |

相关记忆条：`flow-node-tree-interpreter`（终态）、`flow-effect-buff-three-layer`（第八期三层）、`actor-flow-host`、`weapon-system-flow-driven`、`actor-lifecycle-damage-chokepoint`。
