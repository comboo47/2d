# GameplayFlow 设计理念文档（已归档）

> **⚠️ 本文已废弃（2026/06/15，第十三期）。**
>
> 本文描述的是**早期设计设想**：`GameplayFlowBase` 基类 + `SkillFlow/BuffFlow/ActorFlow/LevelFlow` 子类、`trigger_event` 事件触发模式、`signal-condition-action` 模式、`effects[]` 数据拼装、`weapon_base` 信号链路等——这些**均未按此落地或已被删除**。
>
> 实际终态是 **Duration/Trigger/Action 节点树 + per-instance `FlowInterpreter`**：所有宿主共用 `FlowGraph` + `GameplayFlowContext`，没有 flow 子类；"等待"用 `FlowTrigger`（非 `trigger_event`/协程）；逻辑结构是数据节点、计算放 `FlowLeaf` 脚本叶子。
>
> **权威文档 → [`FlowSystem.md`](FlowSystem.md)**。其中「9. 已知未做 / 留待后续优化」一节收录了本文部分设想（如宿主子类约束、两类入口统一、可视化编辑器）作为**待评估的后续方向**。
>
> 本文不再维护。
