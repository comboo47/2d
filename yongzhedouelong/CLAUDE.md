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
| `BattleManager` | `Scripts/GameBase/BattleSystemBase/BattleSystem/BattleManager.gd` | Static utility methods for applying/removing buffs, combat operations |
| `DataRegistry` | `Scripts/GameBase/GameDataBase/DataManager.gd` | Registry for `AttributeBuff` resources, keyed by `buff_id` |
| `DataAutoScanner` | `Scripts/GameBase/GameDataBase/DataAutoScanner.gd` | On startup, scans `res://prefab/Buffs/` and registers all `.tres` buff resources |
| `DropManager` | `ManagerScene/drop_manager.tscn` | Handles item/poker drops from enemies |
| `BulletManager` | `ManagerScene/bullet_manager.tscn` | Manages bullet instantiation and lifecycle |
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
      WeaponScripts/          -- WeaponBase, Weapon_Bow, Weapon_Crossbow, Weapon_Bottle
    GameDataBase/             -- DataManager (DataRegistry), DataAutoScanner
    LevelSystemBase/          -- DropManager
    UIBase/                   -- MainUI, PopDamageWidget
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