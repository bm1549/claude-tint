---
description: Configure claude-tint colors interactively
allowed-tools: Read, Bash, AskUserQuestion
---

You are configuring the `claude-tint` plugin. Walk the user through each of the three tint colors one at a time. For each color, show it live in the terminal before asking them to confirm. Do not write anything to `~/.claude/settings.json` until all three colors are confirmed.

## Step 1: Detect current state

Read `~/.claude/settings.json` and note any existing `CLAUDE_TINT_*` values in the `env` block. These are the starting values for each color (fall back to the plugin defaults if not set):

- `CLAUDE_TINT_ACTIVE` default: `#2a2e4a`
- `CLAUDE_TINT_QUESTION` default: `#3e3825`
- `CLAUDE_TINT_IDLE` default: unset (reset to terminal default via OSC 111)

Briefly tell the user what's currently configured.

## Step 2: Configure Idle color

The idle state is what the terminal shows when Claude is done responding and waiting for input.

Use AskUserQuestion with these options:

- **Reset to terminal default** (recommended) — emits OSC 111; the bg snaps back to whatever your terminal is configured to show. Works on most terminals.
- **Subtle dark** — `#1e1e1e`
- **Subtle warm** — `#261e1e`
- **Keep current** — only show this if there's already a value set
- **Custom hex** — user will type their own

After the user picks:
- If they chose "Reset to terminal default", emit `printf '\033]111\007' > /dev/tty` to show what it looks like (it will just look like their normal terminal).
- If they chose a hex, emit it: `printf '\033]11;<hex>\007' > /dev/tty`
- Then ask: **"Does this look right for your idle state?"** Options: "Yes, use this" / "No, pick again"
- If they want to pick again, loop back to the top of this step.
- Once confirmed, store the value (or "reset" for the default behavior).
- Reset the bg before moving on: `printf '\033]111\007' > /dev/tty`

## Step 3: Configure Active color

The active state shows while Claude is working on a response.

Use AskUserQuestion with these options:

- **Subtle blue** — `#2a2e4a` (plugin default, good for dark terminals near `#282c34`)
- **Bold blue** — `#2c3260`
- **Subtle green** — `#1e2a1e`
- **Subtle purple** — `#2a1e3a`
- **Keep current** — only show this if there's already a value set
- **Custom hex** — user will type their own

After the user picks, emit the color: `printf '\033]11;<hex>\007' > /dev/tty`

Then ask: **"Does this look right for the active state?"** Options: "Yes, use this" / "No, pick again"

If they pick "Custom hex", ask them to type a hex value in `#rrggbb` format. Validate it matches `^#[0-9a-fA-F]{6}$` before emitting; if invalid, re-prompt.

If they want to pick again, loop back to the top of this step.

Once confirmed, store the value. Reset the bg before moving on: `printf '\033]111\007' > /dev/tty`

## Step 4: Configure Question color

The question state shows when Claude is calling `AskUserQuestion` or waiting for a permission prompt — Claude is blocked waiting for the user.

Use AskUserQuestion with these options:

- **Subtle yellow** — `#3e3825` (plugin default)
- **Bold amber** — `#4a3a1a`
- **Subtle orange** — `#3a2a1e`
- **Subtle teal** — `#1e3a3a`
- **Keep current** — only show this if there's already a value set
- **Custom hex** — user will type their own

After the user picks, emit the color: `printf '\033]11;<hex>\007' > /dev/tty`

Then ask: **"Does this look right for the question state?"** Options: "Yes, use this" / "No, pick again"

Same custom hex validation and loop-back logic as step 3.

Once confirmed, store the value. Reset the bg before moving on: `printf '\033]111\007' > /dev/tty`

## Step 5: Write to settings.json

All three colors are confirmed. Use Python via Bash to write them safely:

```bash
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home() / ".claude" / "settings.json"
data = json.loads(p.read_text()) if p.exists() else {}
env = data.setdefault("env", {})

# Substitute the confirmed values before running this script
active = "<confirmed-active-hex>"
question = "<confirmed-question-hex>"
idle = "<confirmed-idle-hex-or-empty>"  # empty string means reset

env["CLAUDE_TINT_ACTIVE"] = active
env["CLAUDE_TINT_QUESTION"] = question
if idle:
    env["CLAUDE_TINT_IDLE"] = idle
else:
    env.pop("CLAUDE_TINT_IDLE", None)

p.write_text(json.dumps(data, indent=2) + "\n")
PY
```

Do not use the Edit tool — JSON shape varies and Edit is fragile without a guaranteed anchor string.

## Step 6: Report

Summarize what was written in a short table. Tell the user:
- Changes take effect on the next Claude Code session (restart or `/exit` + relaunch).
- Run `/claude-tint:setup` again any time to change colors.
