---
name: cmd-follow-up
description: Self-review after implementation — surface missed work, simplification opportunities, and idiomatic improvements
disable-model-invocation: true
---

# Follow-Up

Post-implementation reflection pass. Run after completing a task to catch loose ends and simplify before calling it done.

## Instructions

1. **Determine scope** — use the current branch diff unless the user specifies otherwise:
   - `git diff main...HEAD --name-only`
   - Fall back to staged changes if no branch diff exists
2. **Read all changed files in full** before reviewing.
3. **Answer each question below.** For every finding, cite `file_path:line_number` and fix it directly.
4. **If everything looks good**, say so briefly — don't invent busywork.

## Questions

### 1. Anything left undone?

- Are there TODOs, FIXMEs, or HACKs introduced in this diff that should be resolved now?
- Did you skip something the user asked for?
- Are there commented-out code blocks or placeholder values that shouldn't ship?
- Are there missing error cases, edge cases, or validations at system boundaries?
- Are there fallback/legacy code paths? If so, **ask the user explicitly** whether to keep, remove, or flag them — don't assume backward compatibility is wanted.

### 2. More idiomatic?

- Does the code follow the language's conventions and standard library patterns?
- Are there manual implementations of things the standard library or existing dependencies already provide?
- Does naming follow the project's existing conventions (check surrounding files)?
- Are there language-specific antipatterns? (e.g., Python: bare `except`, mutable default args; Go: exported names that shouldn't be; JS/TS: `any` types that should be narrowed)

### 3. More modular?

- Are there functions doing more than one thing that should be split?
- Is there duplicated logic across the diff that should be extracted?
- Are responsibilities in the right files/modules, or did something land in the wrong place?
- **Counter-check:** Don't extract abstractions for one-time code. Three similar lines is fine.

### 4. Simpler?

- Can any code path be removed or collapsed? (dead branches, unreachable conditions)
- Are there over-engineered patterns? (unnecessary factories, abstractions with one implementation, config for things that won't change)
- Can complex conditionals be simplified or inverted for early returns?
- Is there defensive code for impossible states? (internal callers you control, framework guarantees)

## Output

For each question where you find something actionable:
- Show the finding with `file_path:line_number`
- Apply the fix directly
- One-line explanation of what changed and why

If nothing actionable is found, say: "Clean — nothing to follow up on."
