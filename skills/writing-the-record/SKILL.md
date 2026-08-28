---
name: writing-the-record
description: Use when writing any prose a person will read - an issue, a pull request, a changelog entry, release notes, a roadmap, a README section, a commit title, a design note, or a reply that reports status or findings. Load before the first sentence, not after a draft exists.
---

# Writing the record

Text is the project's record. The reader gets the fact, its evidence, and what is still open,
in that order, in as few words as carry them. Each recipe below states what a text IS. Write
to the recipe.

## Rules for every text

- **The title is one plain sentence that states the fact.** "Stopping speech hangs the daemon
  when the speaker is gone", not "TTS deadlock" or "Fix speech hang". A feature title states
  the behaviour: "the hotkey is configurable".
- **Observed, then cause, then evidence.** Evidence names its source: a command, a file and
  line, a measurement.
- **One fact, one place.** A second mention of a number, path or symptom is a cut.
- **Numbers only when measured; facts only from the brief.** Say "not measured" when it is not.
- **Bullets of one or two lines; paragraphs of at most two.** A longer thought is two bullets.
- **Headings only where the reader's question changes.** No Summary, Steps, Expected, Actual
  or Environment templates; those facts go in the observed lines. A recipe section that would
  repeat another, or would be empty, is omitted.
- **What remains is named.** A limit, a deferred half, an unverified claim.
- **Nothing the reader did not ask for.** No proposed fix in a bug report, no preamble, no
  closing summary, no thanks. No process steps: what happens after a merge or a release
  belongs to the workflow, not to the text that records the change.

## Recipes

| Text | Parts, in order |
|---|---|
| **Bug issue** | Title. One line: version and trigger. Two to four observed bullets. `## Cause`: mechanism bullets. `## Evidence`: tool, frames or commands, measurements. |
| **Feature or help-wanted issue** | Title as the missing behaviour. One line: what exists today. `## What to build`: exact files and shapes. `## How to prove it`: the command to run, the artefact to paste. |
| **Pull request** | Title as the changelog line. One line: the problem in the user's terms. `## what it does`. `## decisions worth a look`, each with its reason. `## testing`: counts, commands, real-machine steps. `## what remains`. |
| **Changelog entry** | One bold sentence: what changed for whom. Two to five lines: what the user does differently, what still needs a restart or a workaround. |
| **Release notes** | The version's changelog section, unchanged, under a title in the project's series. |
| **Roadmap** | Landed. Next, numbered, each with why it is next. Community sized. Not planned, each with why. |
| **Commit title** | `type: <the fact>`, lowercase, no period, no body. |
| **Status reply** | State in one line: done, blocked, in progress. What was measured, with the number. What is open. The one question, if any. |
| **Findings reply** | Per finding: the finding as a sentence, the evidence, the consequence, the recommendation. A table at three or more. |
| **README or doc section** | What it is, one line. The command. What it needs. Where it falls short. |

## One example, a bug issue

```markdown
A fade hangs the daemon when the network drops

Observed on 2.3.0 when Wi-Fi drops for ten seconds during a fade.

- `lampd status` times out after 2 s
- the tray keeps showing `Fading`
- only a daemon restart recovers it

## Cause

- the animation thread holds the `scene` mutex while `netlite 1.4` `send()` waits for an
  acknowledgement that never arrives
- the `status` handler takes the same mutex, so it blocks behind it

## Evidence

Debugger, twice: animation thread in `netlite::send`, holding `scene`; RPC thread in
`Mutex::lock` on `scene`.
```

## Before you send

Read it once as the person who must act on it. Cut every line they do not need. Check: the
title is a sentence, every number is measured, what remains is named.
