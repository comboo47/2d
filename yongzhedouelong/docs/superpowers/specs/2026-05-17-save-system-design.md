# Save System Design

## Purpose

Build the first version of the player progress save system for `Yongzhedouelong`. This version saves long-term progression, not an in-battle resume state.

The system should let the game remember campaign and level progress across launches, unlock new levels after completion, record earned rewards, and reset progress for testing or future menu support.

## Scope

This design covers a single automatic progress save. It does not include multiple save slots, manual save/load UI, battle-state persistence, enemy persistence, player position persistence, or mid-level resume.

The first implementation should be small enough to validate the storage format, public API, and integration points before the game has a complete progression economy.

## Architecture

Add a `SaveManager` autoload that owns all save-file access. Other systems call `SaveManager` methods and never read or write the save file directly.

`SaveManager` stores one JSON file at:

```text
user://save/progress.json
```

On startup, `SaveManager` loads the file if it exists. If the file is missing, unreadable, malformed, or on an unsupported schema version, it falls back to a default progress dictionary. The fallback should not crash the game.

The first integration point is progression completion, not scene loading. `GameManager`, level flow code, or a future level-complete reward flow can call `mark_level_completed()` or `unlock_level()` after a level is completed or a reward is accepted.

## Save Data

Use a dictionary-based JSON schema for version 1:

```json
{
  "schema_version": 1,
  "current_level_id": "",
  "completed_levels": [],
  "unlocked_levels": [],
  "rewards": {},
  "updated_at": ""
}
```

Field meanings:

- `schema_version`: integer schema version for future migrations.
- `current_level_id`: the latest selected or completed level id.
- `completed_levels`: unique list of completed level ids.
- `unlocked_levels`: unique list of playable level ids.
- `rewards`: dictionary keyed by reward id or resource id. Values remain flexible for now because the long-term economy is not final.
- `updated_at`: timestamp string used for debugging and future save-slot displays.

The default progress should include `schema_version = 1`, empty progress arrays, an empty rewards dictionary, and an empty `current_level_id`.

## Public API

`SaveManager` should expose these methods:

```gdscript
func load_progress() -> Dictionary
func save_progress(progress: Dictionary) -> bool
func get_progress() -> Dictionary
func mark_level_completed(level_id: String, rewards: Dictionary = {}) -> bool
func unlock_level(level_id: String) -> bool
func reset_progress() -> bool
func has_save() -> bool
```

Expected behavior:

- `load_progress()` loads from disk and updates the in-memory progress.
- `save_progress(progress)` validates and writes progress to disk, returning whether the write succeeded.
- `get_progress()` returns a duplicate of the in-memory progress so callers cannot mutate internal state accidentally.
- `mark_level_completed()` adds the level id to `completed_levels`, updates `current_level_id`, merges reward data, and writes the file.
- `unlock_level()` adds the level id to `unlocked_levels` and writes the file.
- `reset_progress()` removes or overwrites the existing save with default progress and writes the file.
- `has_save()` reports whether the save file exists.

Duplicate level ids should not be added twice.

## Error Handling

Recoverable read errors should use `push_warning()`. Write failures should use `push_error()`. Neither case should block the game from reaching the main menu.

If a save file cannot be parsed, `SaveManager` should keep the malformed file untouched for this first version and continue with default in-memory progress. This version does not create repair files or backups.

If writing fails, the mutating API should return `false`. First-version UI does not display write failures.

## Integration

Register `SaveManager` in `project.godot` under `[autoload]`.

Keep the first code integration narrow:

- Load progress automatically when `SaveManager` enters the tree.
- Keep `GameManager` focused on scene and state transitions.
- Add explicit calls from level-complete or reward-acceptance logic once that flow exists.
- Do not add save-slot UI in this version.

The reset API exists for tests and menu wiring. Any menu reset button should call `SaveManager.reset_progress()` rather than deleting files itself.

## Testing

Add focused headless tests for the save system:

- Missing save file returns default progress.
- Saving progress writes JSON to disk.
- Loading after saving restores the same progress.
- Completing the same level twice keeps one entry.
- Unlocking the same level twice keeps one entry.
- Resetting progress returns to default data.
- Malformed JSON falls back to default progress without crashing.

Use an isolated test path or injectable save path so tests do not overwrite a developer's real `user://save/progress.json`.

## Open Decisions Resolved

- Save scope: progress save only.
- Slot strategy: single automatic save.
- Data priority: campaign, level, unlock, and reward progress.
- Timing: load on startup; save on completion or reward acceptance.
- Architecture: dedicated `SaveManager` autoload.
- Reset behavior: include `reset_progress()` in version 1.
