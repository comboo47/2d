# UI 系统说明文档

## UIManager 单例架构

**核心文件**: [UIManager.gd](../Scripts/GameBase/UIBase/UIManager.gd)
**场景文件**: [ui_manager.tscn](../ManagerScene/ui_manager.tscn)

UIManager 是 CanvasLayer 单例，管理三层 UI 结构。

### 三层 UI 结构

```gdscript
const LAYER_BATTLE := 0      # 战斗 HUD 层
const LAYER_MENU := 1        # 菜单层
const LAYER_OVERLAY := 2     # 叠加层（伤害数字、提示等）

# UI 层引用
var battle_layer: CanvasLayer
var menu_layer: CanvasLayer
var overlay_layer: CanvasLayer
```

| 层级 | 名称 | 内容 |
|------|------|------|
| 0 | Battle | HP Bar、Energy Bar、战斗 HUD |
| 1 | Menu | 暂停菜单、设置菜单、对话框 |
| 2 | Overlay | 伤害数字、提示信息、特效 |

### 核心信号定义

```gdscript
signal hp_changed(actor: BattleActor, old_value: float, new_value: float, max_value: float)
signal energy_changed(actor: BattleActor, current: float, max: float)
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)
signal ui_initialized
```

---

## UIConfig 场景路径配置

**文件路径**: [UIConfig.gd](../Scripts/GameBase/UIBase/UIConfig.gd)

### SceneType 枚举

```gdscript
enum SceneType {
    POP_DAMAGE,     # 伤害数字显示
    BATTLE_HUD,     # 战斗 HUD
    HP_BAR,         # HP 条
    ENERGY_BAR,     # 能量条
    MAIN_MENU,      # 主菜单
    PAUSE_MENU,     # 暂停菜单
    SETTINGS        # 设置菜单
}
```

### 场景路径配置

```gdscript
const SCENE_PATHS := {
    SceneType.POP_DAMAGE: "res://art/UIResource/UI/DamageNumber/PopDamage.tscn",
    SceneType.BATTLE_HUD: "res://art/UIResource/UI/HUD/BattleHUD.tscn",
    SceneType.HP_BAR: "res://art/UIResource/UI/HUD/HPBar.tscn",
    SceneType.ENERGY_BAR: "res://art/UIResource/UI/HUD/EnergyBar.tscn",
    SceneType.MAIN_MENU: "res://art/UIResource/UI/Menu/MainMenu.tscn",
    SceneType.PAUSE_MENU: "res://art/UIResource/UI/Menu/PauseMenu.tscn",
    SceneType.SETTINGS: "res://art/UIResource/UI/Menu/Settings.tscn"
}

const MENU_MAIN := "MainMenu"
const MENU_PAUSE := "PauseMenu"
const MENU_SETTINGS := "Settings"
```

### 场景缓存机制

```gdscript
static var _scene_cache: Dictionary = {}

static func get_scene(type: SceneType) -> PackedScene:
    if not _scene_cache.has(type):
        var path = SCENE_PATHS.get(type, "")
        var scene = load(path)
        _scene_cache[type] = scene
    return _scene_cache[type]

static func get_menu_scene_path(menu_name: String) -> String:
    match menu_name:
        MENU_MAIN: return SCENE_PATHS[SceneType.MAIN_MENU]
        MENU_PAUSE: return SCENE_PATHS[SceneType.PAUSE_MENU]
        MENU_SETTINGS: return SCENE_PATHS[SceneType.SETTINGS]
        _: return ""
```

---

## 伤害数字显示

### PopDamageWidget 实现

**核心文件**: [PopDamage.gd](../Scripts/GameBase/UIBase/Widget/PopDamage.gd)
**场景文件**: [PopDamage.tscn](../art/UIResource/UI/DamageNumber/PopDamage.tscn)

