#!/usr/bin/env bash
# Link plumbline into every agent on this machine. Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB="$HOME/.agents"
BACKUP="$HOME/.plumbline-backup"
SKILLS_CLI="skills@1.8.1"

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
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY=1 ;;
    --no-companions)  COMPANIONS=0 ;;
    --uninstall)      UNINSTALL=1 ;;
    -h|--help)
      cat <<'USAGE'
usage: install.sh [--dry-run] [--no-companions] [--uninstall]

  --dry-run         Print what would change. Write nothing.
  --no-companions   Skip installing superpowers, frontend-design and impeccable.
  --uninstall       Remove plumbline's links and its import line, and put back
                    what the install moved to ~/.plumbline-backup. Companions stay.

Links AGENTS.md and the skills into ~/.agents, then points each installed
agent at that hub. A file or link that plumbline does not own moves to
~/.plumbline-backup first. ~/.claude/CLAUDE.md gets one import line appended.
USAGE
      exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

DID=(); SKIPPED=(); WARNED=(); STUCK=0
note()    { DID+=("$1"); }
skip()    { SKIPPED+=("$1"); }
warn()    { WARNED+=("$1"); }
stuck()   { warn "$1"; STUCK=1; }
run()     { if [ "$DRY" -eq 1 ]; then echo "  would: $*"; else "$@"; fi; }
tilde()   { printf '%s' "${1/#$HOME/~}"; }
exists()  { [ -e "$1" ] || [ -L "$1" ]; }
backup_of() { printf '%s' "$BACKUP/${1#"$HOME"/}"; }

# A link to src is ours. So is a link into a plumbline clone, even after that clone
# moved away.
ours() {
  local src="$1" dst="$2" rel target root
  [ -L "$dst" ] || return 1
  target="$(readlink "$dst")"
  [ "$target" != "$src" ] || return 0
  rel="$(relative "$src")"
  [ -n "$rel" ] || return 1
  case "$target" in */"$rel") ;; *) return 1 ;; esac
  root="${target%/"$rel"}"
  [ ! -e "$target" ] || { [ -f "$root/install.sh" ] && [ -f "$root/skills/coding-principles/SKILL.md" ]; }
}

