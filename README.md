# claude-tint

A Claude Code plugin that tints your terminal background based on what Claude is doing.

| State | Default tint | When |
|-------|--------------|------|
| **Active** | `#292d3e` (blue) | You sent a message and Claude is working |
| **Question** | `#2e2b27` (yellow) | Claude is calling `AskUserQuestion` or showing a permission prompt and waiting on you |
| **Idle** | terminal default | Claude finished responding, or session ended |

Works in any terminal that supports the `OSC 11` set-background escape sequence: Ghostty, iTerm2, kitty, alacritty, wezterm, xterm. The matching `OSC 111` reset sequence is an XTerm extension with patchier support. If your idle bg doesn't return to default on those terminals, set `CLAUDE_TINT_IDLE` to your terminal's default background hex (see [Configuration](#configuration)).

## Why

When you're alt-tabbed away or have a long-running turn, you can't tell at a glance whether Claude is still working, finished, or waiting on a question. A subtle background tint gives you that signal without taking up screen space.

## Install

```
/plugin marketplace add bm1549/claude-tint
/plugin install claude-tint@claude-tint
```

That's it. Restart Claude Code (or start a new session) and the tints will activate. To change colors interactively, run `/claude-tint:setup`.

## Configuration

Run `/claude-tint:setup` to walk through presets and write the right env vars to your `~/.claude/settings.json`.

To configure manually, set any of the three env vars in your Claude Code `settings.json`:

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

### Multiplexers and multiple terminals

If you run Claude inside tmux, screen, or another multiplexer, add this to your shell config (`.zshrc` / `.bashrc`):

```sh
export CLAUDE_TTY=$(tty)
```

This pins the tint target to the specific terminal pane where you launched Claude, preventing the process-tree heuristic from picking the wrong device in complex session setups.

### Picking colors

Aim for hex values close to your terminal's default brightness, with one channel pushed up. Going too dark reads as "screen dimmed" rather than "tinted."

For a typical dark default (e.g. `#282c34`):
- Subtle blue: `#292d3e`
- Obvious blue: `#2a2e4a`
- Very obvious blue: `#2c3260`
- Subtle yellow: `#2e2b27`
- Obvious yellow: `#3e3825`
- Subtle red: `#2e2929`
- Subtle green: `#292d29`

## Known limitation: ESC interrupt

If you press `ESC` to interrupt Claude mid-response, no hook fires. The "active" tint stays until your next message (which retriggers the cycle and resets at end of turn).

Tracked upstream in [anthropics/claude-code#9516](https://github.com/anthropics/claude-code/issues/9516). On Ghostty specifically, [#2795](https://github.com/ghostty-org/ghostty/issues/2795) (OSC 11 not cleared by `reset` action) and [#9868](https://github.com/ghostty-org/ghostty/discussions/9868) (`ctrl+shift+*` keybinds swallowed by kitty keyboard protocol) block the obvious manual-reset workarounds. Add a 👍 to any of these if they bother you.

## How it works

The plugin registers hooks for these events:

| Hook | Action |
|------|--------|
| `UserPromptSubmit` | tint active |
| `PreToolUse(AskUserQuestion)` | tint question |
| `PostToolUse(AskUserQuestion)` | tint active |
| `PermissionRequest` | tint question |
| `PermissionDenied` | tint active |
| `Stop`, `SessionStart`, `SessionEnd` | tint idle |

Each hook runs `hooks/tint.sh` with one argument (`active`, `question`, or `idle`), which writes an `OSC 11` escape sequence to the terminal. Because Claude Code spawns hooks detached from the controlling terminal, the script locates the target device via `$CLAUDE_TTY` (if set) or by walking the process tree to find the parent `claude` process's TTY.

## Uninstall

```
/plugin uninstall claude-tint
```

If your background gets stuck after uninstalling, run `printf '\033]111\007'` in any terminal pane.

## License

MIT
