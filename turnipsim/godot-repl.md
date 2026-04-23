---
name: godot-repl
description: Use when the user asks to "check what X returns", "sanity-check this function", "run a quick snippet against the engine", or similar one-off verification that doesn't warrant a full test. Writes a throwaway tests/scratch_*.gd extending SceneTree, runs it headless, returns the printed output + exit code, then deletes the file. Lower priority — use only when a real test would be overkill.
---

# godot-repl skill

Run a one-off GDScript snippet against the turnipsim engine without polluting the test suite.

## Steps

1. **Platform detect** the Godot binary (same as `engine-tests` skill).
2. **Generate a timestamped scratch file** at `godot/tests/scratch_<unix_epoch>.gd`:
   ```gdscript
   extends SceneTree

   func _init():
       # <user's snippet here>
       # Preload game modules the snippet needs, e.g.:
       # var types = preload("res://game/types.gd")
       # var engine = preload("res://server/game_engine.gd").new()
       print("<result>")
       quit()
   ```
3. **Run headless**:
   ```bash
   "$GODOT" --headless --path godot -s tests/scratch_<epoch>.gd
   ```
4. **Capture** stdout + exit code.
5. **Delete** the scratch file unconditionally (even on failure) — these are a lint hazard if left behind.
6. **Report** only the printed output + exit code. Do not dump Godot boot logs.

## Rules
- Never leave scratch files behind. Use `trap` or explicit `rm` in a `finally`-equivalent.
- Do not `git add` the scratch file. Do not commit it.
- If the snippet needs more than ~30 lines, suggest writing a proper test in `tests/test_game_engine.gd` instead — this skill is for quick checks, not real testing.
- Respect the pure-RefCounted contract: snippets that instantiate Nodes are a smell; reconsider what's being tested.
- If the user runs this skill frequently for the same behavior, suggest promoting it to a real test.
