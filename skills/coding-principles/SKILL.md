---
name: coding-principles
description: "The house rules for writing code in any language or repo, each under its common name: need before build (YAGNI), naming and comments, structure, complexity, contracts, testing and process. Load before writing, refactoring or reviewing any code."
---

# Coding principles

The one home for how code is written. Nothing here names a framework or a file in a repo.
Each rule carries its common name in bold, so a reader can look it up.

- Repo mechanics, such as paths, test config and fixture placement, live in the repo's `AGENTS.md`.
- The reason for a specific decision lives in the repo's decision records, such as `docs/adr/`.

## 1. Need before build

**YAGNI** (you aren't gonna need it). Ask these in order and stop at the first yes.

1. Does nothing need it today? Then skip it.
2. Does the standard library do it? Use that.
3. Does the platform do it natively? Use that.
4. Does an installed dependency do it? Use that.
5. Does one line do it? Write one line.
6. Otherwise, write the least code that works.

Each dependency is one more thing to break, to patch and to build.

## 2. Naming and comments

- **Intention-revealing names.** If a name needs a comment, rename it.
- Abbreviate only when the short form is better known than the full word.
- **Self-documenting code.** Default to no comment. Make the code carry the intent first:
  rename, extract or restructure. A comment holds only what is left.
- **What earns a comment.** Four things do. A third-party default the call site cannot show.
  A library behaviour that contradicts the obvious reading. The measurement behind a magic
  number. An absence, which says why a guard, a check or a dependency is deliberately missing.
  Code cannot show what is not written, so an absence is the strongest case.
- Never restate what stands next to the comment: the constant below, the test name above, the
  type on the parameter.
- Keep the constraint and drop its provenance. A ticket, a meeting or a specification section
  is no reason. Decision prose goes in the commit or a decision record.
- State the constraint the code lives under now. A note about an earlier state goes stale and
  nothing catches it.
- Cut a surviving comment to length. One line wherever one line does.
- **A docstring is contract.** When it names one thing and the body does another, it misleads
  every later reader. A shipped docstring holds contract only: the public API, a generated
  schema, published docs. Internal rationale goes in a comment beside the code.

## 3. Structure

- **Single responsibility** (the S in SOLID). A function or class does one thing and has one
  reason to change.
- **Functional core, imperative shell.** Keep decisions in pure functions: the same input gives
  the same output, with no side effects. Keep I/O and presentation in a thin outer layer.
- Prefer flat code to nested code.
- **A rule with a name is a function.** Put it in the module that owns its concern, where a
  test can reach it. A private helper buried in a large method is unreachable, so it goes untested.
- **Single source of truth** (DRY). One fact has one definition. Two shapes for one fact drift
  apart. Ship no second mechanism for it, even for one phase.
- **Dependency injection for the environment.** `PATH`, the working directory, `HOME`,
  environment variables, the clock and the locale are inputs. The shell reads each one once and
  passes it in.
- Configuration that is fixed for a run goes to the object that owns it, once, when the object
  is built. Do not thread it through every call. Ask of every function: does it read anything
  that neither its caller passed nor its owner holds?
- **Open/closed and dependency inversion** (the O and D in SOLID) apply once a second case
  exists. Add an interface or an extension point only for a variant that exists today. With one
  implementation, call it directly.

## 4. Complexity

- **Cyclomatic complexity.** When a reader has to trace branches on paper to follow a
  function, split it.
- **Dead code.** Delete it. Version control remembers it.
- **Premature optimization.** Optimize only what a measurement shows is slow.

## 5. Interfaces and contracts

- **Parse, don't validate.** A check returns the value it proved, in a type that carries the
  proof. It never returns a bool, and it never hands back the raw string it was given.
- **Make invalid states unrepresentable.** Use types and schemas so bad data cannot be built.
- **Fail fast.** Reject bad input at the boundary where it arrives, loudly, with the value that
  broke the rule. An error deep in a stack trace hides its cause.
- **Postel's law, at the outer edge only.** Accept loose input from a source you do not
  control, such as a person, a file or a third-party API. Parse it into a strict type at once.
  Everything inside the boundary, and everything you send, stays strict.
- **Expand and contract** across services that deploy apart. Ship the producer that serves the
  old and the new shape first. Move each consumer, then remove the old shape.

In this example, `is_port` leaves every caller holding a raw string that it must check again.
`parse_port` runs once at the boundary and hands back a `Port` or raises.

```python
def is_port(text: str) -> bool:
    return text.isdigit() and 0 < int(text) < 65536

@dataclass(frozen=True)
class Port:
    number: int

def parse_port(text: str) -> Port:
    number = int(text)
    if not 0 < number < 65536:
        raise ValueError(f"port out of range: {text!r}")
    return Port(number)
```

## 6. Testing

- **Red, green, refactor** (test-driven development). Watch a test fail before you trust it.
  When the code exists already, break the code and watch the test go red. Then make it pass,
  then tidy it while the change is fresh.
- **Mutation testing.** Break a subtle rule the way a maintainer would by accident: drop a
  sort, flip a boolean. Confirm a test goes red, then restore. Deleting the whole function
  proves nothing. A mutant that survives is a missing test, or a test that lies.
- **Fixtures must discriminate.** Pick inputs where a wrong implementation gives a different
  answer.
- **Assert the contract.** An assertion copied from the current output always agrees with it
  and carries no requirement. A refactor that keeps the behaviour keeps every test green. Never
  change an assertion and the code it checks in the same step.
- **Test the rule directly.** Test the rule's own function from section 3. A rule reachable only
  through a large method gets tested by accident, or never.
- **A test helper never reimplements a production guard.** Call the real guard, or test its branch.
- **Double-loop TDD.** A unit test pins the rule and an acceptance test pins the behaviour a
  person sees. A deviation must fail both. Keep one home per rule in each layer and delete any
  other copy. Before you delete a test whose subject moved, confirm its requirement holds elsewhere.
- **Round-trip a pair.** Two halves that must agree, such as encode and decode or plan and
  apply, get one test on the agreement. A green half proves nothing about the seam.
- **Never weaken a test to get green.** Do not skip it, delete it or loosen its assertion to
  pass. Fix the code, or tell the person why the test is wrong.
- **Test code is production code.** The same standards hold for naming, duplication and clarity.
- **FIRST.** Fast, independent, repeatable, self-validating and timely.

In this example, the first fixture passes whether `names` sorts or not, so a dropped sort
survives it. The second fixture kills that mutant.

```python
def test_names_are_sorted():
    assert names(["ana", "bo"]) == "ana, bo"
    assert names(["cy", "ana", "bo"]) == "ana, bo, cy"
```

## 7. Process

- **KISS** (keep it simple). Pick the simplest design that meets the need.
- **Boy Scout rule, scoped to the diff.** Tidy the code your change already touches. Leave other
  code alone, and offer its fix as a phase of its own.
- **Automate a checkable rule.** A lint gate, a coverage threshold or a mutation run holds over
  a long session, where a prose rule fades. Keep only judgment calls in this skill.
- **Review behaviour first.** Read the tests, because they are the contract. Then run the code.
  Then spot-check the critical lines.
