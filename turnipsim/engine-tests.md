---
name: engine-tests
description: Use when the user says "run tests", "run the suite", "run engine tests", or similar. Runs the turnipsim headless Godot test suites (tests/test_game_engine.gd and tests/test_runner.gd) with platform-detected Godot path and reports a compact pass/fail summary. NOT for scripts/test-stack.sh, which is manual-play, not tests.
---

# engine-tests skill

Run the two headless test suites and report a summary.

## Platform detection

```bash
if [[ -x "/c/tools/Godot/Godot_v4.6.2-stable_win64.exe" ]]; then
  GODOT="/c/tools/Godot/Godot_v4.6.2-stable_win64.exe"
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
else
  echo "Godot binary not found for this platform" >&2
  exit 1
fi
```

## Commands

From the turnipsim repo root:

```bash
"$GODOT" --headless --path godot -s tests/test_game_engine.gd
"$GODOT" --headless --path godot -s tests/test_runner.gd
```

Each runner prints a final `Passed: N / Failed: M` line. Parse those.

## Output shape

```
<engine_total> engine + <types_total> types = <grand_total> total, <failing> failing
```

If failures exist, list only the FAIL lines from the output (grep `^FAIL` or similar) — do not dump the full log.

## Rules
- **Never** run `scripts/test-stack.sh` and call it a test run — it launches a manual-play stack (headless server + windowed clients), not tests.
- If the Godot binary isn't found, surface that plainly and stop; do not try to install Godot.
- Both suites must be run — don't skip one because the other passed.
- Run from the turnipsim repo root (the dir containing `godot/` and `scripts/`).
