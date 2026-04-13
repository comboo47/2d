# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Yongzhedouelong** is a 2D pixel-art action shooter game built with **Godot 4.6**. Resolution is 384×240 with integer scaling. The game features player movement/shooting, enemy AI, a data-driven attribute/buff system, and weapon mechanics.

## Development Commands

This is a Godot project — there is no build step from the command line. All development is done through the Godot Editor or via the Godot CLI:

```bash
# Run the project (requires Godot 4.6 installed)
godot --path . project.godot

# Export (requires export templates)
godot --path . --export-release "Windows Desktop" build/game.exe

# Data table generation (Excel → JSON)
cd Tables && gen_all.bat
```

The `Tables/` directory contains an Excel-to-JSON pipeline (`gen_all.bat`) that converts `Tables/Excel/*.xlsx` into `Tables/Json/` — run this after modifying any data tables.

## Architecture

### Autoloaded Singletons (project.godot `[autoload]`)

| Singleton | Script/Scene | Purpose |
|-----------|-------------|---------|
| `BattleManager` | `Scripts/GameBase/BattleSystemBase/BattleSystem/BattleManager.gd` | Static utility methods for applying/removing buffs, combat operations, Skill/Vfx/Flow API |
| `DataRegistry` | `Scripts/GameBase/GameDataBase/DataManager.gd` | Registry for `AttributeBuff` resources, keyed by `buff_id` |
| `DataAutoScanner` | `Scripts/GameBase/GameDataBase/DataAutoScanner.gd` | On startup, scans `res://prefab/Buffs/` and registers all `.tres` buff resources |
| `DropManager` | `Scripts/GameBase/BattleSystemBase/DropSystem/DropManager.gd` | Handles item/poker drops from enemies, data-driven with DropConfig.json |
| `BulletManager` | `ManagerScene/bullet_manager.tscn` | Manages bullet instantiation and lifecycle |
| `VfxManager` | `Scripts/GameBase/BattleSystemBase/VfxSystem/VfxManager.gd` | Unified visual effects management with pooling system |
| `EnemyFactory` | `Scripts/GameBase/BattleSystemBase/EnemySystem/EnemyFactory.gd` | Dynamic enemy creation from EnemyConfig.json |
| `SkillRegistry` | `Scripts/GameBase/BattleSystemBase/SkillSystem/SkillRegistry.gd` | Registry for Skill resources, scans `res://prefab/Skills/` |
| `FlowRegistry` | `Scripts/GameBase/BattleSystemBase/GameplayFlow/GameplayFlowRegistry.gd` | Registry for GameplayFlow resources, scans `res://prefab/Flows/` |
| `MainUI` | `ManagerScene/main_ui.tscn` | Global HUD |
| `Player` | `prefab/Player/First_Player.tscn` | The player character (accessible globally via `/root/Player`) |
| `JsonLoader` | UID reference | Loads JSON data tables |

### Attribute System

The core attribute/buff pipeline:

```
AttributeConfig (enum: Hp, Armor, Atk, Mana, Crit)
    ↓
Attribute (Resource) — holds base_value + computed_value + buffs[]
    ↓
AttributeSet (Resource) — collection of Attributes, manages derived-attribute dependencies
    ↓
AttributeComponent (Node) — attaches to actors, drives AttributeSet._process each physics tick
```

- **`Attribute`** (`AttributeSysscript/Attribute.gd`): Base resource. Override `custom_compute()` to define calculation formulas, `derived_from()` to declare attribute dependencies, and `post_attribute_value_changed()` to clamp values.
- **`AttributeSet`** (`AttributeSysscript/AttributeSet.gd`): Duplicates all attributes at runtime so each actor instance has independent values. Tracks derived-attribute relationships for cascading updates.
- **`AttributeComponent`** (`AttributeSysscene/component/AttributeComponent.gd`): Node added to actors; drives `attribute_set.run_process(delta)` each frame.
- **`AttributeConfig`** (`AttributeConst/AttributeConfig.gd`): Central enum — add new attribute types here.

### Buff System

```
AttributeBuff (Resource) — buff_id, duration, DurationMerging policy, BuffEffects[]
    ↓
AttributeBuffEffect (base) — subclassed per effect type
    ├── E_AttributeModify — adds/subtracts from an Attribute
    └── E_Damage — deals damage
```

