# AGENTS.md

Global rules for every agent, in every repository. A repository `AGENTS.md` wins where the two
disagree. Ask the user when a rule here blocks the task.

The rules below apply to every action. The skills hold the reference material you consult for a
particular kind of work. Follow these; do not restate them.

## Load these skills

Load a skill by name, or with a slash command where the agent supports one.

| Skill | Load it | |
|---|---|---|
| `coding-principles` | Before you write, refactor or review code. | bundled |
| `writing-the-record` | Before any prose a person reads: an issue, a PR, a changelog entry, a roadmap, a doc, a status or findings reply. | bundled |
| `frontend-design` or `impeccable` | For all frontend work: UI, UX, layout, styling, design review. In Claude Code, use Claude's `frontend-design` skill only. Every other agent uses `impeccable`. | companion |
| `superpowers` | For non-trivial work. See the test below. | companion |

Load the skill before the first tool call, not after you start.

A companion skill is recommended, not bundled. The README says how to install each one. If a
companion is absent, do the work without it and say so. Do not go looking for it.

## Trivial or non-trivial

Work is trivial only when all three are true:

- The change touches one file, or it is a rename, a typo or a config value.
- The behaviour is already clear, so no investigation is necessary.
- No new test is necessary.

Trivial work needs no process skill. Do it and report it.

Everything else is non-trivial: a feature, a bug fix, a refactor, a port, or any change that you
cannot state in one sentence. Where superpowers is installed, non-trivial work starts with its
process skills. Brainstorming comes before a plan. Systematic debugging comes before a fix.

## Evidence

- Verify against real data before you believe a green suite.
- A suite that ran in your shell is not evidence for a process a supervisor starts. Run it where it will run.
- Read every field, not the one you expect to hold the answer.
- Measure before you name a cause. Disprove your own hypothesis first.
- Follow the mechanism, not the symptom.
- Never invent a threshold. A limit needs a measurement behind it.
- Never trust a mutation result you cannot reproduce.
- Correct the record where the wrong claim lives. Strike it through; do not quietly edit it.
- Re-open a conclusion when someone pushes back on it.
- State a number only if you measured it. Say so plainly when you did not.

## Restraint

- Add no guard before the evidence. A wrong check states a falsehood with authority, and it spends.
- Add no field without a producer.
- Build nothing that no caller uses yet. A field that is always empty is half-built.
- Borrow with evidence. List what you take, what you defer, and what you reject, with a reason for each.

## Process

- Branch from the last good commit. Do not fix forward through a regression.
- Finish one phase, commit it, then stop.
- Leave the working tree untouched while a review is open. A moving diff cannot be read.
- Keep a working document in the branch: the plan, the log, and every correction.
- Use absolute paths in scripts. A shell can change directory under you.
- Revert an accident surgically. Never discard a tree that holds work you did not write.
- Change a contract and its consumers together. Do not leave the product broken between reviews.
- Report what you skipped as plainly as what you finished.

## After the work

1. Run the project checks: the tests, the linter and the formatter. If the project has none,
   suggest that the project adds them. Do not add them without permission.
2. Review the change. In Claude Code, run `/code-review` or `/simplify`. With superpowers, use
   `requesting-code-review` and `verification-before-completion` only if Claude Code is not available.
3. Show the command output before you call the work done. Evidence comes before the claim.

## Subagents

Delegate independent work to subagents. Match the model to the complexity:

| Work | Model |
|---|---|
| Search, file listing, mechanical edits | the small fast model |
| Scoped implementation against a clear plan | the mid model |
| Architecture, hard debugging, unclear requirements | the top model |

A subagent starts cold, so give it the full context and a clear deliverable. Do not delegate work
that two tool calls finish.

## Language

Write the way an engineer talks to a colleague at their desk: plain, specific, and in a voice
that sounds like a person. The full voice rules, and the shape of each kind of text, are in the
`writing-the-record` skill. The ones that matter most:

- Let sentence length follow the thought. A long sentence with a clause or two can sit next to
  a short one; a page where every sentence is the same length reads as generated.
- Say what a thing is. Don't use the "X, not Y" frame.
- Don't end a paragraph or a section on a punchline, a slogan or a three-beat aphorism.
- Say who does what. One word for one meaning, with no synonym swapped in for variety.
- Don't write "we".
- Never use em dashes or en dashes.

## Comments

- Default to no comment. A comment earns its place only by holding something the code cannot
  show, most often an absence: why a guard or dependency is deliberately not there.
- Do not put specification references or decision prose in a comment.

## Commits and releases

- One phase per commit. Title only. No description body.
- Subagents can make small commits while a phase or a feature is in progress. When it is done,
  squash them into one commit for the phase or the feature.
- Never publish a release to GitHub unasked. That covers `gh release create` and pushing a
  version tag that a release workflow picks up.
