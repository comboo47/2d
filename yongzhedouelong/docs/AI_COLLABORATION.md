# AI 协作开发节奏

这份文档给项目作者和 AI 一起使用。它不是架构说明，而是约定“怎么合作、怎么拆任务、怎么验收”，让 AI 开发更稳定、更容易回滚。

## 基本原则

- 一次只做一个明确目标，避免把“分析、重构、修 bug、加功能、改表格”混在同一轮。
- 复杂任务先计划，确认后再实施；小修小补可以直接实施，但仍要说明验证结果。
- AI 开始工作前先看 `AGENTS.md`，再根据任务读取相关代码和文档。
- 不把 `.godot/`、本地日志、MCP 私有配置、编辑器缓存提交进仓库。
- `.tscn`、`.tres`、表格生成物要小心处理，优先最小 diff。
- 用户在 Godot 编辑器里改过的内容默认是用户改动，AI 不应回滚。

## 推荐工作流

### 1. 计划阶段

适合新系统、较大功能、涉及多个模块的任务。

用户可以这样说：

```text
先只做方案，不改文件。请阅读 AGENTS.md 和相关系统文档，给我实现 XXX 的计划。
```

AI 应该输出：

- 当前系统怎么工作。
- 要改哪些模块。
- 新增/修改哪些数据结构或资源。
- 兼容和风险点。
- 验证方式。

### 2. 实施阶段

确认计划后再说：

```text
按这个方案实施。
```

AI 实施时应该：

- 先跑 `git status --short`。
- 只改和任务相关的文件。
- 改表格时以 `Tables/Excel` 为源头。
- 改 Godot 场景/资源时避免无关重保存。
- 完成后跑最小必要验证。

### 3. 验收阶段

AI 完成后应汇报：

- 改了什么。
- 跑了什么验证。
- 还有什么已知残留问题。
- 是否创建了 commit。

如果 Godot headless 输出里还有旧的资源泄漏或退出警告，要区分它们是否是本次改动引入。

## 常用任务模板

### 只分析不改

```text
请只分析，不改文件。阅读 AGENTS.md 和相关代码，解释 XXX 当前是怎么工作的，并指出风险点。
```

### 先计划后实现

```text
先给我一个实现 XXX 的计划，不要改文件。计划里包含涉及模块、数据流、验证方式。
```

然后：

```text
PLEASE IMPLEMENT THIS PLAN:
<粘贴计划>
```

### 小范围修 bug

```text
修复 XXX 报错。只做最小改动，不做无关重构。完成后运行 Godot headless 检查。
```

### 新增战斗功能

```text
实现 XXX 战斗效果。需要检查 Skill/Buff/Attribute/GameplayFlow 是否已有可复用机制。先复用现有系统，不要新建平行架构。
```

### 修改数据表

```text
修改 XXX 配置。优先修改 Tables/Excel 源表，然后运行 Tables/gen_all.bat 生成 JSON。不要直接手改生成 JSON，除非说明理由。
```

### 修改场景或资源

```text
修改 XXX 场景/资源。请保持最小 diff，不要重保存无关 .tscn/.tres，不要修改 .uid 文件，除非 Godot 必须生成。
```

## Godot 与 MCP 使用节奏

- 如果 GoPeak MCP 工具可用，优先用它做只读检查：项目状态、场景树、资源路径。
- 需要编辑场景结构时，先明确目标节点和预期变化，再让 AI 操作。
- 如果 MCP 工具没有暴露，AI 可以退回文件级检查和 Godot CLI 验证。
- Godot 编辑器打开项目后，GoPeak Editor Bridge 应连接 `6505` 端口。

## 表格协作规则

- `Tables/Excel` 是数据源。
- `Tables/Json` 是生成物，默认不要手改。
- 改 Excel 后运行：

```powershell
cd Tables
.\gen_all.bat
```

- 如果数据字段影响 Battle Editor，必须同步：
  - `addons/battleeditor/UI/BattleEditorPanel.gd`
  - `Docs/ASSETS_DATA.md`
  - 相关 runtime loader/consumer

## Commit 节奏

建议一类目标一个 commit：

- 清理本机缓存。
- 安装工具或 addon。
- 修一个明确 bug。
- 加一个明确功能。
- 更新一组数据表。

不要把“工具配置、功能开发、格式化、资源重保存”混在一个 commit 里。

## 任务完成定义

一个任务通常要满足：

- `git status --short` 中只有预期变更，或提交后干净。
- `git diff --check` 通过。
- 必要时 Godot headless 能启动：

```powershell
& "E:\GODOT4.6\Godot_v4.6-beta2_win64.exe" --headless --path . --quit
```

- 如果改了表格，运行 `Tables/gen_all.bat`。
- 如果改了 UI/场景/资源，最好在 Godot 编辑器里人工看一眼。

## 给 AI 的协作要求

- 先读上下文，不要凭记忆猜项目结构。
- 遇到已有脏文件，先说明，不要回滚用户改动。
- 默认保守改动，除非用户明确要求重构或删除。
- 删除旧系统前，先搜索引用并说明影响范围。
- 最终回答要短而具体：改动、验证、残留问题。