- Buffs are defined as `.tres` resources under `prefab/Buffs/` and auto-registered at startup by `DataAutoScanner`.
- Apply a buff: `BattleManager.ApplyBuff(source, target, buff_id)` — this calls `DataRegistry.get_buff(id)`, deep-duplicates it, and appends it to the target's `BuffManager`.
- **`BuffManager`** (`AttributeSysscene/component/buff_manager.gd`): Node child of every `BattleActor`; ticks all active buffs and removes expired ones each physics frame.
- Duration merging: `Restart` resets timer, `Addtion` stacks time, `NoEffect` ignores new applications.
- Key fields use snake_case: `buff_name`, `buff_execute()`, `execute_type()`.

### GameplayFlow System

Lifecycle script system for reusable event-driven behaviors (monster spawn/death, buff effects, skill effects):

```
GameplayFlowBase (Resource) — flow_id, trigger_event, effects[], condition_expression
    ↓ trigger events: ON_SPAWN, ON_DEATH, ON_HIT, ON_KILL, ON_SKILL_USE, ON_TIMER
    ↓
FlowEffect (composition pattern) — each effect is a separate Resource
    ├── FE_Damage          — deals damage to target
    ├── FE_SpawnVfx        — spawns visual effect at position
    ├── FE_ApplyBuff       — applies buff to target
    ├── FE_ModifyAttribute — modifies attribute value
    └── FE_SpawnEntity     — spawns entity (bullet, item, etc.)
```

- Flows are defined as `.tres` resources under `prefab/Flows/` and auto-registered by `FlowRegistry`.
- Execute a flow: `FlowRegistry.get_flow(flow_id).execute(context)` or via `BattleManager.trigger_flow_event()`.
- `GameplayFlowContext` holds execution context: `source`, `target`, `event_data`.

### Skill System

Skill management for active/passive/triggered abilities:

```
SkillBase (Resource) — skill_id, skill_type (ACTIVE/PASSIVE/TRIGGERED/TOGGLE), cooldown, effects[]
    ↓ managed by SkillManager (Node component on BattleActor)
    ↓
SkillEffect (composition pattern) — each effect is a separate Resource
    ├── SE_Projectile   — fires projectile
    ├── SE_AreaEffect   — applies effects in area
    ├── SE_BuffApply    — applies buff to target
    ├── SE_Damage       — deals direct damage
    └── SE_Heal         — heals target
```

- Skills are defined as `.tres` resources under `prefab/Skills/` and auto-registered by `SkillRegistry`.
- `SkillManager` handles skill slots, cooldowns, and execution.
- Weapons can link skills via `linked_skills` array; triggered on `weapon_fired`.
- Skill types: `ACTIVE` (player-triggered), `PASSIVE` (auto-effect), `TRIGGERED` (condition-based), `TOGGLE` (on/off state).

### Vfx System

Unified visual effects management with pooling:

```
VfxManager (Autoload) — play_vfx(), play_vfx_follow(), stop_vfx()
    ↓ pooling system: _vfx_pools[VfxType] = Array[Node]
    ↓
VfxConfig — enum VfxType (JUMP_PARTICLE, HIT_IMPACT, DEATH_EFFECT, BULLET_HIT, SKILL_EFFECT)
```

- Play effect: `VfxManager.play_vfx(VfxConfig.VfxType.HIT_IMPACT, position)`
- Effects auto-return to pool after duration defined in `VfxConfig.get_duration()`.
- Pool sizes configurable per VfxType.

### Enemy System (Data-Driven)

Enemy creation from JSON configuration:

```
EnemyConfig.json — keyed by enemy_id, defines: attributes, prefab_path, drop_table_id, spawn_flow_id, death_flow_id
    ↓ loaded by EnemyConfigLoader
    ↓
EnemyFactory.create_enemy(enemy_id, position) — instantiates enemy with configured attributes and flows
```

- Enemy attributes are loaded from JSON and applied via `AttributeComponent`.
- Enemies can have `spawn_flow_id` and `death_flow_id` for lifecycle behaviors.

### Drop System (Data-Driven)

Weight-based random drops from JSON configuration:

```
DropConfig.json — keyed by drop_table_id, defines: drops[] (weight, item_type), guaranteed_drop
    ↓ loaded by EnemyConfigLoader
    ↓
DropCalculator — weight-based random selection, poker pool management
```

