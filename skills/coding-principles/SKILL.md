---
name: coding-principles
description: The house rules for writing code in any language or repo - need-before-build (YAGNI), naming and comments, structure, complexity limits, contracts, testing discipline, and process. Load before writing, refactoring, or reviewing any code.
---

# Coding Principles

The single home for how we write code. Language-agnostic and project-agnostic - nothing here names a framework or a file in a repo.

- Repo mechanics - paths, test config, fixture placement, patch idioms → the repo's `AGENTS.md`
- Why a specific decision was made → the repo's `docs/adr/`, `docs/design/`

Nothing else should restate a principle. Point here instead.

---

## 1. Do You Even Need It?

1. Does this need to exist? → no: skip it (YAGNI)
2. Stdlib does it? → use it
3. Native platform feature? → use it
4. Installed dependency? → use it
5. One line? → one line
6. Only then: write the minimum that works

> The best code is code that doesn't exist. The second best is code that's obvious.

---

## 2. Naming & Comments

- Names should reveal intent - if you need a comment to explain a name, the name is wrong
- Don't abbreviate unless the abbreviation is more universally known than the full word
- Code is read ~10x more than it is written - optimize for the reader
- **"Why, not what" is the floor, not the bar.** Before writing a comment, ask whether the code can carry the intent itself: rename, extract, restructure. A comment is what is left when none of that can express it
- **What can earn a comment** - a third-party default invisible from the call site, a library or browser behaviour that contradicts the obvious reading, the measurement behind a magic number, or an **absence**: why a guard, check, or dependency is deliberately *not* there. Absences are the strongest case, because code cannot state what is not written
- **Never restate what already stands next to it** - the constant below, the test name above, the type on the parameter. A ticket or meeting citation is provenance, not a why: keep the constraint, drop the reference
- **State the constraint the code lives under now, not the change that produced it** - nothing catches a note about a past state when it stops being true. The path not taken belongs in the commit message or an ADR
- **A surviving comment is still cut to length** - one line wherever one line does; delete the second sentence that re-explains the first
- A docstring is part of the contract - when it names one thing and the body does another, it misleads every later reader
- **A docstring that ships is contract only** - public API, generated schema, published docs. Internal rationale belongs in a comment beside the code, not in text handed to callers

---

## 3. Structure

- **Single Responsibility** - a function/class does one thing and has one reason to change
- **Separation of concerns** - keep I/O, business logic, and presentation as distinct layers
- **Pure functions** where possible - same input → same output, no side effects
- Prefer flat over nested
- **Few private helpers** - keep the logic in the object or function that owns it. A private helper buried in a large method is unreachable, so it never gets tested
- A rule with a name is a function - if you can name it, it belongs in the module that owns that concern, not inline in a caller
- **One definition per fact** - two shapes for one fact drift apart. Ship no second mechanism for one fact, not even for one phase
- Turn configuration that does not vary into state, not parameters threaded through each call

---

## 4. Complexity

- Cyclomatic complexity is a smell - if you need to trace more than ~3 branches to understand a function, split it
- Dead code doesn't exist - delete it, git remembers
- Don't optimize prematurely - measure first

---

## 5. Interfaces & Contracts

- **Postel's Law** - be conservative in what you send, liberal in what you accept
- Make invalid states unrepresentable - use types/schemas to prevent bad data rather than checking at runtime
- **Fail fast and loudly** - surface errors at the boundary, not buried in a stack trace
- **Open/Closed** - open for extension, closed for modification; add behavior without touching existing code
- **Dependency Inversion** - depend on abstractions, not concretions
- Fewer dependencies = fewer attack surfaces, fewer breakages, faster builds

---

## 6. Testing

> A test that cannot fail is not a test.

- **Red first** - write the test and watch it fail before you trust it. If the code already exists, break the code and watch it go red
- **Mutation-check subtle rules** - break the rule the way a maintainer breaks it by accident (drop a `sorted`, flip a boolean), confirm the test goes red, restore. Deleting the function proves nothing. A surviving mutant is a missing test, or a test that lies
- **Assert the contract, not the current output** - an assertion copied from the output always agrees with it and carries no requirement
- **Fixtures must discriminate** - pick inputs where a wrong implementation gives a different answer. Two keys already in order make `sorted` and unsorted agree
- **Test behavior, not structure** - if a refactor breaks tests but not behavior, the tests are wrong. Never change assertions and implementation in the same step
- **Test the rule directly** - a rule reachable only through a large method gets tested by accident, or never. Extract it as a pure function (§3) and test that
- **A test helper never reimplements a production guard** - call the real one, or test its branch
- **Verify against real data** - a synthetic fixture holds only what its author remembered. A green suite is not evidence until it has met real output
- **One rule, one home** - delete duplicate coverage. When a test's subject moves, confirm the requirement survives elsewhere before you delete the test
- **State intent at two layers** - a unit test on the rule, an acceptance test on the behavior. A deviation must falsify both. This is not duplicate coverage - one home per rule _per layer_
- **Test code is production code** - same standards for naming, duplication, and clarity
- **FIRST** - Fast, Independent, Repeatable, Self-Validating, Timely

---

## 7. Process & Mindset

- **Boy Scout Rule** - leave the code better than you found it
- **Occam's Razor** - the simplest explanation is usually the correct design
- Don't fix what isn't broken
- The best refactor is the one made before committing, not after
- **A rule a tool can check belongs in a tool** - prose rules decay over a long session; a lint gate, coverage threshold, or mutation run does not. Keep only judgment calls in this doc
- **Review behavior, not diffs** - read the tests (they are the contract), then run the thing. Spot-check critical code instead of reading every generated line
