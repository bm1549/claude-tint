---
description: Reset stuck terminal background color to default
allowed-tools: Bash
---

The terminal background is stuck from an interrupted Claude response. Reset it now by emitting OSC 111:

```bash
printf '\033]111\007' > /dev/tty
```

Then tell the user the background has been reset.
