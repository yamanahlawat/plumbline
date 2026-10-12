---
name: writing-the-record
description: Use when writing any prose a person will read - an issue, a pull request, a changelog entry, release notes, a roadmap, a README section, a commit title, a design note, a reply that reports status or findings, or screen copy (a question, an instruction, a verdict, an error or a button label). Load before the first sentence, not after a draft exists.
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

## Voice

Write the way an engineer talks to a colleague at their desk, in words the reader gets on the
first pass. Two rounds of blind readers flagged text written to short, uniform, declarative
rules as AI-generated; the rules below changed that verdict on the same facts. The caps on
sentence length, one instruction per sentence and the common-word rule come from ASD-STE100
Simplified Technical English. Text written to both sets together has not been through a blind
reading yet.

- **Keep each sentence short, and vary the length under the cap.** At most 20 words in an
  instruction and 25 anywhere else. A five-word sentence can sit next to a twenty-word one; a
  page where every sentence is the same length reads as generated.
- **One idea per sentence.** A second idea is a second sentence.
- **One instruction per sentence, in the imperative.** "Run the loop body once. Type what
  `seen` holds."
- **Active voice, present tense.** Say who does what: "the check finds the gap".
- **Say when something happens in plain words.** Write "when line 4 starts again". A clause
  like "until it comes back to line 4, with `i = 0`" leaves the reader to work out the timing.
- **Common words.** Write "use" for "utilize" and "start" for "commence". A technical name is
  fine: define it on first use, then use the same name every time.
- **No noun clusters longer than three words.** Break a longer one into a phrase: "the fix for
  the drift in the judge's time limit".
- **Say what a thing is.** Don't use the "X, not Y" frame; blind readers quoted it as a tell.
- **No punchline endings.** Don't close a paragraph or a section on a slogan, an epigram or a
  three-beat aphorism ("They move the odds. They do not set the behaviour."). End on the
  fact, the number or what is still open.
- **Say loose ends plainly.** "I don't know why yet" beats a tidy theory.
- **Contractions where they come naturally.** Don't add filler such as "the thing is" to sound
  casual.
- **One word for one meaning,** with no synonym swapped in for variety.
- **No "we", no em dashes, no en dashes.**
- **Never invent a feeling, a motive or an opinion for the person the text speaks for.** Mark
  it for them to confirm.

## Recipes

| Text | Parts, in order |
|---|---|
| **Bug issue** | Title. One line: version and trigger. Two to four observed bullets. `## Cause`: mechanism bullets. `## Evidence`: tool, frames or commands, measurements. |
| **Feature or help-wanted issue** | Title as the missing behaviour. One line: what exists today. `## What to build`: exact files and shapes. `## How to prove it`: the command to run, the artefact to paste. |
| **Pull request** | Title that passes commitlint: the repo's config, else `@commitlint/config-conventional` (`type(scope): subject`, lowercase, no period, at most 100 characters). `## what changed`: one to three bullets. `## tested`: what you ran or tried, and what you saw. Only when they apply: `Closes #N`; `breaking: <what users must do>`, with `!` in the title; a screenshot for a UI change. Nothing else. |
| **Changelog entry** | One bold sentence: what changed for whom. Two to five lines: what the user does differently, what still needs a restart or a workaround. |
| **Release notes** | The version's changelog section, unchanged, under a title in the project's series. |
| **Roadmap** | Landed. Next, numbered, each with why it is next. Community sized. Not planned, each with why. |
| **Commit title** | `type: <the fact>`, lowercase, no period, no body. |
| **Status reply** | State in one line: done, blocked, in progress. What was measured, with the number. What is open. The one question, if any. |
| **Findings reply** | Per finding: the finding as a sentence, the evidence, the consequence, the recommendation. A table at three or more. |
| **README or doc section** | What it is, one line. The command. What it needs. Where it falls short. |
| **Screen copy** | A question: what to do, then what to answer. An instruction: one action per sentence. A verdict: the result in one word, what differs, then the right value. An error: what happened, then what to do next. A button: the verb of its action, and the same verb in the message that confirms it. |

## One example, screen copy

A learner predicts a dict and types a string key. The first version below is what a screen
showed; the second follows the rules.

```text
Run the code in your head until it comes back to line 4, with i = 0. What will seen hold then?
Missed. When line 4 runs again, at step 7, seen holds 3: 0, not '3': 0.
```

```text
Run the loop body one time in your head. What is in seen when line 4 starts again?
Missed. Your key is the string '3'. The code stores the number 3. At step 7, seen is {3: 0}.
```

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

## A pull request reads like a teammate wrote it

- Write it as you would tell a colleague at their desk. Plain words, short lines.
- Name the change, not the effort. "status answers during a fade", not "This PR enhances status handling".
- No "This PR", no bold, no emoji, no summary line at the end.
- No brochure words: robust, seamless, comprehensive, enhance, leverage, streamline, ensure.
- A test line says what happened: the command and its result, or the action and what you saw.

```markdown
fix: lampd status answers during a network drop

## what changed

- the fade releases the `scene` lock before it sends to the lamp
- `status` no longer waits behind a send that never returns

## tested

- dropped Wi-Fi for 10 s mid-fade: `lampd status` answered every time
- `cargo test`: 48 passed
```

## Before you send

Read it once as the person who must act on it. Cut every line they do not need. Check: the
title is a sentence, every number is measured, what remains is named, and no sentence is over
its cap.
