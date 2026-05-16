# AGENTS.md

This is the shared AI development guide for this Godot project. Prefer this file as the source of truth for Codex, Claude, Cursor, and other coding agents.

## Project

- Project name: `Yongzhedouelong`
- Engine: Godot 4.6
- Type: 2D pixel-art action shooter
- Viewport: 384x240 with integer scaling
- Main project file: `project.godot`
- Main scene is configured in `project.godot`; do not hard-code scene entrypoints unless a task requires it.

## Common Commands

Run these from the project root, `yongzhedouelong/`.

```powershell
# Run the project if Godot is on PATH
godot --path . project.godot

# Generate data tables after editing Tables/Excel/*.xlsx
cd Tables
.\gen_all.bat
```

There is no general command-line build step for normal development. Most verification is done through Godot Editor, Godot CLI, focused code review, and data-table regeneration when relevant.

## Repository Rules

- Do not commit `.godot/`, local logs, temporary DLL files, local MCP configs, or tool-specific local settings.
- `.godot/` is local cache only. It must stay ignored and untracked.
- `.claude/settings.local.json` is a local Claude configuration file. Keep it ignored and untracked.
- Avoid editing generated `.uid` files directly unless the Godot editor or import process intentionally updates them.
- Avoid broad formatting churn in `.tscn`, `.tres`, `.godot`, or generated JSON files.
- Preserve user changes in the working tree. Never revert unrelated files while doing a task.
- For the human/AI collaboration workflow, read `Docs/AI_COLLABORATION.md`.
- For Godot UI scene handoff between the human editor and AI logic work, read `Docs/UI_COLLABORATION.md`.

## Project Layout

- `Scripts/GameBase/BattleSystemBase/`: combat, actors, attributes, buffs, skills, weapons, vfx, flows, enemy and drop systems.
- `prefab/`: reusable scenes and resources for players, enemies, weapons, buffs, skills, and components.
- `ManagerScene/`: autoload scene managers such as bullet, UI, and drop managers.
- `Tables/Excel/`: source spreadsheets for data.
- `Tables/Json/`: generated data consumed by runtime loaders.
- `Docs/BattleSystem/`: design notes for major battle systems.
- `addons/battleeditor/`: custom battle data editor.
- `addons/limboai/`: LimboAI addon used for behavior trees and HSM.

## Architecture Notes

- Autoloads are declared in `project.godot` under `[autoload]`; check that section before adding new global dependencies.
- Attributes and buffs are data-driven resources under the AttributeSystem. Runtime actor instances must use duplicated resources, not shared mutable resource state.
- Buff resources live under `prefab/Buffs/` and are registered by `DataAutoScanner` / `DataRegistry`.
- Skill resources live under `prefab/Skills/` and are registered by `SkillRegistry`.
- Gameplay flows are reusable resources executed through `FlowRegistry` and `BattleManager` flow APIs.
- Weapons emit `weapon_fired`; `WeaponRoot` connects weapons to `BulletManager`.
- Enemies use LimboAI behavior trees; player state uses LimboHSM.

## Data And Editor Sync

When changing Skill, Buff, or Enemy JSON structures:

- Update the runtime loader/consumer code.
- Update the custom battle editor templates in `addons/battleeditor/UI/BattleEditorPanel.gd` if new fields should appear in generated JSON.
- Update `Docs/ASSETS_DATA.md` when field definitions or examples change.
- Run `Tables/gen_all.bat` after changing source Excel files.

When adding `@export` fields to Godot Resources, first check whether the editor UI already discovers them through the Inspector before adding manual sync code.

## Verification Checklist

Use the smallest useful verification for the task:

- `git status --short`
- `git diff --check`
- Godot CLI run when available: `godot --path . project.godot`
- Data generation after table edits: `Tables/gen_all.bat`
- Manual Godot Editor check for scene, resource, or plugin UI changes.

## Claude Compatibility

`CLAUDE.md` is kept for Claude Code compatibility. Keep long-lived, tool-neutral guidance here in `AGENTS.md`; mirror only Claude-specific summaries into `CLAUDE.md` when necessary.
