---
description: Reset stuck terminal background color to default
allowed-tools: Bash
---

The terminal background is stuck from an interrupted Claude response. Reset it now:

```bash
~/.claude/plugins/marketplaces/claude-tint/hooks/tint.sh idle
```

Then tell the user the background has been reset.
