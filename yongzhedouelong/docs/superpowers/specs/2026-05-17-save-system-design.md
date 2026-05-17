# 存档系统设计

## 目标

为 `Yongzhedouelong` 构建第一版玩家进度存档系统。本版本保存长期进度，不保存战斗中的续玩状态。

系统需要让游戏在重新启动后记住战役和关卡进度，在完成关卡后解锁新关卡，记录已获得奖励，并提供重置进度能力，方便测试和后续菜单接入。

## 范围

本设计只覆盖单个自动进度存档。不包含多个存档槽、手动保存/读取 UI、战斗现场持久化、敌人持久化、玩家坐标持久化，或中途续关。

第一版实现应保持足够小，优先验证存储格式、公开 API 和集成位置。完整成长经济系统稳定后，再扩展更复杂的数据结构。

## 架构

新增 `SaveManager` autoload，由它统一负责所有存档文件访问。其他系统只能调用 `SaveManager` 方法，不直接读取或写入存档文件。

`SaveManager` 保存一个 JSON 文件：

```text
user://save/progress.json
```

启动时，`SaveManager` 如果发现文件存在，就尝试加载它。如果文件不存在、不可读、格式损坏，或 schema 版本不支持，就回退到默认进度字典。回退不应导致游戏崩溃。

第一版的接入点是“进度完成”，不是“场景加载”。`GameManager`、关卡流程代码，或未来的关卡完成奖励流程，可以在关卡完成或奖励领取后调用 `mark_level_completed()` 或 `unlock_level()`。

## 存档数据

版本 1 使用基于 Dictionary 的 JSON schema：

```json
{
  "schema_version": 1,
  "current_level_id": "",
  "completed_levels": [],
  "unlocked_levels": [],
  "rewards": {},
  "updated_at": ""
}
```

字段含义：

- `schema_version`：整数版本号，用于未来迁移。
- `current_level_id`：最近选择或完成的关卡 id。
- `completed_levels`：已完成关卡 id 的去重列表。
- `unlocked_levels`：已解锁可游玩关卡 id 的去重列表。
- `rewards`：奖励字典，以奖励 id 或资源 id 作为 key。因为长期经济系统尚未定型，value 暂时保持灵活。
- `updated_at`：时间戳字符串，用于调试和未来存档槽展示。

默认进度应包含 `schema_version = 1`、空进度数组、空奖励字典，以及空的 `current_level_id`。

## 公开 API

`SaveManager` 暴露以下方法：

```gdscript
func load_progress() -> Dictionary
func save_progress(progress: Dictionary) -> bool
func get_progress() -> Dictionary
func mark_level_completed(level_id: String, rewards: Dictionary = {}) -> bool
func unlock_level(level_id: String) -> bool
func reset_progress() -> bool
func has_save() -> bool
```

预期行为：

- `load_progress()` 从磁盘加载，并更新内存中的进度。
- `save_progress(progress)` 校验并写入进度，返回写入是否成功。
- `get_progress()` 返回内存进度的副本，避免调用方意外修改内部状态。
- `mark_level_completed()` 将关卡 id 加入 `completed_levels`，更新 `current_level_id`，合并奖励数据，并写入文件。
- `unlock_level()` 将关卡 id 加入 `unlocked_levels`，并写入文件。
- `reset_progress()` 删除或覆盖现有存档，恢复默认进度，并写入文件。
- `has_save()` 返回存档文件是否存在。

重复的关卡 id 不应被加入两次。

## 错误处理

可恢复的读取错误使用 `push_warning()`。写入失败使用 `push_error()`。两种情况都不应阻止游戏进入主菜单。

如果存档文件无法解析，`SaveManager` 在第一版中保留损坏文件不动，并继续使用默认内存进度。本版本不创建修复文件或备份文件。

如果写入失败，修改型 API 返回 `false`。第一版 UI 不展示写入失败提示。

## 集成方式

在 `project.godot` 的 `[autoload]` 中注册 `SaveManager`。

第一版代码集成保持收窄：

- `SaveManager` 进入场景树时自动加载进度。
- `GameManager` 继续专注于场景切换和游戏状态切换。
- 等关卡完成或奖励领取流程存在后，再从那里显式调用保存接口。
- 本版本不新增存档槽 UI。

重置接口用于测试和菜单接入。任何菜单中的重置按钮都应调用 `SaveManager.reset_progress()`，不应自己删除文件。

## 测试

为存档系统新增聚焦的 headless 测试：

- 没有存档文件时返回默认进度。
- 保存进度会把 JSON 写入磁盘。
- 保存后重新加载能恢复相同进度。
- 同一个关卡完成两次，只保留一条记录。
- 同一个关卡解锁两次，只保留一条记录。
- 重置进度后回到默认数据。
- 损坏 JSON 会回退到默认进度且不会崩溃。

测试应使用隔离测试路径，或让保存路径可注入，避免覆盖开发者真实的 `user://save/progress.json`。

## 已确认决策

- 存档范围：只做进度存档。
- 槽位策略：单个自动存档。
- 数据重点：战役、关卡、解锁和奖励进度。
- 读写时机：启动时读取；关卡完成或奖励领取后保存。
- 架构方案：独立 `SaveManager` autoload。
- 重置行为：第一版包含 `reset_progress()`。
