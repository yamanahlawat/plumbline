#!/usr/bin/env bash
# Runs the SessionStart hook on a copy of the plugin and parses what it prints.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/plumbline-hook.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

ALL=0

# Prints the context the hook delivers, or fails when its output is not the JSON Claude Code reads.
context_for() {
  local root="$WORK/$1"
  mkdir -p "$root/hooks"
  cp "$REPO/hooks/session-start.sh" "$root/hooks/"
  printf '%s' "$2" >"$root/AGENTS.md"
  CLAUDE_PLUGIN_ROOT="$root" bash "$root/hooks/session-start.sh" | python3 -c '
import json, sys
out = json.load(sys.stdin)["hookSpecificOutput"]
assert out["hookEventName"] == "SessionStart", out
sys.stdout.write(out["additionalContext"])'
}

check() {
  local name="$1" rules="$2" context
  if ! context="$(context_for "$name" "$rules" 2>&1)"; then
    echo "not ok - $name: ${context##*$'\n'}"
    ALL=1
  elif [[ "$context" != *"$rules"* ]]; then
    echo "not ok - $name: the context does not hold the rules unchanged"
    ALL=1
  else
    echo "ok - $name"
  fi
}

check "the repository AGENTS.md" "$(cat "$REPO/AGENTS.md")"
check "quotes, backslashes and tabs" $'say "hi"\\n\tthen\r\nstop'
check "a form feed and other control bytes" $'page one\fpage two\x01\x1b[0m'
check "multibyte text" $'caf\xc3\xa9 \xe2\x86\x92 done'

exit "$ALL"