- Drops calculated on enemy death: `DropManager.handle_enemy_death(enemy)`
- Supports weighted random drops and guaranteed drops.

### Actor Hierarchy

```
CharacterBody2D
    └── BattleActor (class_name) — base for all combatants; holds AttributeComponent ref + BuffManager
        ├── MainPlayer (Player.gd) — HSM-driven states (Idle/Move/Jump/Hurt/Die)
        └── base_enemy (base_enemy.gd) — BehaviorTree (LimboAI BT) driven, EnemyID links to data table
```

- Player state machine uses **LimboHSM** (hierarchical FSM from LimboAI addon).
- Enemies use **LimboAI BehaviorTree** (`bt` export field on `base_enemy`).
- All actors access their `AttributeComponent` via `BattleActor.GetAttributes()`.
- LimboHSM state methods: `_enter()`, `_exit()`, `_update()` (not `_on_exited`).

### Weapon System

```
WeaponBase (Node2D, class_name) — unified weapon base class
    signal: weapon_fired(bullet, spawn_position, direction, speed, bullet_type)
    ├── Bow/ (Weapon_Bow.gd) — hold for spread shot
    ├── Crossbow/ (Weapon_Crossbow.gd) — energy-based auto-fire
    └── Bottle/ (Weapon_Bottle.gd) — throwable bottle
    └── EnemyWeapon/ — enemy weapons extend WeaponBase
```

- Weapons emit `weapon_fired(bullet, spawn_position, direction, speed, bullet_type)` signal.
- `BulletManager.handle_bullet_spawn()` handles both new and legacy signal formats.
- The player's current weapon is stored as meta: `actor.get_meta("CurrentWeapon")`.
- WeaponRoot connects weapon signals to BulletManager and sets `owner_actor`.

### Data Tables

- Source: `Tables/Excel/BattleAttribute.xlsx`
- Output: `Tables/Json/BattleAttribute/BattleActorAttribute.json`
- Format: keyed by `AttributeID` (e.g. `10001`), fields: `MaxHP`, `Attack`, `Armor`, `Strength`, `Crit`
- `JsonLoader` autoload reads these JSON files; `DataRegistry` and `DataAutoScanner` handle buff resource registration separately.

### Directory Structure

```
Scripts/
  GameBase/
    BattleSystemBase/
      AttributeSystem/
        AttributeConst/       -- AttributeConfig.gd (enum only)
        AttributeSysscript/   -- Core logic: Attribute, AttributeBuff, AttributeSet, AttributeModifier
        AttributeSysscript/BuffEffect/ -- E_AttributeModify, E_Damage
        AttributeSysresource/ -- Attribute presets: AttackAttribute, HealthAttribute
        AttributeSysscene/component/ -- AttributeComponent, BuffManager
      BattleActor/            -- BattleActor, Player.gd (MainPlayer), base_enemy.gd
      BattleSystem/           -- BattleManager, BulletManager
      GameplayFlow/           -- GameplayFlowBase, FlowRegistry, FlowEffect (lifecycle scripts)
        FlowEffect/           -- FE_Damage, FE_SpawnVfx, FE_ApplyBuff, FE_ModifyAttribute, FE_SpawnEntity
      SkillSystem/            -- SkillBase, SkillManager, SkillRegistry, SkillEffect
        SkillEffect/          -- SE_Projectile, SE_AreaEffect, SE_BuffApply, SE_Damage, SE_Heal
      VfxSystem/              -- VfxManager, VfxConfig (visual effects pooling)
      EnemySystem/            -- EnemyFactory, EnemyConfigLoader, EnemySpawnData (data-driven enemies)
      DropSystem/             -- DropManager, DropCalculator (data-driven drops)
      WeaponScripts/          -- WeaponBase, Weapon_Bow, Weapon_Crossbow, Weapon_Bottle, WeaponConfig
    GameDataBase/             -- DataManager (DataRegistry), DataAutoScanner
    LevelSystemBase/          -- Legacy DropManager location
    UIBase/                   -- UIManager, MainUI, PopDamageWidget
  Actor/                      -- InteractionShow, PokerBar, SuperJump
  Interface/                  -- BodyArea, CanPickUp, DropDisplay, WeaponEnergy
  GameModeScript/             -- Main.gd
  ai/
    HSM&BT/Stats/             -- LimboHSM states: Idle, Move, Jump, Hurt, Die
    tasks/                    -- BT tasks: GetFirstInGroup, InRangeOf, PursureTarget

Scene/                        -- (was Sceen/, typo fixed)
  TestScene.tscn              -- Current main scene
  Main.tscn                   -- Alternative test scene
  SuperJump.tscn              -- Jump pad

prefab/
  Buffs/                      -- AttributeBuff .tres resources
  Skills/                     -- SkillBase .tres resources (new)
  Flows/                      -- GameplayFlowBase .tres resources (new)
  Vfx/                        -- Visual effect scenes (new)
  Component/                  -- WeaponRoot, MoveComponent, HurtDisplayComponent
  Enemy/                      -- base_enemy, First_Enemy, Second_Enemy, DamageTestEnemy
  Item/                       -- Poker, CanPickUp, Card, DropDisplay
  Player/                     -- First_Player (autoload), PlayerBase
  Weapon/                     -- Bow/, Bottle/, Crossbow/, EnemyWeapon/

ManagerScene/                 -- DropManager, BulletManager, MainUI
Tables/                       -- Excel/, Json/
art/                          -- GameplayArtResource, UIResource
addons/                       -- limboai, buffresourceplugin, battleresourceeditor
```

