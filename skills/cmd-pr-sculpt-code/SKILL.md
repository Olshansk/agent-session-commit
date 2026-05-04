---
name: cmd-pr-sculpt-code
description: Reshape code for readability, naming, structure, TODOs, and reduced surface area across any language
disable-model-invocation: false
---

# Sculpt Code

Reshape code quality across nine dimensions. Scope to branch changes by default, or accept explicit file/directory targets.

**Philosophy:** Write code for the next reader (human, agent, or RAG indexer). Minimize cognitive load. Prefer boring, obvious code over clever code. Every change must preserve business logic unless explicitly told otherwise.

## Determine Scope

**Default (no scope specified):** diff the current branch against the repo's base branch.

Detect the base branch in order — stop at the first success:

1. `gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null`
2. `git remote show origin 2>/dev/null | grep "HEAD branch" | cut -d: -f2 | xargs`
3. `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'`

Do **not** assume `main` or `master`. If all methods fail, ask the user.

Once resolved, run:

```bash
git diff <base>...HEAD -- ":(exclude)*.lock" ":(exclude)package-lock.json" ":(exclude)pnpm-lock.yaml" ":(exclude)package.json"
```

**If the user specifies a scope**, use the corresponding command instead:

| Scope | Command | What it covers |
|---|---|---|
| `unstaged` | `git diff HEAD -- <excludes>` | All uncommitted changes (staged + unstaged) |
| `staged` | `git diff --cached -- <excludes>` | Changes staged but not yet committed |
| `last commit` / `last 1 commit` | `git diff HEAD~1...HEAD -- <excludes>` | Changes in the most recent commit |
| `last N commits` | `git diff HEAD~N...HEAD -- <excludes>` | Changes in the last N commits |
| `entire repo` | `git ls-files \| grep -vE "\.(lock\|snap)$\|package-lock\.json\|pnpm-lock\.yaml"` | All tracked source files; no diff — apply all sculpting dimensions to the full current state of the codebase |
| explicit files/dirs | (user-provided paths) | Only the specified files or directories |

For all diff commands, apply: `-- ":(exclude)*.lock" ":(exclude)package-lock.json" ":(exclude)pnpm-lock.yaml" ":(exclude)package.json"`

## Instructions

1. **Determine scope** using **Determine Scope** above — ask if still unclear.
2. **Read all changed files in full** before reviewing — understand existing patterns, not just the diff.
3. **For Python codebases**, also load `references/python.md` for language-specific guidance.
4. **Review each dimension** below. For each finding, cite `file_path:line_number`.
5. **Apply fixes directly** — this is a sculpting tool, not a report generator. Make the changes, show what you did.

## Dimensions

### 1. Dead Code & Surface Area

- Remove genuinely unused imports, functions, classes, and exception types
- **Verify before delete**: grep the entire codebase before removing anything
- Remove commented-out code older than 1 month unless marked with a TODO explaining why
- DRY threshold: extract helper only at 3+ occurrences (2 is fine as-is)
- Remove premature abstractions: factories with 1 implementation, pass-through wrappers, single-use utility classes

### 2. Naming & Clarity

- Names must reveal intent — no `data`, `temp`, `result`, `x`, `val`, `info` without context
- Follow the codebase's existing conventions (don't mix `repo`/`repository`, `config`/`configuration`)
- Function names describe what they do, not how
- No "hacker code" — prefer `if not items:` over `if len(items) == 0`, but never at the cost of clarity
- Boolean variables/functions read as questions: `is_valid`, `has_permission`, `should_retry`

### 3. File & Function Size

- Functions over ~50 lines → candidate for extraction
- Files over ~400 lines → candidate for splitting
- Each function should have a single clear responsibility
- If you need a comment to separate "sections" within a function, those sections are probably separate functions
- Group related functions in the same file; don't scatter them

### 4. Nesting & Control Flow

- Max 3 levels of nesting — flatten with early returns and guard clauses
- Prefer early returns over deeply nested if/else chains
- Extract complex conditions into named booleans or predicate functions
- Replace nested loops with comprehensions or helper functions where it improves readability (not where it obscures it)

