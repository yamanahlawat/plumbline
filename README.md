<h1 align="center">plumbline</h1>

<p align="center">
  Evidence before assertion. House rules for how a coding agent works.
</p>

---

A plumb line is the reference you check against.

- **`AGENTS.md`** - rules that apply to every action: evidence, restraint, process,
  language, comments, commits. Always in context.
- **`coding-principles`** - a skill: YAGNI, naming, structure, contracts, testing.
- **`writing-the-record`** - a skill: one recipe per kind of text a person reads.

Language-agnostic and project-agnostic. Nothing here names a framework.

## Install

```sh
git clone https://github.com/yamanahlawat/plumbline.git ~/plumbline
~/plumbline/install.sh
```

It links everything into `~/.agents`, points each agent it finds at that hub, and installs
the companions below. Re-run it any time to repair what has drifted. Add `--dry-run` to see
what it would do, or `--no-companions` to skip the extras.

| Agent | Reads the rules from | Reads the skills from |
|---|---|---|
| Claude Code | an import line in `~/.claude/CLAUDE.md` | `~/.claude/skills/` |
| opencode | `~/.config/opencode/AGENTS.md` | `~/.agents/skills/`, which it scans itself |
| Antigravity | `~/.gemini/config/rules/AGENTS.md` | `~/.gemini/config/skills/` |

Every agent reads its own paths, so the installer fills each one. To add an agent, add a row
to the `AGENTS` table at the top of `install.sh`: its name, the directory that proves it is
installed, the file it reads rules from, and the directory it reads skills from. Leave a
field empty when the agent needs nothing there.

<details>
<summary>Other ways to install</summary>

**Claude Code only.** The repository is its own marketplace, so nothing needs approving.
A `SessionStart` hook delivers `AGENTS.md`, because a plugin cannot ship a context file.

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
using both loads the rules twice. The installer warns you when it sees the plugin.

</details>

## Companions

plumbline is one opinionated working style, not a neutral baseline. `AGENTS.md` names two
skills it does not bundle. `install.sh` installs both; neither is required.

- **[superpowers](https://github.com/obra/superpowers)** - the process: brainstorming
  before a plan, systematic debugging before a fix, TDD, code review.
- **[impeccable](https://github.com/pbakaus/impeccable)** - frontend craft: hierarchy,
  typography, accessibility, motion.

If you skip one, delete its row from `AGENTS.md`.

## License

MIT. See [LICENSE](LICENSE).