```gdscript
class_name PopDamageWidget extends Control

@export var numberList: Array[Resource]  # 0-9 数字纹理资源

var damageValue: Array[String]           # 伤害数字拆分
var popPosition: Vector2                 # 显示位置
var _is_active: bool = false

func init(_actor: BattleActor, _damageNumber: float = 15):
    popPosition = _actor.global_position + Vector2(0, -12) + Vector2(randf() * 7.5, randf() * 7.5)
    damageValue = split_number_to_list_str(int(ceil(_damageNumber)))
    _setup_digits()

func pop_damage():
    _is_active = true
    # PathFollow2D 动画沿曲线移动
    var tween = create_tween()
    tween.tween_property(path_follow_2d, "progress_ratio", 1, 0.5)
    timer.start()  # 0.6秒后自动回收

func reset():
    _is_active = false
    timer.stop()
    path_follow_2d.progress_ratio = 0

func is_active() -> bool:
    return _is_active
```

### 池化机制

```gdscript
# UIManager.gd
const DAMAGE_POOL_SIZE := 20
var _damage_widget_pool: Array[Control] = []

func _setup_widget_pool():
    var damage_scene = UIConfig.get_scene(UIConfig.SceneType.POP_DAMAGE)
    for i in range(DAMAGE_POOL_SIZE):
        var widget = damage_scene.instantiate()
        widget.set_process(false)
        overlay_layer.add_child(widget)
        _damage_widget_pool.append(widget)

func show_damage(actor: BattleActor, damage: float, position_offset: Vector2 = Vector2.ZERO):
    var widget = _get_damage_widget()
    widget.init(actor, abs(damage))
    widget.global_position = actor.global_position + Vector2(0, -12) + position_offset
    widget.pop_damage()

func _get_damage_widget() -> Control:
    for widget in _damage_widget_pool:
        if not widget.is_active():
            return widget
    # 池耗尽时动态创建
    var new_widget = UIConfig.get_scene(UIConfig.SceneType.POP_DAMAGE).instantiate()
    overlay_layer.add_child(new_widget)
    _damage_widget_pool.append(new_widget)
    return new_widget
```

---

## 能量条实现

### weaponEnergy 脚本

**文件路径**: [weaponEnergy.gd](../Scripts/Interface/weaponEnergy.gd)

```gdscript
extends Node

var player
var energy = float(0)
var energyShow = false

func _ready():
    player = $".".get_parent()
    updateEnergyBarvisible()

func _process(delta):
    if energyShow:
        var weapon = player.get_meta("CurrentWeapon")
        if weapon and weapon.has_method("getWeaponEnergy"):
            energy = weapon.getWeaponEnergy()
            energy = clamp(energy, 0, $ProgressBar.max_value)
            $ProgressBar.value = energy
        else:
            # 武器不支持能量显示，隐藏
            energyShow = false
            $".".visible = false

func updateEnergyBarvisible():
    if player.has_meta("CurrentWeapon"):
        var weapon = player.get_meta("CurrentWeapon")
        if weapon and weapon.has_method("getWeaponEnergy"):
            energy = weapon.getWeaponEnergy()
            player.set_meta("weaponEnergyBar", self)
            $ProgressBar.max_value = energy
            energyShow = true
            $".".visible = true
        else:
            $".".visible = false
    else:
        $".".visible = false
```

### 武器切换通知

```gdscript
# WeaponRoot.gd
func setCurrentWeapon(i: int):
    currentWeapon = i
    updateWeapon()
    # 通知能量条更新
    if weaponOwner.has_meta("weaponEnergyBar"):
        weaponOwner.get_meta("weaponEnergyBar").updateEnergyBarvisible()
```

---

## HUD 组件

### HPBarWidget

**文件路径**: [HPBarWidget.gd](../Scripts/GameBase/UIBase/Widget/HPBarWidget.gd)

```gdscript
class_name HPBarWidget extends Control

signal value_changed(current: float, max_value: float)
signal value_depleted()

@export var low_hp_threshold: float = 0.3  # 30%以下为低血量

var _current_value: float = 0.0
var _max_value: float = 100.0

func update_value(current: float, max_value: float):
    _current_value = current
    _max_value = max_value
    
    var progress_bar = get_node_or_null("ProgressBar")
    if progress_bar:
        progress_bar.max_value = max_value
        progress_bar.value = current
    
    # 低血量警告
    if current / max_value <= low_hp_threshold:
        _trigger_low_hp_warning()
```

