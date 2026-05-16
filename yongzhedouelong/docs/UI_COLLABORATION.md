# UI Collaboration Workflow

This document defines how the human UI editor and AI coding assistant work together on the Godot UI system.

## Roles

- Human owns UI window editing in Godot: layout, controls, anchors, containers, visual style, art resources, and interaction intent.
- AI owns logic integration: reading saved `.tscn`, `.gd`, and `.tres` files, connecting buttons, adding data binding, updating UI registration, and keeping UI flow consistent.

The default handoff is:

```text
Human edits and saves the UI scene in Godot -> Human tells AI which window changed -> AI reads saved files -> AI implements logic.
```

AI cannot reliably read unsaved changes inside the Godot editor. Save the scene before asking AI to inspect or wire it.

## Human Handoff Format

Use this format when a UI window is ready for AI logic work:

```text
I edited <WindowName>.
Scene path:
res://scenes/ui/<Folder>/<WindowName>.tscn

Please:
1. Read the scene structure.
2. Check important node names.
3. Wire the logic for <buttons/sliders/lists/data binding>.
4. Do not change layout or visual styling unless necessary.
```

A reusable copy-paste template is available at `Docs/UI_HANDOFF_TEMPLATE.md`.

Example:

```text
I edited Settings.
Scene path:
res://scenes/ui/menu/Settings.tscn

Please:
1. Read the scene structure.
2. Check MasterSlider, MusicSlider, SfxSlider, BackButton.
3. Wire the volume and back logic.
4. Do not change layout.
```

When reporting a bug, use this format:

```text
Bug:
Clicking <Window/Button> causes:
<exact Godot error text>

Changed recently:
<scene/script path>
```

## UI Scene Rules

- One UI window should be one scene.
- Root node should usually be `Control`.
- Root node name should match the UI window id, for example `Settings`, `LevelSelect`, `Inventory`.
- Interactive node names should describe intent:
  - `StartButton`
  - `BackButton`
  - `SettingsButton`
  - `ConfirmButton`
  - `MasterSlider`
  - `LevelList`
- Keep key node names stable after AI wires logic.
- If a key node is renamed, tell AI the old and new names.
- Visual layout may change freely as long as wired node names remain available.

## AI Intake Checklist

Before editing UI logic, AI should read:

- The changed `.tscn` scene.
- The attached panel script, if any.
- `Scripts/GameBase/UIBase/UIManager.gd`.
- `Scripts/GameBase/UIBase/UIConfig.gd`.
- `Scripts/GameBase/GameManager.gd` when scene flow, pause, loading, or gameplay state is involved.

AI should avoid broad `.tscn` rewrites. It should prefer script-only changes unless scene registration, script attachment, or missing nodes require scene edits.

## Logic Ownership

Panel scripts own only local UI behavior:

- Find child controls.
- Connect button and slider signals.
- Update labels, lists, bars, and simple local display.
- Emit actions through `panel_action` or call the agreed manager API when the current system requires it.

`UIManager` owns UI display state:

- Open and close screens.
- Maintain screen history.
- Show and hide popups.
- Show and hide overlays such as loading.
- Show and hide HUD.
- Register UI scenes.

`GameManager` owns game state:

- Main menu.
- Loading.
- Playing.
- Paused.
- Returning to main menu.
- Scene switching.

Pause state should be controlled by `GameManager`, not by arbitrary panels.

## Target UI Categories

Use these categories when planning new UI:

- `Screen`: full menu page, such as main menu, settings, level select, inventory, result.
- `Popup`: modal confirmation or short blocking dialog.
- `Overlay`: loading screen, transition mask, global fade.
- `HUD`: battle HUD and player-facing gameplay UI.
- `Widget`: reusable small UI element such as damage number, HP bar, toast.

## Current Project Paths

- UI scenes: `res://scenes/ui/`
- UI scripts: `res://src/ui/`
- UI panels: `res://src/ui/Panel/`
- UI manager: `res://src/ui/UIManager.gd`
- UI config: `res://src/ui/UIConfig.gd`
- Game state: `res://src/app/GameManager.gd`

## Verification

For UI logic changes, AI should run or request the smallest useful checks:

- `git diff --check`
- Read the changed scene and script paths.
- Godot editor manual test when CLI is not available.
- Godot CLI test when available:

```powershell
godot --path . project.godot
```

Manual UI smoke test:

- Open the edited window.
- Click every newly wired button.
- Trigger `Back` or `Close`.
- Check pause state if the window is opened from gameplay.
- Check Godot Output and Debugger for red errors.