### Addons

- **`limboai`** — Provides `LimboHSM` (player FSM) and `BehaviorTree` (enemy AI).
- **`buffresourceplugin`** — Editor plugin for authoring `AttributeBuff` resources.
- **`battleresourceeditor`** — Editor tooling for battle resources.

### Physics Layers

| Layer | Name |
|-------|------|
| 1 | 地面 (Ground) |
| 2 | 子弹阻挡 (Bullet block) |
| 13 | 身体碰撞箱 (Body hitbox) |

### Input Actions

`left`/`right` → A/D, `jump` → Space, `fire` → Mouse LMB, `interaction` → F, `test` → Q

## MCP Servers

The project has MCP servers configured in `.mcp.json`:

- **filesystem MCP** — Read project files, JSON data tables, .godot metadata
- **Excel MCP** — Read Tables/Excel/ .xlsx files directly

## Naming Conventions

- **class_name**: PascalCase (e.g., `WeaponBase`, `MainPlayer`, `PopDamageWidget`)
- **Methods**: snake_case (e.g., `buff_execute()`, `hurt_somebody()`)
- **Variables**: snake_case (e.g., `under_control`, `current_energy`)
- **Signals**: snake_case (e.g., `weapon_fired`, `attribute_changed`)

## Godot Best Practices

### Autoload Singletons

**重要规则：Autoload 脚本不应使用 `class_name`**

- Autoload 名称（在 `project.godot` 中定义）本身就是全局访问名称
- 使用 `class_name` 与 autoload 同名会导致解析错误："Class X hides an autoload singleton"
- 正确做法：autoload 脚本只使用 `extends`，不加 `class_name`

```gdscript
# 错误 ✗
class_name DataRegistry extends Node  # 与 autoload DataRegistry 冲突

# 正确 ✓
extends Node
## Autoload: DataRegistry
## 用法: DataRegistry.method() 或 DataRegistry.instance.method()

# 单例实例（不使用类型声明，因为是 autoload）
static var instance

func _init():
    instance = self
```

**注意：`static var instance` 不应使用类型声明**

- 使用 `static var instance: TypeName` 会在某些情况下导致解析问题
- 正确做法：`static var instance` 不加类型注解，在 `_init()` 中赋值为 `self`

### 检查属性是否存在

- 使用 `object.get("property") != null` 检查属性存在
- 不要使用 `object.has("property")`（`has` 检查的是方法/字典键，不是属性）

```gdscript
# 错误 ✗
if weapon.has("owner_actor"):
    weapon.owner_actor = owner

# 正确 ✓
if weapon.get("owner_actor") != null:
    weapon.owner_actor = owner
```

### 信号连接

- 连接信号前检查是否已连接，避免重复连接错误
- 使用 `is_connected(signal_name, callable)` 检查

```gdscript
# 正确 ✓
if not weapon.is_connected("weapon_fired", Callable(target, "method")):
    weapon.connect("weapon_fired", Callable(target, "method"))
```

### LimboHSM 状态方法

- LimboHSM 状态使用 `_enter()`, `_exit()`, `_update()` 方法
- 不要使用 `_on_entered()`, `_on_exited()`（这些不会被 LimboHSM 调用）