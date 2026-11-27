#!/usr/bin/env bash
# Runs install.sh against a throwaway HOME. Touches nothing outside its temp directory.
# The tests run by name from the list at the bottom, which shellcheck cannot follow.
# shellcheck disable=SC2329
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/plumbline-install.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

ALL=0
FAILED=0
fail() { echo "not ok - $CURRENT: $*"; FAILED=1; }

# A copy of the files install.sh reads, standing in for a clone.
make_clone() {
  mkdir -p "$1"
  cp -R "$REPO/AGENTS.md" "$REPO/install.sh" "$REPO/skills" "$1/"
}

# A HOME where Claude Code, opencode and Antigravity are all installed.
make_home() {
  mkdir -p "$1/.claude" "$1/.config/opencode" "$1/.gemini/config"
}

# Runs the installer with no companions and a bare environment. Sets OUT and CODE.
install() {
  local home="$1" clone="$2"
  shift 2
  OUT="$(env -i HOME="$home" PATH=/usr/bin:/bin bash "$clone/install.sh" --no-companions "$@" 2>&1)"
  CODE=$?
}

resolve() {
  local path="$1" hops=0
  while [ -L "$path" ] && [ "$hops" -lt 10 ]; do
    path="$(readlink "$path")"
    hops=$((hops + 1))
  done
  printf '%s' "$path"
}

