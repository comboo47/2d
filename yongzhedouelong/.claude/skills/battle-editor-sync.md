# Battle Editor Sync Skill

Use this Claude-specific skill when game asset data structures change and the custom Battle Editor must stay in sync.

## Trigger Conditions

- A Skill, Buff, or Enemy JSON config gains, removes, or renames a field.
- `SkillBase`, `AttributeBuff`, or related Resource scripts add exported fields that should be visible in editor workflows.
- Data structures used by `addons/battleeditor/` change in a way that affects generated defaults.

## Workflow

1. Inspect the requested data change and identify the affected runtime consumer.
2. Check `addons/battleeditor/UI/BattleEditorPanel.gd` for JSON default templates and creation paths.
3. Update Skill, Buff, or Enemy templates only where the editor owns generated JSON defaults.
4. Update `Docs/ASSETS_DATA.md` with field definitions and examples when public data shape changes.
5. Report which runtime files, editor templates, and docs changed.

## Current Sync Targets

| Change type | Primary target |
| --- | --- |
| Skill JSON fields | `addons/battleeditor/UI/BattleEditorPanel.gd` |
| Buff JSON fields | `addons/battleeditor/UI/BattleEditorPanel.gd` |
| Enemy config fields | `addons/battleeditor/UI/BattleEditorPanel.gd` |
| Resource `@export` fields | Usually discovered by the Godot Inspector; verify before adding manual sync code |

## Notes

- Avoid hard-coded line-number assumptions; search for the relevant template or creation method.
- Keep reusable, tool-neutral rules in `AGENTS.md`.
- Do not commit `.claude/settings.local.json`; it is a local permissions and MCP configuration file.