### 5. Idiomatic Patterns

- Use language-native constructs (e.g., list comprehensions in Python, `map`/`filter` in JS where idiomatic)
- Follow the repo's established patterns — don't introduce new paradigms for one function
- Prefer standard library over hand-rolled equivalents
- Match error handling style to the rest of the codebase

### 6. Reuse Opportunities

- Check if an existing helper already does what new code is doing — grep before writing
- Identify patterns repeated across the diff that should use a shared utility
- Flag cases where a library function was reimplemented
- Constants and magic values: extract to named constants if used in more than one place

### 7. TODO Hygiene

Apply the project's TODO prefix standards:

- `TODO:` — general future work
- `TODO_IMPROVE:` — code quality improvements
- `TODO_OPTIMIZE:` — performance improvements
- `TODO_TECHDEBT:` — technical debt to address later
- `TODO_REVISIT:` — design decisions that may need revisiting
- `TODO_IDEA:` — potential features to consider
- `TODO_IN_THIS_PR:` — must complete before merge
- `TODO_REMOVE_LATER:` — temporary code with removal condition
- `FIXME:` — known bugs
- `HACK:` — temporary workarounds

Each TODO must include:
- **What**: clear description
- **Why**: context on why it's deferred

Add missing TODOs for: known shortcuts, deferred work, temporary workarounds, and obvious improvement opportunities spotted during review. Remove stale or resolved TODOs.

### 8. Readability & Cognitive Load

- Comments explain **why**, never **what** (delete `# increment counter` above `counter += 1`)
- Add a brief comment above grouped code blocks (~5+ lines doing one thing)
- Convert paragraph-style comments to bullet points when feasible
- Strategic whitespace: blank lines between logical sections
- Preserve all `IMPORTANT`, `NOTE`, `CRITICAL`, `DEV_NOTE` markers — clean up the text, not the tag
- Keep links, issue references, and external references intact

### 9. Agent & Index Readability

Code is increasingly consumed by agents traversing a codebase and RAG pipelines embedding individual chunks. Apply these checks in addition to the structural ones in Dimensions 3 and 4.

**Self-containment:** Each function should be understandable without reading its callers or surrounding file state.

- Flag functions that only make sense in the context of their caller — extract the shared context into a parameter or a named type
- Avoid implicit shared state (module-level mutation, magic globals) that forces a reader to hold the whole file in mind
- Prefer explicit inputs and outputs over side effects on outer-scope variables

**Meaningful boundaries:** File and module splits should reflect conceptual units, not arbitrary line-count budgets.

- A file with 3 unrelated utility functions is worse than one slightly larger file with a coherent theme
- Module names should describe the concept, not the implementation (`auth_tokens.py` > `helpers.py`, `user_processor.py` > `utils.py`)
- If splitting a file, each half should have a name that a reader can immediately map to a concept

**Embeddable names:** Names must carry enough signal to be useful in isolation — without surrounding code as context.

- Avoid generic names at module or class scope (`process`, `handle`, `run`, `execute`) — add the subject (`process_payment`, `handle_auth_error`)
- Single-letter variables are fine inside a 3-line loop; flag them inside functions that could be indexed independently
- Constants should be named for their meaning, not their value (`MAX_RETRY_ATTEMPTS` > `THREE`)

**Branching budget:** High cyclomatic complexity fragments meaning across many paths, making any single path hard to embed or summarize.

- Flag functions with more than ~5 distinct branches (if/elif/except/case arms combined)
- Prefer dispatch tables, strategy objects, or polymorphism over long if/elif chains when the branches share a shape
- Each branch arm should be readable as a standalone case — extract arm bodies to named helpers when they exceed ~5 lines

## Output Format

For each file changed, show:

```
### file_path

**Changes made:**
- [dimension] description of change (line X)
- [dimension] description of change (line Y)
```

End with a summary: files touched, lines removed, TODOs added/removed, helpers extracted.

## What NOT to Change

- Working abstractions (even if currently simple)
- Type hints (always valuable)
- Test code (unless explicitly asked)
- Forward-looking base classes if second implementation is likely soon
- Domain-specific patterns the team uses intentionally
