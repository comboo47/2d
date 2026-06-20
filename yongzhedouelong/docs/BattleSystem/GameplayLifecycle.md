# Gameplay 生命周期地图

> 本文档是 gameplay 运行生命周期的**权威地图**：游戏里有哪些「官方钩子点」、各自在什么时机由谁 emit、走哪条分发路径、当前是否真正接通。
> 用途：flow / 特质 / buff 要挂逻辑时，从这张图找钩子点；新增钩子时按本文规则归位。
> 状态（2026/06/14）：**ACTOR_HIT/DIED/KILL 已收口接通**（DamageResolver 全权 emit + 驱动死亡，旧 BattleActor signal 已删）。其余空壳钩子（LEVEL_END 等）仍待补。
> 注：**逐帧 tick 类钩子**（BULLET_PROCESS、on_tick 等）本期不纳入，留待单独处理。

---

## 一、分发路径规则（最重要——决定新钩子怎么走）

系统有**三条**事件分发路径。新增任何钩子前，先按此规则选定它走哪条：

| 路径 | 适用 | 机制 | 例子 |
|---|---|---|---|
| **A. 全局总线** `GameplayEventBus` | **全局/跨实体**事件：任何系统都可能关心、需要广播 | emit → 总线 → 所有订阅者（FlowRuntime 按 listen_events 转发给常驻 flow；BuffManager 按 source/target+event_flows 转发给 buff） | 关卡、角色生死、伤害结算、技能、Buff |
| **B. 点对点** `FlowRuntime.deliver_event(inst, evt)` | **holder 私有、且 holder 持有常驻 flow 实例**：只发给"我自己的那个 flow" | 直达某个 flow 实例的 on_event，不广播 | 武器开火（WeaponDriver→自己的 fire_flow） |
| **C. 容器自管** `TraitContainer.dispatch(evt)` | **holder 私有、量大短命、不该进全局**：holder 自己的容器内分发 | 容器遍历自己的特质 flow，按 listen_events 过滤，完全不碰总线 | 子弹生命周期（命中/生成/销毁） |

**选择规则（一句话）**：
- 事件**全局可关心** → 走 A（总线）。
- 事件**只属于某个 holder、holder 有专属 flow** → 走 B（点对点）。
- 事件**属于海量短命实体（子弹）或 holder 自带容器** → 走 C（自管），杜绝总线广播压力与跨实体串扰。

> 反例警示：子弹命中**不能**走总线——A 子弹命中不该触发 B 子弹的特质。这正是 C 存在的理由。

---

## 二、现状盘点（2026/06/14 逐行核实）

图例：✅ 活钩子（有发有听） ｜ 🟡 发了暂无 listener ｜ ⚠️ 空壳（枚举有、从未 emit） ｜ 断裂（新旧两套未接通）

| 事件(枚举值) | 层 | emit 点 | emit 者 | 分发 | 现状 |
|---|---|---|---|---|---|
| LEVEL_START (0) | 关卡 | LevelRunner.gd:20 | LevelRunner | A 总线 + 关卡一次性flow | ✅ |
| LEVEL_END (1) | 关卡 | — | — | — | ⚠️ 空壳 |
| ACTOR_SPAWNED (2) | 角色 | LevelRunner.gd:43 | LevelRunner | A 总线 | 🟡 发了暂无 flow 监听 |
| ACTOR_DIED (3) | 角色 | DamageResolver.gd | DamageResolver | A 总线 | ✅（HP≤0 时收口 emit，带 killer） |
| ACTOR_HIT (4) | 角色 | DamageResolver.gd | DamageResolver | A 总线 | ✅（造成伤害时收口 emit，带 source） |
| ACTOR_KILL (5) | 角色 | DamageResolver.gd | DamageResolver | A 总线 | ✅（致命一击且有 source 时 emit） |
| SKILL_USED (6) | 技能 | SkillBase.gd:64 | SkillBase.use | A 总线 | ✅ |
| BUFF_APPLIED (7) | Buff | buff_manager.gd:30 | BuffManager | A 总线 | ✅ |
| BUFF_REMOVED (8) | Buff | buff_manager.gd:37 | BuffManager | A 总线 | ✅ |
| BUFF_TICK (9) | Buff | buff_manager.gd:49（buff.run_process 产生） | BuffManager | A 总线 | ✅（burn buff 在用） |
| BUFF_STACK_CHANGED (10) | Buff | AttributeBuff.gd:101 | AttributeBuff.add_stack | A 总线 | ✅ |
| DAMAGE_REQUESTED (11) | 战斗 | DamageResolver.gd:14 | DamageResolver | A 总线 | ✅（buff 在此改伤害） |
| DAMAGE_APPLIED (12) | 战斗 | DamageResolver.gd:32 | DamageResolver | A 总线 | ✅ |
| WEAPON_FIRE_PRESSED (13) | 武器 | WeaponDriver.gd:46 | WeaponDriver | B 点对点 | ✅ |
| WEAPON_FIRE_HELD (14) | 武器 | — | — | (B) | ⚠️ 空壳（HOLD 连发未用此事件，在 flow 内 tick 实现） |
| WEAPON_FIRE_RELEASED (15) | 武器 | WeaponDriver.gd:51 | WeaponDriver | B 点对点 | ✅ |
| BULLET_SPAWNED (16) | 子弹 | BulletBase.gd:62 | BulletBase | C 自管 | ✅（仅带 traits 时发） |
| BULLET_PROCESS (17) | 子弹 | — | — | (C) | ⚠️ 空壳（逐帧，本期不做） |
| BULLET_HIT (18) | 子弹 | BulletBase.gd:91 | BulletBase | C 自管 | ✅（弹射特质在用） |
| BULLET_RELEASED (19) | 子弹 | BulletBase.gd:78 | BulletBase | C 自管 | ✅（仅带 traits 时发） |

