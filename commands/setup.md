---
description: Configure claude-tint colors and presets
allowed-tools: Read, Edit, Write, Bash, AskUserQuestion
---

You are configuring the `claude-tint` plugin for the user. The plugin tints the terminal background based on Claude Code state via env vars: `CLAUDE_TINT_ACTIVE`, `CLAUDE_TINT_QUESTION`, `CLAUDE_TINT_IDLE`.

## Step 1: Detect terminal and current state

Read `~/.claude/settings.json` and inspect the `env` block for any existing `CLAUDE_TINT_*` values. Report what's currently set, or "using defaults" if none.

If `$TERM_PROGRAM` is set (run `echo "$TERM_PROGRAM"` via Bash), report it so the user knows which terminal you detected. Common values: `ghostty`, `iTerm.app`, `Apple_Terminal`, `WezTerm`. If unknown, ask the user.

## Step 2: Pick a preset

Use AskUserQuestion to offer four presets, plus a custom path. Each preset sets `CLAUDE_TINT_ACTIVE` and `CLAUDE_TINT_QUESTION`; `CLAUDE_TINT_IDLE` is left empty by default (uses OSC 111 reset).

| Preset | Active | Question | Notes |
|--------|--------|----------|-------|
| Subtle (recommended) | `#2a2e4a` | `#3e3825` | Barely visible; matches a typical dark default like `#282c34` |
| Bold | `#2c3260` | `#4a3a1a` | Clearly visible blue / yellow |
| Cool tones | `#1e2a3e` | `#2a3a2e` | Blue / green instead of yellow |
| Warm tones | `#3a2a1e` | `#3e3825` | Red-orange / yellow |
| Custom | (ask)  | (ask)    | User provides hex values |

If the user picks Custom, ask for each color hex with AskUserQuestion. Offer 3-4 sensible suggestions as options; the user can pick "Other" to type their own hex. Validate that any custom input matches `#[0-9a-fA-F]{6}` before continuing; if invalid, re-prompt.

## Step 3: Idle behavior

Ask whether the user wants `CLAUDE_TINT_IDLE`:
- Default (unset) — emit OSC 111 to reset to terminal default. Best for most terminals.
- Explicit hex — set a specific idle color. Useful if the user's terminal doesn't honor OSC 111 (some older Alacritty builds).

If they pick explicit, ask for the hex.

## Step 4: Preview each color and confirm

Before writing anything to disk, show the user each color live so they can see how it looks against their actual terminal config. For each of `CLAUDE_TINT_ACTIVE`, `CLAUDE_TINT_QUESTION`, and (only if explicitly set) `CLAUDE_TINT_IDLE`:

1. Emit the color via OSC 11 to `/dev/tty`:
   ```bash
   printf '\033]11;<hex>\007' > /dev/tty
   ```
2. Ask the user via AskUserQuestion: "Does this <state-name> color look right? Background should now be tinted <hex>." Options: "Looks good", "Pick a different color".
3. If they want a different color, loop back to step 2 (preset) or step 3 (idle) for that specific value and re-preview. Do not proceed until they confirm.

After each preview, immediately reset the bg to avoid leaving a stuck tint:
```bash
printf '\033]111\007' > /dev/tty
```

If the user chose default (unset) for idle, skip the idle preview entirely.

## Step 5: Write to settings.json

The settings file is JSON, and the existing `env` block may or may not exist. Use Python via Bash to mutate it safely without risking malformed edits:

```bash
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home() / ".claude" / "settings.json"
data = json.loads(p.read_text()) if p.exists() else {}
env = data.setdefault("env", {})
# Set or remove each var based on user choice. Pass values in via os.environ
# from the shell, or substitute them into this script before running.
env["CLAUDE_TINT_ACTIVE"] = "<chosen-active-hex>"
env["CLAUDE_TINT_QUESTION"] = "<chosen-question-hex>"
# For idle: only set if user explicitly chose a hex; otherwise pop it
if "<chosen-idle>" and "<chosen-idle>" != "default":
    env["CLAUDE_TINT_IDLE"] = "<chosen-idle-hex>"
else:
    env.pop("CLAUDE_TINT_IDLE", None)
p.write_text(json.dumps(data, indent=2) + "\n")
PY
```

Substitute the user's actual hex values into the script before running. Do not use the Edit tool here — JSON shape varies and Edit's exact-string match is fragile against missing `env` blocks or trailing-comma differences.

## Step 6: Report

Summarize what was set, in a table or bullet list. Tell the user that:
- Changes apply on next Claude Code session start.
- They can re-run `/claude-tint:setup` any time to change.
- For unknown limitations or troubleshooting, point them at the [README](https://github.com/bm1549/claude-tint).

Do not modify anything outside the `env` block. Do not touch hooks, permissions, or other settings keys.