relative() { case "$1" in "$ROOT"/*) printf '%s' "${1#"$ROOT"/}" ;; esac; }

link() {
  local src="$1" dst="$2" label backup
  label="$(tilde "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    skip "$label (already linked)"; return
  fi
  run mkdir -p "$(dirname "$dst")"
  if ours "$src" "$dst"; then
    note "$label (moved from $(readlink "$dst"))"
  elif exists "$dst"; then
    # The backup goes outside every skills root. A copy left beside a skill is
    # discovered as a second skill of the same name.
    backup="$(backup_of "$dst")"
    if exists "$backup"; then
      stuck "$label is not plumbline's, and a backup already sits at $(tilde "$backup"). Move one of them, then re-run."
      return
    fi
    run mkdir -p "$(dirname "$backup")"
    run mv "$dst" "$backup"
    note "$label (previous version saved to $(tilde "$backup"))"
  else
    note "$label"
  fi
  run ln -sfn "$src" "$dst"
}

# Only a link plumbline owns is removed. Anything else at that path belongs to the user.
unlink_ours() {
  local src="$1" dst="$2" backup
  if ours "$src" "$dst"; then
    run rm "$dst"
    backup="$(backup_of "$dst")"
    if [ "$UNINSTALL" -eq 1 ] && exists "$backup"; then
      run mv "$backup" "$dst"
      note "$(tilde "$dst") (restored from $(tilde "$backup"))"
    else
      note "$(tilde "$dst") (link removed)"
    fi
  fi
}

# One skill, into the hub and into every installed agent that keeps its own skills root,
# except the agent named in the second argument, which loses any link plumbline made there.
install_skill() {
  local src="$1" except="${2:-}" name row agent probe skills
  name="$(basename "$src")"
  # A companion installer already put its skill in the hub. Do not link it to itself.
  if [ "$src" != "$HUB/skills/$name" ]; then
    place "$src" "$HUB/skills/$name"
  fi
  for row in "${AGENTS[@]}"; do
    IFS='|' read -r agent probe _ skills <<<"$row"
    if [ ! -d "$probe" ] || [ -z "$skills" ]; then
      continue
    elif [ "$agent" = "$except" ]; then
      unlink_ours "$src" "$skills/$name"
    else
      place "$src" "$skills/$name"
    fi
  done
}

place() { if [ "$UNINSTALL" -eq 1 ]; then unlink_ours "$@"; else link "$@"; fi; }

claude_plugin() {
  local name="$1" plugin="$1@claude-plugins-official"
  if ! command -v claude >/dev/null 2>&1; then
    skip "$name (the claude CLI is not on PATH)"
  elif [ "$DRY" -eq 1 ]; then
    echo "  would: claude plugin install $plugin"
    note "$name"
  elif (cd "$HOME" && claude plugin install "$plugin") </dev/null; then
    note "$name"
  else
    skip "$name (install it yourself: claude plugin install $plugin)"
  fi
}

claude_import() {
  local claude_md="$HOME/.claude/CLAUDE.md" import='@~/.agents/AGENTS.md'
  [ -d "$HOME/.claude" ] || return 0
  if [ "$UNINSTALL" -eq 1 ]; then
    if [ -f "$claude_md" ] && grep -qxF "$import" "$claude_md"; then
      if [ "$DRY" -eq 1 ]; then
        echo "  would: remove '$import' from $claude_md"
      else
        { grep -vxF "$import" "$claude_md" || true; } >"$claude_md.plumbline"
        cat "$claude_md.plumbline" >"$claude_md"
        rm "$claude_md.plumbline"
      fi
      note "$(tilde "$claude_md") (import removed)"
    fi
    return 0
  fi
  # The plugin ships the same rules through its SessionStart hook. Say so and install
  # anyway: a wrong guess here would leave Claude Code with no rules at all.
  if grep -qE '"plumbline@[^"]*"[[:space:]]*:[[:space:]]*true' "$HOME/.claude/settings.json" 2>/dev/null; then
    warn "The plumbline plugin is enabled in Claude Code, so it loads AGENTS.md too. Keep one path: uninstall the plugin, or re-run with --uninstall."
  fi
  if [ -f "$claude_md" ] && grep -qxF "$import" "$claude_md"; then
    skip "$(tilde "$claude_md") (already imports the hub)"
  elif [ "$DRY" -eq 1 ]; then
    echo "  would: append '$import' to $claude_md"
    note "$(tilde "$claude_md")"
  else
    if [ -s "$claude_md" ] && [ -n "$(tail -c1 "$claude_md")" ]; then
      printf '\n' >> "$claude_md"
    fi
    printf '%s\n' "$import" >> "$claude_md"
    note "$(tilde "$claude_md") (import appended)"
  fi
}

echo "plumbline: $ROOT"
[ "$DRY" -eq 1 ] && echo "dry run. nothing is written."

# The hub. opencode scans ~/.agents/skills itself, and the line appended to CLAUDE.md
# points at ~/.agents/AGENTS.md, so this path has to stay fixed.
place "$ROOT/AGENTS.md" "$HUB/AGENTS.md"

for row in "${AGENTS[@]}"; do
  IFS='|' read -r name probe rules _ <<<"$row"
  if [ ! -d "$probe" ]; then
    skip "$name (not installed)"
  elif [ -n "$rules" ]; then
    place "$HUB/AGENTS.md" "$rules"
  fi
done

for skill in "$ROOT"/skills/*/; do
  install_skill "${skill%/}"
done

# Claude Code reads one global rules file, ~/.claude/CLAUDE.md, and the user owns it.
# An import line is the only way in that does not take the file over.
claude_import

# Both installers pick user or project scope from the working directory, so they run
# from $HOME. Run from here, they install into this repository.
#
# superpowers is a plugin with hooks and commands, so each agent holds its own copy:
# the Claude Code plugin cache, and a `plugin` entry in opencode.jsonc.
if [ "$UNINSTALL" -eq 1 ]; then
  skip "superpowers, frontend-design and impeccable (companions are left installed)"
elif [ "$COMPANIONS" -eq 1 ]; then
  claude_plugin superpowers
  claude_plugin frontend-design

  if ! command -v npx >/dev/null 2>&1; then
    skip "impeccable (npx is not on PATH)"
  elif [ "$DRY" -eq 1 ]; then
    echo "  would: npx -y $SKILLS_CLI add pbakaus/impeccable"
    note "impeccable"
  elif (cd "$HOME" && npx -y "$SKILLS_CLI" add pbakaus/impeccable) </dev/null; then
    note "impeccable"
  else
    skip "impeccable (install it yourself with Node 22.20 or newer: npx $SKILLS_CLI add pbakaus/impeccable)"
  fi
else
  skip "superpowers, frontend-design and impeccable (--no-companions)"
fi

# impeccable installs into ~/.agents/skills only, so plumbline links it out to every
# other root. AGENTS.md has Claude Code use the frontend-design plugin instead.
if [ -d "$HUB/skills/impeccable" ]; then
  install_skill "$HUB/skills/impeccable" "Claude Code"
fi

echo
echo "changed:"
if [ ${#DID[@]} -eq 0 ]; then echo "  nothing"; else printf '  %s\n' "${DID[@]}"; fi
echo "skipped:"
if [ ${#SKIPPED[@]} -eq 0 ]; then echo "  nothing"; else printf '  %s\n' "${SKIPPED[@]}"; fi
if [ ${#WARNED[@]} -gt 0 ]; then
  echo "warnings:"
  printf '  %s\n' "${WARNED[@]}"
fi
exit "$STUCK"
