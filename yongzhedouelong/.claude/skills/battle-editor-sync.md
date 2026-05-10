# Battle Editor Sync Skill

同步游戏资产数据结构到 Battle Editor 编辑器代码。

## 触发条件

当以下情况发生时，运行此 Skill：
1. Skill/Buff/Enemy JSON 配置新增字段
2. SkillBase/AttributeBuff 脚本新增 @export 属性
3. 数据结构发生重大变更

## 执行步骤

### Step 1: 分析变更内容

请用户提供变更描述，例如：
- "Skill JSON 新增了 `critical_rate` 字段"
- "Buff 新增了 `icon_path` @export 属性"

### Step 2: 检查需要更新的文件

| 变更类型 | 目标文件 |
|----------|----------|
| Skill JSON 字段 | `addons/battleeditor/UI/BattleEditorPanel.gd` |
| Buff JSON 字段 | `addons/battleeditor/UI/BattleEditorPanel.gd` |
| Enemy 配置字段 | `addons/battleeditor/UI/BattleEditorPanel.gd` |
| Resource @export | **自动同步**（Inspector 自动扫描） |

### Step 3: 更新编辑器代码

**JSON 配置默认模板更新位置**:

```gdscript
# Skill JSON 默认模板（约第 565 行）
func _on_create_skill_json_config() -> void:
    _skill_json_config[_selected_skill_id] = {
        "damage": 10.0,      # ← 更新此处
        "level": 1,
        "cooldown": 3.0,
        # 新增字段在这里添加
    }

# Buff JSON 默认模板（约第 576 行）
func _on_create_buff_json_config() -> void:
    _buff_json_config[_selected_buff_id] = {
        "duration": 5.0,     # ← 更新此处
        "tick_interval": 1.0,
        # 新增字段在这里添加
    }

# Skill 创建时的 JSON 配置（约第 776 行）
_skill_json_config[skill_id] = {
    "damage": 10.0,
    "level": 1,
    "cooldown": 3.0,
    # 新增字段在这里添加
}

# Buff 创建时的 JSON 配置（约第 808 行）
_buff_json_config[buff_id] = {
    "duration": 5.0,
    "tick_interval": 1.0,
    # 新增字段在这里添加
}
```

### Step 4: 更新文档

同步更新 `docs/ASSETS_DATA.md`：
- 更新字段定义表格
- 更新 JSON 示例
- 记录变更日志

## 示例执行

**用户输入**: "Skill JSON 新增了 `critical_rate` 字段，类型为 float，默认值 0.1"

**Skill 执行**:
1. 读取 `BattleEditorPanel.gd`
2. 找到 4 处 Skill JSON 模板位置
3. 在每处添加 `"critical_rate": 0.1`
4. 更新 `ASSETS_DATA.md` 文档
5. 报告完成

## 注意事项

- Resource @export 属性无需手动同步（Inspector 自动扫描所有 @export）
- JSON 字段变更需要同步 4 处：新建对话框模板、创建时模板（Skill/Buff 各 2 处）
- Enemy 配置变更只需更新 `_create_new_enemy()` 函数