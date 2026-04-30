---
description: Reset claude-tint colors to plugin defaults
allowed-tools: Bash
---

Remove any `CLAUDE_TINT_*` env vars from `~/.claude/settings.json` so the plugin falls back to its built-in defaults (`#292d3e` active, `#2e2b27` question, OSC 111 reset for idle).

Run this Python snippet via Bash:

```bash
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home() / ".claude" / "settings.json"
data = json.loads(p.read_text()) if p.exists() else {}
env = data.get("env", {})
for key in ["CLAUDE_TINT_ACTIVE", "CLAUDE_TINT_QUESTION", "CLAUDE_TINT_IDLE"]:
    env.pop(key, None)
p.write_text(json.dumps(data, indent=2) + "\n")
PY
```

Then tell the user the reset is done and defaults are restored. No confirmation needed — this is non-destructive since `/claude-tint:setup` can reconfigure at any time.