### BattleHUD 场景结构

**场景路径**: [BattleHUD.tscn](../art/UIResource/UI/HUD/BattleHUD.tscn)

```
BattleHUD (Control)
├── HPBar (HPBarWidget)
│   ├── ProgressBar
│   └── HpLabel
└── EnergyBar (Control)
    └── ProgressBar
```

---

## UI 更新机制

### 角色绑定流程

```gdscript
# Main.gd
func _ready():
    player = _find_player()
    if player:
        UIManager.instance.bind_actor(player)
```

### bind_actor 实现

```gdscript
# UIManager.gd
func bind_actor(actor: BattleActor) -> void:
    if _bound_actor == actor:
        return
    
    # 解绑旧角色
    if _bound_actor:
        unbind_actor(_bound_actor)
    
    _bound_actor = actor
    
    # 绑定 HP 监听
    var attr_comp = actor.GetAttributes()
    if attr_comp:
        var hp_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Hp)
        if hp_attr and hp_attr.has_signal("attribute_changed"):
            if not hp_attr.attribute_changed.is_connected(_on_actor_hp_changed):
                hp_attr.attribute_changed.connect(_on_actor_hp_changed)
    
    # 创建 HUD
    _create_battle_hud(actor)
```

### HP 监听和更新

```gdscript
# UIManager.gd
func _on_actor_hp_changed(attr: Attribute, old_value: float, new_value: float) -> void:
    var max_hp = attr.base_value
    hp_changed.emit(_bound_actor, old_value, new_value, max_hp)
    
    # 更新 HP 条
    if hp_bar_widget and hp_bar_widget.has_method("update_value"):
        hp_bar_widget.update_value(new_value, max_hp)
    
    # 显示伤害数字（如果是伤害）
    if new_value < old_value:
        show_damage(_bound_actor, old_value - new_value)
```

### Attribute.attribute_changed 信号

```
Attribute.sub(damage)
      │
      ▼
attribute_changed.emit(old_value, new_value)
      │
      ▼
UIManager._on_actor_hp_changed()
      │
      ├── hp_changed.emit()
      ├── hp_bar_widget.update_value()
      └── show_damage()
```

---

## 菜单系统

### UIPanel 基类

**文件路径**: [UIPanel.gd](../Scripts/GameBase/UIBase/Panel/UIPanel.gd)

```gdscript
class_name UIPanel extends Control

enum PanelType { HUD, MENU, DIALOG, POPUP }

signal panel_closed
signal panel_action(action_name: String)

@export var panel_type: PanelType = PanelType.MENU
@export var close_on_escape: bool = true
@export var pause_game: bool = false

var _is_open: bool = false

func _input(event: InputEvent):
    if _is_open and close_on_escape and event.is_action_pressed("ui_cancel"):
        close()
        get_viewport().set_input_as_handled()

func open():
    _is_open = true
    show()
    if pause_game:
        get_tree().paused = true

func close():
    _is_open = false
    hide()
    panel_closed.emit()
    if pause_game and get_tree().paused:
        get_tree().paused = false
```

### PauseMenuPanel

**文件路径**: [PauseMenuPanel.gd](../Scripts/GameBase/UIBase/Panel/PauseMenuPanel.gd)
**场景文件**: [PauseMenu.tscn](../art/UIResource/UI/Menu/PauseMenu.tscn)

```gdscript
class_name PauseMenuPanel extends UIPanel

var _closed_by_button: bool = false

func close():
    if GameManager.is_paused():
        # 输入锁定防止 fire release 触发
        var lock_duration = 0.15 if not _closed_by_button else 0.3
        InputManager.lock_inputs(lock_duration)
        GameManager.change_state(GameManager.GameState.PLAYING)
        GameManager.game_resumed.emit()
    super.close()

func _on_resume_pressed():
    get_viewport().set_input_as_handled()
    _closed_by_button = true
    close()

func _on_main_menu_pressed():
    GameManager.return_to_main_menu()
```

