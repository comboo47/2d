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

The unifying protocol (`src/gameplay/flows/`, `core/`, `damage/`, `effects/`). Levels, skills, and buffs all drive logic through the same pieces — prefer this over older bespoke systems:

- **Flow = a Duration/Trigger/Action node tree run by a per-instance interpreter (第十三期).** A `FlowGraph` (`src/gameplay/flows/graph/`) holds `durations: Array[FlowDuration]` (main line, serial). A `FlowDuration` is a lifetime shell (`LifetimeMode` INSTANT/FRAMES/SECONDS/FOREVER) holding parallel `children` — `FlowTrigger` (a persistent event listener with `EndMode` ONCE/COUNT/NEVER, fires its `actions` and may `finish_parent`) and `FlowAction` (instant: `action_name`+`opts` dispatched to the static `FlowActions` library, or a `FlowLeaf` script for computation like bow-charge lerp). `FlowInterpreter` (`extends RefCounted`, per-host, **not** an autoload and **not** subscribed to any bus) drives it: hosts call `start(graph,ctx,host)` / `advance(delta)` (feed frames) / `deliver_event(event)` (bridge events) / `cancel()` (deterministic sync teardown — replaces leak-prone coroutine await); `FlowInterpreter.run_oneshot(graph,ctx,host)` runs a graph to completion for one-shot hosts. The old `GameplayFlowBase` script-class model and `FlowRuntime` autoload were **deleted** in 第十三期; `FlowActions` (the stateless static action implementations) is unchanged and reused by the interpreter and leaves. There is **no `effects` data-assembly array** on flows (the old `FlowEffectBase`/`FE_*` were deleted in 第八期).
- **Effect = logic carried by a buff (`src/gameplay/effects/`).** `EffectBase` with `apply(ctx, buff)`/`remove(ctx, buff)`; subclasses `ModifierEffect` (reversible panel-attribute change via `Attribute` modifier-source stack, keyed by buff runtime id) and `StateEffect` (invincible/stealth/vision, set on apply / cleared on remove). Effects only attach to buffs.
- **Buff = lifecycle data + dual track.** `AttributeBuff` carries `buff_flow` (now a `FlowGraph` node tree, driven by a `FlowInterpreter` the buff hosts — `on_applied`→start, `run_process`→advance, `handle_gameplay_event`→deliver_event, `on_removed`→cancel) **and** `effects: Array[EffectBase]` (applied on add, reverted on remove). The old `event_flows` dict / `BuffEffects` / `attribute_modifier` were removed; `BuffManager.apply_buff/remove_buff` calls `on_applied()/on_removed()`.
- **Attribute layering.** Panel attributes (Atk/Armor/MaxHP/Crit) use `base_value + 修改源栈` → `computed` (never mutated in place; buff/flow push removable sources via `add_modifier_source/remove_modifier_source`). Resource values (current HP/energy) use immediate `add/sub` (damage still routed through DamageResolver).
- `GameplayFlowContext` carries `source`, `target`, `skill`, `buff`, `level`, `gameplay_event`, `damage_request`, `stack`, `event_data`.
- `GameplayEventBus` (`src/gameplay/core/`) is a **static** event bus, intentionally not an autoload, so the core doesn't couple to `project.godot`.
- **Damage never bypasses the resolver:** flow/skill/buff damage builds a `DamageRequest` → `DamageResolver.resolve()` broadcasts `DAMAGE_REQUESTED` (buffs can mutate the request) → evaluates the formula → deducts HP → broadcasts `DAMAGE_APPLIED`. Formulas use a whitelist with helpers `source_attr("Atk")`, `target_attr("Armor")`, `event_value(...)`, `has_tag(...)`. **The resolver is the single chokepoint that judges death and emits the actor lifecycle:** after deducting HP it broadcasts `ACTOR_HIT` (damage>0, carries source), `ACTOR_DIED` (HP≤0, killer in event_data) and `ACTOR_KILL` (lethal blow with a source), and drives `BattleActor.kill()` → `_on_death()`. All damage funnels through it (`FlowActions.deal_damage` and `modify_attr` for Hp-SUB); self-cost like skill HP sacrifice does not. The old `BattleActor` `actor_*` signals are deleted — everything goes through `GameplayEventBus`. See `Docs/BattleSystem/GameplayRuntimeCore.md` and `GameplayLifecycle.md`.

Event-driven buffs: a buff's `buff_flow` is driven by the buff's own lifecycle — `BuffManager` fires `BUFF_TICK` per `buffPeriod`, and the buff forwards bus/lifecycle events to its interpreter via `deliver_event` (a FOREVER Duration + `FlowTrigger(BUFF_TICK, NEVER)` → `deal_damage` is the burn/DoT pattern). (`LevelDefinition.event_flows` is unrelated — that's level-lifecycle, now a `{EventType → FlowGraph[]}` map run via `FlowInterpreter.run_oneshot`.)

### Data-driven resources + registries

Gameplay content is `.tres` resources scanned at startup (autoloads in `project.godot`):

- `DataAutoScanner` / `DataRegistry` (`src/gameplay/data/`) — buffs, scanning `res://resources/gameplay/buffs/`.
- `SkillRegistry` — `res://resources/gameplay/skills/`.
- `FlowRegistry` (`GameplayFlowRegistry`) — `res://resources/gameplay/flows/`.
- Levels/campaign/enemies live under the sibling `resources/gameplay/` folders.

Skills reference flows by `graph_refs: Array[FlowGraph]` (direct) or `on_use_flow_id` (looked up via `/root/FlowRegistry`, which now caches `FlowGraph` templates and returns `deep_duplicate()` copies).

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
