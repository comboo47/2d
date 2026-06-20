# Flow 编辑器 / JSON 数据契约（阶段 1）

> Flow 重构（JSON 数据驱动 + HTML 蓝图编辑器 + 分支）的**地基**。本目录只产数据契约 + 样例；
> 运行时加载（`FlowGraph.from_dict`）、HTML 编辑器、解释器分支在后续阶段交付。
> 计划全文见 plan `melodic-whistling-biscuit`，机制权威见 `Docs/BattleSystem/FlowFileIndex.md`。

## 两份 schema 的分工

| 文件 | 角色 | 谁消费 |
|------|------|--------|
| [`flow.schema.json`](flow.schema.json) | **数据契约**（JSON Schema draft-07）：一份 `.flow.json` 文档的合法结构 / 字段 / 取值约束。 | 运行时 `from_dict`、校验器、`*.flow.json` 作者。 |
| [`flow_schema.json`](flow_schema.json) | **编辑器调色板清单**：可用节点类型、动作及其 opts、leaf 脚本及 `@export`、枚举、表达式白名单——从 GDScript 代码事实派生。 | HTML 蓝图编辑器（注册节点）。初期手维护，后续由生成脚本扫 GDScript 重出。 |

> 命名易混：`flow.schema.json`（带点，单数 schema=契约） vs `flow_schema.json`（下划线，编辑器清单）。

## 图模型回顾

- **主线节点**只有两种：`duration`（生命周期壳）/ `condition`（分支，本期新增）。带 `id` + `pos`（编辑器坐标，运行时忽略）+ 执行 pin。
- **Trigger / Action 是 Duration 的并行 `children`**，不是主线图节点（与数据模型一致：children 是并行内含，非主线流转）。
- **连线 `connections`**：`{from, from_pin, to}`，与 GraphEdit/LiteGraph link 同构。pin 用稳定字符串名（增删 pin 不错位）：
  - `duration` 输出 pin = `"out"`。
  - `condition` bool 模式 = `"true"` / `"false"`；switch 模式 = `"case_0"`..`"case_N"` / `"default"`。
  - `to` 指回上游节点 = loop 回边（解释器靠 MAX_HOPS 守卫）。
- **只表达执行流 pin**（下一步走哪），**不做数据 pin**——数据走 `ctx`。这是与 Orchestrator（通用脚本语言）的根本分界。

## 资源引用约定（from_dict 反序列化最硬的一块）

JSON 不能嵌 Godot 资源，一律用字符串路径 + 反序列化时水合：

| 形态 | JSON 写法 | from_dict 行为 |
|------|-----------|----------------|
| **枚举**（lifetime_mode/event_type/end_mode） | 枚举名字符串，如 `"INSTANT"` / `"BUFF_TICK"` / `"NEVER"` | 转回 int（可读、防 int 漂移） |
| **脚本叶子 / filter / predicate** | `{ "script": "res://...gd", "props": { ... } }` | `load(script).new()`，再灌 `props`；props 中是 Resource 类型属性、值为 `res://` 字符串时 `load()` 回资源（如 leaf 的 `bullet_scene`） |
| **buff 资源**（apply_buff） | `"buff_res": "res://...tres"` | `load()` 回 `AttributeBuff` |
| **opts 内的资源**（如 fire_projectile 的 `bullet`） | `res://` 字符串 | 由 action 实现/from_dict 在用时 load（opts 是原生 Dictionary） |

## 样例自检（覆盖现有全部节点形态 + Condition）

`samples/` 下的 `.flow.json` 手写覆盖现有 10 个 flow 的**所有节点形态**，并新增 Condition 演示。
JSON 解析 + 结构校验（entry/连线端点/pin 与 use_switch 匹配/枚举/路径）已通过——见下方"验证"。

| 样例 | 形态 | 覆盖的现有 flow |
|------|------|-----------------|
| [`example_burn_tick`](samples/example_burn_tick.flow.json) | FOREVER + Trigger(BUFF_TICK, NEVER) → deal_damage | `example_burn_tick_flow`、`WeaponTemplate_TickFlow`（同形态，仅 opts 异） |
| [`bow_shot`](samples/bow_shot.flow.json) | INSTANT + 脚本叶子（BowShot，带 `bullet_scene`/`max_charge_speed`） | `skill_bow_fire`；同形态覆盖 `skill_bottle_fire`(BottleShot)/`skill_crossbow_fire`+`skill_pistol_fire`(Shot)——仅 leaf 脚本/props 异 |
| [`example_firebolt`](samples/example_firebolt.flow.json) | INSTANT + 两个并行 Action（deal_damage + apply_buff `buff_res`） | `example_firebolt_skill`、`WeaponTemplate_Skill`（同形态） |
| [`enemy_death_sample`](samples/enemy_death_sample.flow.json) | 两 Duration 串 `out`：INSTANT(leaf EnemyDeath) → SECONDS(延时门控) | `actor_init_sample` 的 `death_flow` |
| `enemy_death_sample`(首节点) | INSTANT + 脚本叶子（无 props） | `actor_init_sample` 的 `spawn_flow`（EnemySpawn，单 INSTANT leaf，同形态） |
| [`trait_bounce`](samples/trait_bounce.flow.json) | FOREVER + Trigger(BULLET_HIT, NEVER) → 脚本叶子（Bounce） | `trait_bounce` |
| [`condition_demo_bool`](samples/condition_demo_bool.flow.json) | **新增**：Condition(expression, bool) → true/false 两 Duration 分支 | —（本期新能力） |
| [`condition_demo_switch`](samples/condition_demo_switch.flow.json) | **新增**：Condition(use_switch) → case_1/default 分支 | —（本期新能力） |

> 现有 10 个 flow 的节点形态共 4 类：①FOREVER+Trigger+data-action（burn/weapon-tick） ②INSTANT+leaf（4 个发射 + spawn） ③INSTANT+多并行 data-action（2 个 skill，含 buff_res） ④多 Duration 串 out（death）。`trait_bounce` 是 ①的 leaf 变体。样例全覆盖。

## 验证

无 Python；用 Node 校验（仓库已有 Node v24）。从本目录运行：

```bash
# 1) 全部 JSON 可解析
node -e 'const fs=require("fs"),p=require("path");let ok=true;for(const d of [".","samples"])for(const f of fs.readdirSync(d)){if(!f.endsWith(".json"))continue;try{JSON.parse(fs.readFileSync(p.join(d,f),"utf8"))}catch(e){ok=false;console.log("FAIL",f,e.message)}}console.log(ok?"ALL JSON OK":"PARSE ERRORS");'
```

结构校验脚本（entry/连线端点/pin↔use_switch/枚举/`res://` 路径）见提交记录中执行的内联 Node 校验；阶段 3 落地 `FlowGraph.from_dict` 后改由 GDScript 往返单测（`from_dict(to_dict(g)) ≡ g`）权威验证。

## 下一阶段

- **阶段 2**：LiteGraph.js 单页编辑器，读 `flow_schema.json` 注册 Duration/Condition 节点 + children 内部 UI + `res://` 路径框，导出 `.flow.json`。
- **阶段 3**：`FlowGraph.from_dict/to_dict` + FlowRegistry 扫 `resources/gameplay/flows/*.flow.json` + `AttributeConfig.actor_attr`（与 DamageRequest 共用属性解析）。