### MainMenuPanel

**文件路径**: [MainMenuPanel.gd](../Scripts/GameBase/UIBase/Panel/MainMenuPanel.gd)
**场景文件**: [MainMenu.tscn](../art/UIResource/UI/Menu/MainMenu.tscn)

```gdscript
class_name MainMenuPanel extends UIPanel

func _ready():
    super._ready()
    pause_game = true
    close_on_escape = false  # 主菜单不能 ESC 关闭
    get_tree().paused = true
    process_mode = Node.PROCESS_MODE_ALWAYS

func _on_start_pressed():
    get_viewport().set_input_as_handled()
    GameManager.start_game()
```

---

## UI 组件复用模式

| 模式 | 描述 | 实现 |
|------|------|------|
| **对象池化** | PopDamageWidget 预创建池 | `UIManager._damage_widget_pool` (20个) |
| **场景缓存** | UIConfig 缓存 PackedScene | `UIConfig._scene_cache` |
| **信号绑定** | Attribute.attribute_changed → UIManager | 解耦更新机制 |
| **面板基类** | UIPanel 提供通用功能 | 继承复用 |
| **Meta 存储** | 武器引用通过 meta 存储 | `player.set_meta("CurrentWeapon")` |
| **能量条通知** | WeaponRoot 切换武器时通知能量条 | `weaponEnergyBar.updateEnergyBarvisible()` |

---

## 关键代码路径汇总表

| 类/文件 | 路径 |
|--------|------|
| UIManager | [Scripts/GameBase/UIBase/UIManager.gd](../Scripts/GameBase/UIBase/UIManager.gd) |
| UIConfig | [Scripts/GameBase/UIBase/UIConfig.gd](../Scripts/GameBase/UIBase/UIConfig.gd) |
| PopDamageWidget | [Scripts/GameBase/UIBase/Widget/PopDamage.gd](../Scripts/GameBase/UIBase/Widget/PopDamage.gd) |
| HPBarWidget | [Scripts/GameBase/UIBase/Widget/HPBarWidget.gd](../Scripts/GameBase/UIBase/Widget/HPBarWidget.gd) |
| UIPanel | [Scripts/GameBase/UIBase/Panel/UIPanel.gd](../Scripts/GameBase/UIBase/Panel/UIPanel.gd) |
| PauseMenuPanel | [Scripts/GameBase/UIBase/Panel/PauseMenuPanel.gd](../Scripts/GameBase/UIBase/Panel/PauseMenuPanel.gd) |
| MainMenuPanel | [Scripts/GameBase/UIBase/Panel/MainMenuPanel.gd](../Scripts/GameBase/UIBase/Panel/MainMenuPanel.gd) |
| weaponEnergy | [Scripts/Interface/weaponEnergy.gd](../Scripts/Interface/weaponEnergy.gd) |
| WeaponRoot | [prefab/Component/WeaponRoot.gd](../prefab/Component/WeaponRoot.gd) |
| Main.gd | [Scripts/GameModeScript/Main.gd](../Scripts/GameModeScript/Main.gd) |
| GameManager | [Scripts/GameBase/GameManager.gd](../Scripts/GameBase/GameManager.gd) |
| InputManager | [Scripts/GameBase/InputManager.gd](../Scripts/GameBase/InputManager.gd) |
| BattleActor | [Scripts/GameBase/BattleSystemBase/BattleActor/BattleActor.gd](../Scripts/GameBase/BattleSystemBase/BattleActor/BattleActor.gd) |
| Attribute | [Scripts/GameBase/BattleSystemBase/AttributeSystem/AttributeSysscript/Attribute.gd](../Scripts/GameBase/BattleSystemBase/AttributeSystem/AttributeSysscript/Attribute.gd) |

---

## 相关文档

- [Architecture.md](Architecture.md) - 整体架构概览
- [WeaponSystem.md](WeaponSystem.md) - 武器系统详细说明
- [BulletSystem.md](BulletSystem.md) - 子弹系统详细说明