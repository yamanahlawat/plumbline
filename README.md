<h1 align="center">plumbline</h1>

<p align="center">
  Evidence before assertion. House rules for how a coding agent works.
</p>

---

A plumb line is the reference you check against.

- **`AGENTS.md`**: rules for every action. It covers precedence, evidence, restraint,
  process, language, commits and releases. Each agent loads it at the start of a session.
- **`coding-principles`**: a skill with YAGNI, naming, structure, contracts and testing.
- **`writing-the-record`**: a skill with one recipe per kind of text that stays in the record.

Language-agnostic and project-agnostic. Nothing here names a framework.

## Install

```sh
git clone https://github.com/yamanahlawat/plumbline.git ~/plumbline
~/plumbline/install.sh
```

It links everything into `~/.agents` and points each agent it finds at that hub. It appends
one import line to `~/.claude/CLAUDE.md`, and installs the companions below. A file already at
a target moves to `~/.plumbline-backup` first. Re-run it any time to repair what has drifted,
including links into a clone you moved.

- `--dry-run` prints what it would do and writes nothing.
- `--no-companions` skips the companions.
- `--uninstall` removes the links and the import line, and puts back what it moved aside. It
  leaves the companions installed.

It exits with an error when it leaves a target unrepaired, and says which one.

| Agent | Reads the rules from | Reads the skills from |
|---|---|---|
| Claude Code | an import line in `~/.claude/CLAUDE.md` | `~/.claude/skills/` |
| opencode | `~/.config/opencode/AGENTS.md` | `~/.agents/skills/`, which it scans itself |
| Antigravity | `~/.gemini/config/rules/AGENTS.md` | `~/.gemini/config/skills/` |

Every agent reads its own paths, so the installer fills each one. To add an agent, add a row
to the `AGENTS` table at the top of `install.sh`. A row holds four fields: the agent's name,
the directory that proves it is installed, its rules file and its skills directory. Leave a
field empty when the agent needs nothing there.

<details>
<summary>Other ways to install</summary>

**Claude Code only.** The repository is its own marketplace, so nothing needs approving.
A `SessionStart` hook delivers `AGENTS.md`, because a plugin cannot ship a context file. The
hook runs at startup, after `/clear` and after compaction. The plugin pins no version, so
`claude plugin update plumbline@plumbline` picks up each new commit.

```
/plugin marketplace add yamanahlawat/plumbline
/plugin install plumbline@plumbline
```

**Skills only.** These are [Agent Skills](https://agentskills.io), so any agent that reads
the format works.

```sh
npx skills add yamanahlawat/plumbline
```

It fills `~/.agents/skills/` and links `~/.claude/skills/`. It does not fill
`~/.gemini/config/skills/`, so Antigravity does not see the skills this way. It never installs
`AGENTS.md`, so the always-on rules do not reach you this way.

On Claude Code, pick one path. The installer and the plugin each deliver `AGENTS.md`, so
using both loads the rules twice. The installer warns you when it sees the plugin enabled.

</details>

## Companions

plumbline is one opinionated working style. `AGENTS.md` names three companions that plumbline
does not bundle: two Claude Code plugins and one skill. `install.sh` installs all three, and
none is required.

- **[superpowers](https://github.com/obra/superpowers)**, a plugin: the process. Brainstorming
  before a plan, systematic debugging before a fix, TDD, code review.
- **[frontend-design](https://github.com/anthropics/claude-plugins-public/tree/main/plugins/frontend-design)**,
  a Claude Code plugin: Claude's own frontend skill. Claude Code uses it for UI and UX work.
- **[impeccable](https://github.com/pbakaus/impeccable)**, a skill: frontend craft, such as
  hierarchy, typography, accessibility and motion. Every agent except Claude Code uses it. The
  installer links it everywhere else, and removes a link it made in `~/.claude/skills/` earlier.

If you skip one, take it out of `AGENTS.md`.

## Working on plumbline

`scripts/check` runs shellcheck and the installer and hook tests against a throwaway `HOME`.
CI runs it on each pull request, and also checks each commit title. The language rules are
judgment calls, so no tool checks them. To run the checks before they reach CI:

```sh
brew install shellcheck
git config core.hooksPath .githooks
```

## License

MIT. See [LICENSE](LICENSE).
