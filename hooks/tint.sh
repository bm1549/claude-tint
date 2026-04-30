#!/usr/bin/env bash
# Set Ghostty (or any OSC 11-capable terminal) background based on Claude state.
# Usage: tint.sh active|question|idle

set_bg() {
  printf '\033]11;%s\007' "$1" > /dev/tty 2>/dev/null
}

reset_bg() {
  printf '\033]111\007' > /dev/tty 2>/dev/null
}

case "${1:-}" in
  active)
    set_bg "${CLAUDE_TINT_ACTIVE:-#292d3e}"
    ;;
  question)
    set_bg "${CLAUDE_TINT_QUESTION:-#2e2b27}"
    ;;
  idle)
    if [ -n "${CLAUDE_TINT_IDLE:-}" ]; then
      set_bg "$CLAUDE_TINT_IDLE"
    else
      reset_bg
    fi
    ;;
esac

exit 0
