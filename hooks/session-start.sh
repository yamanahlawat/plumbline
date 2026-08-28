#!/usr/bin/env bash
# SessionStart hook. A plugin cannot ship a context file, so the rules arrive here.
set -euo pipefail

# Byte semantics, not locale semantics. Under a UTF-8 locale the newline substitution
# below takes ~110ms on a 5 KB file; here it is ~1ms. Every byte matched is ASCII, and
# a UTF-8 trail byte is never ASCII, so multibyte content survives untouched.
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RULES_FILE="${PLUGIN_ROOT}/AGENTS.md"

[ -f "$RULES_FILE" ] || exit 0

rules="$(<"$RULES_FILE")"

# One pass per escape. A character loop is orders of magnitude slower.
escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

context="<PLUMBLINE>\nThe house rules below apply to every action in this session. Follow them; do not restate them.\n\n$(escape_for_json "$rules")\n</PLUMBLINE>"

# Each platform reads one field and ignores the rest, so emit only the one it reads.
if [ -n "${CURSOR_PLUGIN_ROOT:-}" ]; then
  printf '{\n  "additional_context": "%s"\n}\n' "$context"
elif [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -z "${COPILOT_CLI:-}" ]; then
  printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$context"
else
  printf '{\n  "additionalContext": "%s"\n}\n' "$context"
fi
