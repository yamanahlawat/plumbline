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

# JSON forbids every control byte below 0x20 in a string. One pass per byte.
escape_for_json() {
  local s="$1" code char
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  for code in 01 02 03 04 05 06 07 08 0b 0c 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f; do
    printf -v char %b "\\x$code"
    s="${s//$char/\\u00$code}"
  done
  printf '%s' "$s"
}

context="<PLUMBLINE>\nThe house rules below apply to every action in this session. Follow them; do not restate them.\n\n$(escape_for_json "$rules")\n</PLUMBLINE>"

printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$context"
