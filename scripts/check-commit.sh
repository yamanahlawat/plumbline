#!/usr/bin/env bash
# Check commit messages against plumbline's commit rule: a conventional title and no body.
#
# usage: check-commit.sh FILE          check one message, as the commit-msg hook passes it
#        check-commit.sh --range A..B  check every non-merge commit in a range
set -euo pipefail

TYPES='build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test'
MAX=100

# Prints one line per problem with the message on stdin. Prints nothing when it passes.
problems() {
  local message title body
  message="$(cat)"
  title="$(printf '%s\n' "$message" | sed -n '1p')"
  case "$title" in "Merge "*|"Revert "*|"fixup! "*|"squash! "*|"amend! "*) return ;; esac
  body="$(printf '%s\n' "$message" | sed -e '1d' -e '/^#/d' | grep -v '^[[:space:]]*$' || true)"
  if ! printf '%s' "$title" | grep -qE "^($TYPES)(\([a-z0-9._/-]+\))?!?: [^[:space:]]"; then
    echo "the title is not 'type(scope): subject' with a type from: ${TYPES//|/, }"
  fi
  case "${title#*: }" in [A-Z]*) echo "the subject starts with a capital letter" ;; esac
  case "$title" in *.) echo "the title ends with a period" ;; esac
  if [ "${#title}" -gt "$MAX" ]; then
    echo "the title is ${#title} characters, over $MAX"
  fi
  if [ -n "$body" ]; then
    echo "the message has a body"
  fi
}

status=0
report() {
  local name="$1" found
  found="$(problems)"
  if [ -n "$found" ]; then
    printf '%s:\n%s\n  rule: writing-the-record, Recipes: Commit title\n' "$name" \
      "$(printf '%s\n' "$found" | sed 's/^/  /')" >&2
    status=1
  fi
}

case "${1:-}" in
  --range)
    shas="$(git rev-list --no-merges "${2:?usage: check-commit.sh --range A..B}")" || exit 2
    for sha in $shas; do
      report "$(git log -1 --format='%h %s' "$sha")" < <(git log -1 --format=%B "$sha")
    done ;;
  '') echo "usage: check-commit.sh FILE | --range A..B" >&2; exit 2 ;;
  *) report "commit message" <"$1" ;;
esac
exit "$status"
