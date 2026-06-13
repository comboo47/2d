# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Authoritative guides

`AGENTS.md` is the shared, tool-neutral development guide — read it before code or asset changes. Workflow specifics live in `Docs/AI_COLLABORATION.md` (human/AI collaboration) and `Docs/UI_COLLABORATION.md` (human-editor → AI-logic UI handoff).

Do not commit `.claude/settings.local.json` (local permissions/MCP config).

The live code is under `src/`, data tables under `data/tables/`, and gameplay `.tres` resources under `resources/gameplay/`. `AGENTS.md` and `Docs/BattleSystem/*.md` were realigned to this layout. If any path ever conflicts, treat `project.godot` `[autoload]` and the directory map below as authoritative.

## Project

- `Yongzhedouelong` — 2D pixel-art action shooter on **Godot 4.6**.
- Main scene: `res://scenes/ui/menu/MainMenu.tscn` (set in `project.godot`; don't hard-code entrypoints).
- Run from the project root (`yongzhedouelong/`).

## Commands

```bash
# Run the project (if Godot is on PATH)
godot --path . project.godot

# Headless regression tests (exit code 0 = pass; each test prints PASS/FAIL)
godot --headless --path . -s res://tests/GameplayCoreTest.gd            # gameplay core + SaveManager units
godot --headless --path . -s res://tests/GameplayExampleLevelSmokeTest.gd  # full LevelRunner smoke test

# Compile/parse check (loads every script; surfaces parse errors)
godot --headless --editor --path . --quit

# Regenerate data tables after editing data/tables/Excel/*.xlsx
cd data/tables && ./gen_all.bat
```

There is no general CLI build step. `tests/` are plain `extends SceneTree` scripts with no test framework — add a `_test_*` method and register it in `_initialize()`'s `_run(...)` list. Tests isolate side effects (e.g. SaveManager uses `set_save_path_for_tests(...)` to avoid touching real `user://` saves).

> Godot headless may print resource-leak / duplicate-UID noise on exit. Treat it as environment noise as long as tests print PASS and the exit code is 0.

## Architecture

### Gameplay runtime core: Flow → Effect → Context

The unifying protocol (`src/gameplay/flows/`, `core/`, `damage/`). Levels, skills, and buffs all drive logic through the same pieces — prefer this over older bespoke systems:

- `GameplayFlowBase` holds `effects: Array[FlowEffectBase]`, executed in ascending `priority`.
- `GameplayFlowContext` carries `source`, `target`, `skill`, `buff`, `level`, `gameplay_event`, `damage_request`, `stack`, `event_data`.
- `FlowEffectBase` is the base for new effects (`FE_Damage`, `FE_ApplyBuff`, `FE_SpawnEntity`, …). Legacy `SkillEffectBase` / `AttributeBuffEffect` remain only as a compatibility layer.
- `GameplayEventBus` (`src/gameplay/core/`) is a **static** event bus, intentionally not an autoload, so the core doesn't couple to `project.godot`.
- **Damage never bypasses the resolver:** `FE_Damage` builds a `DamageRequest` → `DamageResolver.resolve()` broadcasts `DAMAGE_REQUESTED` (buffs can mutate the request) → evaluates the formula → deducts HP → broadcasts `DAMAGE_APPLIED`. Formulas use a whitelist with helpers `source_attr("Atk")`, `target_attr("Armor")`, `event_value(...)`, `has_tag(...)`. See `Docs/BattleSystem/GameplayRuntimeCore.md`.

Event-driven buffs: `AttributeBuff.event_flows` maps `GameplayEvent.EventType` (e.g. `BUFF_TICK`, `DAMAGE_REQUESTED`) → flows. `BuffManager` fires `BUFF_TICK` per `buffPeriod`.

### Data-driven resources + registries

Gameplay content is `.tres` resources scanned at startup (autoloads in `project.godot`):

- `DataAutoScanner` / `DataRegistry` (`src/gameplay/data/`) — buffs, scanning `res://resources/gameplay/buffs/`.
- `SkillRegistry` — `res://resources/gameplay/skills/`.
- `FlowRegistry` (`GameplayFlowRegistry`) — `res://resources/gameplay/flows/`.
- Levels/campaign/enemies live under the sibling `resources/gameplay/` folders.

Skills reference flows by `flow_refs` (direct) or `on_use_flow_id` (looked up via `/root/FlowRegistry`).

**Runtime actors must duplicate resources, not mutate shared resource state** — attributes/buffs are shared `.tres` assets.

### Actor / combat composition

`BattleActor` (`src/gameplay/actors/`) composes `AttributeComponent` (→ `AttributeSet` → `Attribute`, with derived attributes), `BuffManager`, optional `SkillManager`, and a weapon. Weapons (`src/gameplay/weapons/`) extend `weapon_base`, emit `weapon_fired`; that signal routes to `BulletManager` which spawns bullet scenes. `UIManager` listens to `Attribute.attribute_changed` to update HP bars and pooled damage popups.

### AI

Enemies use **LimboAI** behavior trees (`addons/limboai/`, tasks in `src/gameplay/ai/tasks/`); player/enemy state machines use LimboHSM (`src/gameplay/ai/HSM&BT/`).

### Level orchestration

`LevelDefinition` (initial actors/buffs + `event_flows`) is driven by `LevelRunner.start_level()`: spawns actors, grants initial skills/buffs, then broadcasts `LEVEL_START`.

## Directory map (current)

- `src/app/` — autoload-level managers (`GameManager`, `InputManager`, `SaveManager`, `Main`).
- `src/gameplay/` — `actors`, `ai`, `attributes`, `battle`, `campaign`, `core`, `damage`, `data`, `drops`, `enemies`, `flows`, `levels`, `skills`, `vfx`, `weapons`.
- `src/ui/` — UI managers, `Panel/`, `Widget/`.
- `scenes/` — `.tscn` scenes (`autoload/`, `ui/`, `actors/`, `weapons/`, `items/`, `components/`).
- `resources/gameplay/` — `.tres` data: `buffs`, `skills`, `flows`, `levels`, `enemies`, `campaign`.
- `data/tables/` — `Excel/` sources, generated `Json/`, `gen_all.bat`.
- `addons/` — `limboai`, `battleeditor`, `buffresourceplugin`, MCP editor/runtime, `auto_reload`.
- `tests/` — headless SceneTree tests.

## Data & editor sync

When changing Skill / Buff / Enemy JSON or resource structure: update the runtime loader/consumer, update the battle-editor templates in `addons/battleeditor/UI/BattleEditorPanel.gd` if new fields belong in generated JSON, update `Docs/ASSETS_DATA.md`, and run `data/tables/gen_all.bat` after editing source Excel. For new `@export` fields on Resources, first check whether the Godot Inspector already discovers them before writing manual sync code (see `.claude/skills/battle-editor-sync.md`).

## Repo hygiene

Keep `.godot/`, logs, temp DLLs, and local MCP/editor configs untracked. Avoid broad reformatting of `.tscn`/`.tres`/`.godot`/generated JSON. Don't edit `.uid` files unless Godot regenerates them. Preserve unrelated working-tree changes.
