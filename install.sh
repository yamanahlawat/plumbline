#!/usr/bin/env bash
# Link plumbline into every agent on this machine. Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB="$HOME/.agents"
BACKUP="$HOME/.plumbline-backup"

# One row per agent: name | probe | rules file | skills root.
#
# The probe decides whether the agent is installed. An empty field means the agent
# needs nothing there. To support another agent, add a row.
#
# Claude Code has no rules file here. Its rules arrive as an import line inside
# ~/.claude/CLAUDE.md, which the user owns, so a symlink would overwrite their file.
# opencode has no skills root. It scans ~/.agents/skills itself.
AGENTS=(
  "Claude Code|$HOME/.claude||$HOME/.claude/skills"
  "opencode|$HOME/.config/opencode|$HOME/.config/opencode/AGENTS.md|"
  "Antigravity|$HOME/.gemini/config|$HOME/.gemini/config/rules/AGENTS.md|$HOME/.gemini/config/skills"
)

DRY=0
COMPANIONS=1
for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY=1 ;;
    --no-companions)  COMPANIONS=0 ;;
    -h|--help)
      cat <<'USAGE'
usage: install.sh [--dry-run] [--no-companions]

  --dry-run         Print what would change. Write nothing.
  --no-companions   Skip superpowers and impeccable.

Links AGENTS.md and the skills into ~/.agents, then points each installed
agent at that hub. Anything already in place moves to ~/.plumbline-backup
first. Nothing is overwritten.
USAGE
      exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

DID=(); SKIPPED=(); WARNED=()
note()    { DID+=("$1"); }
skip()    { SKIPPED+=("$1"); }
warn()    { WARNED+=("$1"); }
run()     { if [ "$DRY" -eq 1 ]; then echo "  would: $*"; else "$@"; fi; }
tilde()   { printf '%s' "${1/#$HOME/~}"; }

# A link we already own is left alone. Anything else is moved aside first.
link() {
  local src="$1" dst="$2" label="$3"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    skip "$label (already linked)"; return
  fi
  run mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    # The backup goes outside every skills root. A copy left beside a skill is
    # discovered as a second skill of the same name.
    local backup="$BACKUP/${dst#$HOME/}"
    if [ -e "$backup" ]; then
      warn "$label is not plumbline's. A backup already sits at $backup, so it was left as it is."
      return
    fi
    run mkdir -p "$(dirname "$backup")"
    run mv "$dst" "$backup"
    note "$label (previous version saved to $backup)"
  else
    note "$label"
  fi
  run ln -sfn "$src" "$dst"
}

# One skill, into the hub and into every installed agent that keeps its own skills root.
install_skill() {
  local src="$1" name row probe skills
  name="$(basename "$src")"
  # A companion installer already put its skill in the hub. Do not link it to itself.
  if [ "$src" != "$HUB/skills/$name" ]; then
    link "$src" "$HUB/skills/$name" "~/.agents/skills/$name"
  fi
  for row in "${AGENTS[@]}"; do
    IFS='|' read -r _ probe _ skills <<<"$row"
    if [ -d "$probe" ] && [ -n "$skills" ]; then
      link "$src" "$skills/$name" "$(tilde "$skills/$name")"
    fi
  done
}

echo "plumbline: $ROOT"
[ "$DRY" -eq 1 ] && echo "dry run. nothing is written."

# The hub. opencode scans ~/.agents/skills itself, and the line appended to CLAUDE.md
# points at ~/.agents/AGENTS.md, so this path has to stay fixed.
link "$ROOT/AGENTS.md" "$HUB/AGENTS.md" "~/.agents/AGENTS.md"

for row in "${AGENTS[@]}"; do
  IFS='|' read -r name probe rules _ <<<"$row"
  if [ ! -d "$probe" ]; then
    skip "$name (not installed)"
  elif [ -n "$rules" ]; then
    link "$HUB/AGENTS.md" "$rules" "$(tilde "$rules")"
  fi
done

for skill in "$ROOT"/skills/*/; do
  install_skill "${skill%/}"
done

# Claude Code reads one global rules file, ~/.claude/CLAUDE.md, and the user owns it.
# An import line is the only way in that does not take the file over.
if [ -d "$HOME/.claude" ]; then
  # The plugin ships the same rules through its SessionStart hook. Say so and install
  # anyway: a wrong guess here would leave Claude Code with no rules at all.
  if grep -qE '"plumbline@[^"]*"[[:space:]]*:[[:space:]]*true' "$HOME/.claude/settings.json" 2>/dev/null; then
    warn "The plumbline plugin is enabled in Claude Code, so it loads AGENTS.md too. Keep one path: uninstall the plugin, or drop the import from ~/.claude/CLAUDE.md."
  fi
  claude_md="$HOME/.claude/CLAUDE.md"
  import='@~/.agents/AGENTS.md'
  if [ -f "$claude_md" ] && grep -qF "$import" "$claude_md"; then
    skip "~/.claude/CLAUDE.md (already imports the hub)"
  elif [ "$DRY" -eq 1 ]; then
    echo "  would: append '$import' to $claude_md"
    note "~/.claude/CLAUDE.md"
  else
    if [ -s "$claude_md" ] && [ -n "$(tail -c1 "$claude_md")" ]; then
      printf '\n' >> "$claude_md"
    fi
    printf '%s\n' "$import" >> "$claude_md"
    note "~/.claude/CLAUDE.md (import appended)"
  fi
fi

# Both installers pick user or project scope from the working directory, so they run
# from $HOME. Run from here, they install into this repository.
#
# impeccable is a skill, so it installs into the hub and links out like the rest.
# superpowers is a plugin with hooks and commands, so each agent holds its own copy:
# the Claude Code plugin cache, and a `plugin` entry in opencode.jsonc.
if [ "$COMPANIONS" -eq 1 ]; then
  if command -v claude >/dev/null 2>&1; then
    if [ "$DRY" -eq 1 ]; then
      echo "  would: claude plugin install superpowers@claude-plugins-official"
      note "superpowers"
    elif (cd "$HOME" && claude plugin install superpowers@claude-plugins-official) </dev/null >/dev/null 2>&1; then
      note "superpowers"
    else
      skip "superpowers (install it yourself: claude plugin install superpowers@claude-plugins-official)"
    fi
  else
    skip "superpowers (the claude CLI is not on PATH)"
  fi

  if command -v npx >/dev/null 2>&1; then
    if [ "$DRY" -eq 1 ]; then
      echo "  would: npx skills add pbakaus/impeccable"
      note "impeccable"
    elif (cd "$HOME" && npx -y skills add pbakaus/impeccable) </dev/null >/dev/null 2>&1; then
      note "impeccable"
    else
      skip "impeccable (install it yourself: npx skills add pbakaus/impeccable)"
    fi
    # The installer writes ~/.agents/skills and stops. Every other root is ours to fill.
    if [ -d "$HUB/skills/impeccable" ]; then
      install_skill "$HUB/skills/impeccable"
    fi
  else
    skip "impeccable (npx is not on PATH)"
  fi
else
  skip "superpowers and impeccable (--no-companions)"
fi

echo
echo "linked:"
if [ ${#DID[@]} -eq 0 ]; then echo "  nothing"; else printf '  %s\n' "${DID[@]}"; fi
echo "skipped:"
if [ ${#SKIPPED[@]} -eq 0 ]; then echo "  nothing"; else printf '  %s\n' "${SKIPPED[@]}"; fi
if [ ${#WARNED[@]} -gt 0 ]; then echo "warnings:"; printf '  %s\n' "${WARNED[@]}"; fi
