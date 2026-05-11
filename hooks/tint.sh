#!/usr/bin/env bash
# Set Ghostty (or any OSC 11-capable terminal) background based on Claude state.
# Usage: tint.sh active|question|idle

# Claude Code spawns hook subprocesses detached from the controlling terminal, so
# /dev/tty is unavailable. Prefer an explicit CLAUDE_TTY env var (set in shell
# config via: export CLAUDE_TTY=$(tty)); fall back to walking the process tree.
find_tty() {
  if [ -n "${CLAUDE_TTY:-}" ] && [ -w "$CLAUDE_TTY" ]; then
    echo "$CLAUDE_TTY"
    return 0
  fi
  local pid=$$
  while [ "$pid" -gt 1 ]; do
    local tty_name ppid
    read -r tty_name ppid <<< "$(ps -o tty=,ppid= -p "$pid" 2>/dev/null)"
    case "$tty_name" in
      ''|'?'|'??'|'-') ;;
      *) [ -w "/dev/$tty_name" ] && echo "/dev/$tty_name" && return 0 ;;
    esac
    [ -z "$ppid" ] && break
    [ "$ppid" = "$pid" ] && break
    pid="$ppid"
  done
  return 1
}

# Cache the resolved TTY per Claude session to avoid ps forks on every hook call.
_TINT_CACHE="${TMPDIR:-/tmp}/.tint_tty.$PPID"
if [ -f "$_TINT_CACHE" ]; then
  TTY_DEV=$(<"$_TINT_CACHE")
else
  TTY_DEV=$(find_tty)
  [ -z "$TTY_DEV" ] && exit 0
  printf '%s' "$TTY_DEV" > "$_TINT_CACHE"
fi

set_bg() {
  printf '\033]11;%s\007' "$1" > "$TTY_DEV" 2>/dev/null
}

reset_bg() {
  printf '\033]111\007' > "$TTY_DEV" 2>/dev/null
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