# Every place install.sh links, for a HOME with all three agents.
targets() {
  local home="$1" skill name
  echo "$home/.agents/AGENTS.md"
  echo "$home/.config/opencode/AGENTS.md"
  echo "$home/.gemini/config/rules/AGENTS.md"
  for skill in "$REPO"/skills/*/; do
    name="$(basename "$skill")"
    echo "$home/.agents/skills/$name"
    echo "$home/.claude/skills/$name"
    echo "$home/.gemini/config/skills/$name"
  done
}

expect_into_clone() {
  local home="$1" clone="$2" target end
  while read -r target; do
    end="$(resolve "$target")"
    case "$end" in
      "$clone"/*) [ -e "$end" ] || fail "${target#"$home"/} resolves to a missing $end" ;;
      *) fail "${target#"$home"/} resolves to $end, outside $clone" ;;
    esac
  done < <(targets "$home")
}

expect_code() {
  [ "$CODE" -eq "$1" ] || fail "exit $CODE, expected $1. Output:
$OUT"
}

imports() { grep -cF '@~/.agents/AGENTS.md' "$1/.claude/CLAUDE.md" 2>/dev/null || true; }


test_dry_run_writes_nothing() {
  local home="$WORK/dry/home" clone="$WORK/dry/clone"
  make_clone "$clone"
  make_home "$home"
  local before after
  before="$(cd "$home" && find . | sort)"
  install "$home" "$clone" --dry-run
  expect_code 0
  after="$(cd "$home" && find . | sort)"
  [ "$before" = "$after" ] || fail "the dry run changed HOME"
}

test_fresh_install_links_every_agent() {
  local home="$WORK/fresh/home" clone="$WORK/fresh/clone"
  make_clone "$clone"
  make_home "$home"
  install "$home" "$clone"
  expect_code 0
  expect_into_clone "$home" "$clone"
  [ "$(imports "$home")" = 1 ] || fail "CLAUDE.md does not import the hub once"
}

test_rerun_changes_nothing() {
  local home="$WORK/rerun/home" clone="$WORK/rerun/clone"
  make_clone "$clone"
  make_home "$home"
  install "$home" "$clone"
  install "$home" "$clone"
  expect_code 0
  expect_into_clone "$home" "$clone"
  [ "$(imports "$home")" = 1 ] || fail "a second run added the import again"
  [ ! -e "$home/.plumbline-backup" ] || fail "a second run made a backup"
}

test_user_file_is_backed_up() {
  local home="$WORK/backup/home" clone="$WORK/backup/clone"
  make_clone "$clone"
  make_home "$home"
  echo "my own rules" >"$home/.config/opencode/AGENTS.md"
  install "$home" "$clone"
  expect_code 0
  expect_into_clone "$home" "$clone"
  [ "$(cat "$home/.plumbline-backup/.config/opencode/AGENTS.md" 2>/dev/null)" = "my own rules" ] ||
    fail "the user's AGENTS.md is not in the backup"
}

test_clone_moved_twice() {
  local home="$WORK/moved/home" a="$WORK/moved/a" b="$WORK/moved/b" c="$WORK/moved/c"
  make_clone "$a"
  make_home "$home"
  install "$home" "$a"
  mv "$a" "$b"
  install "$home" "$b"
  expect_code 0
  expect_into_clone "$home" "$b"
  mv "$b" "$c"
  install "$home" "$c"
  expect_code 0
  expect_into_clone "$home" "$c"
  [ ! -e "$home/.plumbline-backup" ] || fail "a link into an old clone was backed up"
}

test_clone_moved_away_and_back() {
  local home="$WORK/back/home" a="$WORK/back/a" b="$WORK/back/b"
  make_clone "$a"
  make_home "$home"
  install "$home" "$a"
  mv "$a" "$b"
  install "$home" "$b"
  mv "$b" "$a"
  install "$home" "$a"
  expect_code 0
  expect_into_clone "$home" "$a"
  case "$OUT" in *warnings:*) fail "warned about its own links:
$OUT" ;; esac
}

test_unrepairable_target_fails() {
  local home="$WORK/stuck/home" clone="$WORK/stuck/clone"
  make_clone "$clone"
  make_home "$home"
  echo "mine" >"$home/.config/opencode/AGENTS.md"
  mkdir -p "$home/.plumbline-backup/.config/opencode"
  echo "older" >"$home/.plumbline-backup/.config/opencode/AGENTS.md"
  install "$home" "$clone"
  [ "$CODE" -ne 0 ] || fail "exit 0 with a target left unrepaired"
  [ "$(cat "$home/.config/opencode/AGENTS.md")" = "mine" ] || fail "the user's file changed"
  [ "$(cat "$home/.plumbline-backup/.config/opencode/AGENTS.md")" = "older" ] ||
    fail "the earlier backup changed"
}

test_impeccable_stays_out_of_claude_code() {
  local home="$WORK/imp/home" clone="$WORK/imp/clone" hub
  make_clone "$clone"
  make_home "$home"
  hub="$home/.agents/skills/impeccable"
  mkdir -p "$hub" "$home/.claude/skills"
  echo "---" >"$hub/SKILL.md"
  ln -s "$hub" "$home/.claude/skills/impeccable"
  install "$home" "$clone"
  expect_code 0
  [ ! -e "$home/.claude/skills/impeccable" ] && [ ! -L "$home/.claude/skills/impeccable" ] ||
    fail "Claude Code still links impeccable"
  [ "$(readlink "$home/.gemini/config/skills/impeccable")" = "$hub" ] ||
    fail "Antigravity does not link impeccable"
}

test_uninstall_restores_home() {
  local home="$WORK/uninstall/home" clone="$WORK/uninstall/clone" target
  make_clone "$clone"
  make_home "$home"
  echo "my own rules" >"$home/.config/opencode/AGENTS.md"
  echo "# my notes" >"$home/.claude/CLAUDE.md"
  install "$home" "$clone"
  install "$home" "$clone" --uninstall
  expect_code 0
  while read -r target; do
    [ "$target" = "$home/.config/opencode/AGENTS.md" ] && continue
    [ ! -L "$target" ] || fail "${target#"$home"/} is still linked"
  done < <(targets "$home")
  [ "$(cat "$home/.config/opencode/AGENTS.md")" = "my own rules" ] ||
    fail "the user's AGENTS.md was not restored"
  [ "$(cat "$home/.claude/CLAUDE.md")" = "# my notes" ] ||
    fail "CLAUDE.md is not back to the user's text: $(cat "$home/.claude/CLAUDE.md")"
}

for CURRENT in test_dry_run_writes_nothing test_fresh_install_links_every_agent \
  test_rerun_changes_nothing test_user_file_is_backed_up test_clone_moved_twice \
  test_clone_moved_away_and_back test_unrepairable_target_fails \
  test_impeccable_stays_out_of_claude_code test_uninstall_restores_home; do
  FAILED=0
  "$CURRENT"
  if [ "$FAILED" -eq 0 ]; then echo "ok - $CURRENT"; else ALL=1; fi
done
exit "$ALL"
