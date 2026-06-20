# GameplayFlow 系统说明文档（已归档）

> **⚠️ 本文已废弃（2026/06/15，第十三期）。**
>
> 本文描述的是**已删除**的 `GameplayFlowBase` 脚本类模型（`_execute_flow` / `on_start/on_tick/on_event/on_stop` / `effects[]` / `trigger_event` / `condition_expression` / `FlowEffect` / `FlowRegistry.subscribe_to_signal` 等）。Flow 已整体重构为 **Duration/Trigger/Action 节点树 + per-instance `FlowInterpreter`**，`GameplayFlowBase.gd` 与 `FlowRuntime.gd` 已删除。
>
> **权威文档 → [`FlowSystem.md`](FlowSystem.md)**（含终态架构、设计取舍、宿主接入、数据样例、待办清单）。
>
> 本文不再维护，保留仅供查阅旧设计脉络。具体 API/字段一律以 `FlowSystem.md`、`GameplayRuntimeCore.md`、`CLAUDE.md` 为准。