**小结**：17 活 / 1 暂无听众(ACTOR_SPAWNED) / 3 空壳(LEVEL_END, WEAPON_FIRE_HELD, BULLET_PROCESS) 。

**已收口（2026/06/14 第七期）**：`ACTOR_HIT/KILL/DIED` 三个核心钩子已由 **DamageResolver 全权收口**——所有伤害走 `DamageResolver.resolve()`，扣血后统一判死并广播这三个事件（都带 source/target），同时驱动 `BattleActor.kill()` 死亡流程。旧的 `BattleActor` Godot signal（actor_hit/died/kill/spawned）**已删除**，flow/特质/buff/UI 现在可经总线挂载受击/击杀/死亡逻辑。详见 `GameplayRuntimeCore.md` 的「伤害管线终态」。

---

## 三、理想生命周期（设计目标，标注待补）

> 决策：`ACTOR_*` 统一到 GameplayEvent 总线（旧 BattleActor signal 标为待迁移/淘汰）。逐帧 tick 类不在本期。

### 关卡级（走 A 总线）
- `LEVEL_START` ✅ ｜ `LEVEL_END` ⚠️待补 ｜ `WAVE_START` / `WAVE_END` 🆕（波次概念，未来需要再加）

### 角色级（走 A 总线）
- `ACTOR_SPAWNED` ✅(待接 flow) ｜ `ACTOR_HIT` ✅ ｜ `ACTOR_KILL` ✅ ｜ `ACTOR_DIED` ✅ ｜ `ACTOR_ATTR_CHANGED` 🆕（属性变化，未来）
- **收口实现**：三者由 `DamageResolver.resolve()` 在扣血后统一 emit——`ACTOR_HIT`（final_amount>0 时，带 source）、`ACTOR_DIED`（HP≤0 时，event_data 带 killer）、`ACTOR_KILL`（致命一击且 source 非空时）。Resolver 同时直接调 `target.trigger_hit_flow/kill()` 与 `source.trigger_kill_flow()` 驱动 actor 配置的 flow_id。旧 `BattleActor` signal 已删。

### 战斗结算级（走 A 总线，独立伤害管线）
- `DAMAGE_REQUESTED` ✅（buff/特质在此改 damage_request——这是"结算时合成"的唯一官方介入点） ｜ `DAMAGE_APPLIED` ✅
- 未来可选：`ON_CRIT` / `ON_HEAL` 🆕

### 武器级（走 B 点对点，发给武器自己的 fire_flow）
- `WEAPON_FIRE_PRESSED` ✅ ｜ `WEAPON_FIRE_RELEASED` ✅ ｜ `WEAPON_FIRE_HELD` ⚠️（当前连发在 flow.on_tick 内实现，未用此事件——保留枚举备用） ｜ `WEAPON_EQUIP` / `WEAPON_UNEQUIP` / `CHARGE_MAX` / `ENERGY_EMPTY` 🆕（未来）

### 子弹级（走 C 容器自管）
- `BULLET_SPAWNED` ✅ ｜ `BULLET_HIT` ✅ ｜ `BULLET_RELEASED` ✅ ｜ `BULLET_PROCESS` ⚠️（逐帧，本期不做，未来若特质需逐帧再补）

### 技能级（走 A 总线）
- `SKILL_USED` ✅ ｜ `SKILL_COOLDOWN_READY` / `SKILL_TRIGGERED` 🆕（未来）

### Buff 级（走 A 总线，BuffManager 转发）
- `BUFF_APPLIED` ✅ ｜ `BUFF_REMOVED` ✅ ｜ `BUFF_TICK` ✅ ｜ `BUFF_STACK_CHANGED` ✅（本层最完整）

---

## 四、待补清单（按优先级，非本期实现）

1. **✅ 已完成（第七期）｜ACTOR_HIT/KILL/DIED 接入总线**：由 DamageResolver 全权收口 emit，旧 signal 已删。同时修复了「敌人 HP=0 不死」的死亡链断裂（`base_enemy.setDead` 从未被调用 → 改为 `_on_death` 由 `kill()` 驱动）。
2. **🟡 中｜LEVEL_END**：对称补 emit，关卡结束 flow 才有处挂。
3. **🟡 中｜ACTOR_SPAWNED 接 flow**：已 emit 但无 listener，确认是否需要"生成时"逻辑入口。
4. **🟢 低｜WEAPON_FIRE_HELD**：若要把连发节奏从 flow.on_tick 改为事件驱动再启用。
5. **🟢 低｜BULLET_PROCESS / tick 类**：逐帧钩子，单独设计（性能敏感）。
6. **📄 文档｜DAMAGE_REQUESTED 改伤害范式**：补一份"buff/特质如何在 DAMAGE_REQUESTED 改 damage_request"的示例。
7. **🟡 中｜玩家受击/死亡**：玩家目前无 `_beHurt`（敌人子弹命中被 `has_method` 跳过），从不受伤。接通需无敌帧/game over UI 等新设计，独立立项；`BattleActor.kill()/_on_death()` 通用入口已为其预留。

---

## 五、与 flow 形式重构的关系（下一轮）

用户已定方向：flow 将从「Resource + 数据拼装」改为「挂在生命周期钩子上的纯逻辑脚本」（脱 Resource 壳、按名引用、砍 effects 数据拼装）。
**本图是那次重构的前置**：先把"有哪些钩子点 + 走哪条分发"定清楚，flow 才有稳定的挂载骨架。flow 形式重构在本图基础上进行。
