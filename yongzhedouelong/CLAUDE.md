# CLAUDE.md

This file is kept for Claude Code compatibility.

The shared, tool-neutral AI development guide for this project is:

- `AGENTS.md`

Claude-specific behavior:

- Read `AGENTS.md` before making code or asset changes.
- Keep reusable project rules in `AGENTS.md`, not here.
- Do not commit `.claude/settings.local.json`; it is local permissions and MCP configuration.
- Use `.claude/skills/battle-editor-sync.md` only for Claude-specific Battle Editor sync reminders.

For architecture details, prefer the maintained project docs:

- `Docs/BattleSystem/Architecture.md`
- `Docs/BattleSystem/WeaponSystem.md`
- `Docs/BattleSystem/SkillSystem.md`
- `Docs/BattleSystem/BulletSystem.md`
- `Docs/BattleSystem/UISystem.md`
