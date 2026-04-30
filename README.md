# claude-ghostty-tint

A Claude Code plugin that tints your terminal background based on what Claude is doing.

| State | Default tint | When |
|-------|--------------|------|
| **Active** | `#2a2e4a` (blue) | You sent a message and Claude is working |
| **Question** | `#3e3825` (yellow) | Claude is calling `AskUserQuestion` and waiting on you |
| **Idle** | terminal default | Claude finished responding, or session ended |

Built for [Ghostty](https://ghostty.org/), but works in any terminal that supports the standard `OSC 11` escape sequence (iTerm2, kitty, alacritty, wezterm, xterm).

## Why

When you're alt-tabbed away or have a long-running turn, you can't tell at a glance whether Claude is still working, finished, or waiting on a question. A subtle background tint gives you that signal without taking up screen space.

## Install

```
/plugin marketplace add bm1549/claude-ghostty-tint
/plugin install claude-ghostty-tint@claude-ghostty-tint
```

That's it. Restart Claude Code (or start a new session) and the tints will activate.

## Configuration

Override any of the three colors via env vars in your Claude Code `settings.json`:

```json
{
  "env": {
    "CLAUDE_TINT_ACTIVE": "#1a2a4a",
    "CLAUDE_TINT_QUESTION": "#4a3a1a",
    "CLAUDE_TINT_IDLE": ""
  }
}
```

- Leave `CLAUDE_TINT_IDLE` unset (or empty) to reset to your terminal's default background, which is usually what you want.
- Set it to a hex color if you want idle to be a specific tint instead of the terminal default.

### Picking colors

Aim for hex values close to your terminal's default brightness, with one channel pushed up. Going too dark reads as "screen dimmed" rather than "tinted."

For Ghostty's stock dark default (`#282c34`):
- Subtle blue: `#2a2e4a`
- Obvious blue: `#2c3260`
- Subtle red: `#3a1a1a`
- Subtle yellow: `#3e3825`
- Subtle green: `#1a3a25`

## Known limitation: ESC interrupt

If you press `ESC` to interrupt Claude mid-response, no hook fires. The "active" tint stays until your next message (which retriggers the cycle) or until you reset manually.

Tracked upstream in [anthropics/claude-code#9516](https://github.com/anthropics/claude-code/issues/9516). Add a 👍 if it bothers you.

### Manual reset

Bind a key in your terminal config to reset the background. For Ghostty, in `~/.config/ghostty/config`:

```
keybind = ctrl+shift+b=reload_config
```

`reload_config` re-applies your default background. Press `Ctrl+Shift+B` after an interrupt to clear a stuck tint.

For other terminals, run `printf '\033]111\007'` in any shell prompt.

## How it works

The plugin registers hooks for these events:

| Hook | Action |
|------|--------|
| `UserPromptSubmit` | tint active |
| `PreToolUse(AskUserQuestion)` | tint question |
| `PostToolUse(AskUserQuestion)` | tint active |
| `Stop`, `SessionEnd` | tint idle |

Each hook runs `hooks/tint.sh` with one argument (`active`, `question`, or `idle`), which writes an `OSC 11` escape sequence directly to `/dev/tty`.

## Uninstall

```
/plugin uninstall claude-ghostty-tint
```

If your background gets stuck after uninstalling, run `printf '\033]111\007'` in any terminal pane.

## License

MIT
