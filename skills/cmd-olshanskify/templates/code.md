# Olshanskify Template: Code

Use when editing source files, proposing refactors, or writing new code in any language.

## Core Bias

- **Write less code.** If the change can be one line, make it one line. No helper functions for things used once.
- **Reach for stdlib and battle-tested OSS** before inventing an abstraction. Don't reinvent the wheel.
- **Solve the problem in front of you.** Do not design for hypothetical future requirements, and do not "clever-engineer" past what the task needs.
- **Simplicity > cleverness.** If two approaches work, pick the one a new reader understands faster.

## Comments & Docs in Code

- **Default to no comments.** Well-named identifiers are the documentation.
- **Write a comment only when the _why_ is non-obvious** — a hidden invariant, a workaround for a specific bug, a surprise the reader would hit otherwise.
- **Never describe _what_ the code does** if the code already says it. Never reference the current task/PR/caller in a comment — that belongs in the PR description and rots otherwise.
- **One short line max** for comments and docstrings. No multi-paragraph preambles.
- **Break comments noisily when they drift** — it is better to delete a wrong comment than to partially update it.

## TODO Conventions

Use a specific prefix — never bare `TODO:` when a more specific one fits.

| Prefix | Use for |
|---|---|
| `TODO:` | Generic future work (fallback) |
| `TODO_IMPROVE:` | Code quality / refactor opportunities |
| `TODO_OPTIMIZE:` | Performance / efficiency gains |
| `TODO_IDEA:` | Potential features worth considering |
| `TODO_CONSIDERATION:` | Design decisions that may need revisiting |
| `TODO_TECHDEBT:` | Known debt to address later |
| `TODO_IN_THIS_PR:` | Must resolve before merging current PR |
| `TODO_REMOVE_LATER:` | Temporary code with a known expiry condition |
| `FIXME:` | Known bug / broken behavior |
| `HACK:` | Temporary workaround to be replaced |
| `NOTE:` | Important explanation or warning for future readers |

Every TODO must carry, at minimum:

- **What** needs to be done
- **Why** it is deferred or necessary
- **How** (optional) — implementation hint if not obvious
- **Blocked** (optional) — what's blocking the work

`TODO_REMOVE_LATER` additionally requires the **condition that makes the branch obsolete**, placed directly above the branch entry point. Only use it for genuinely temporary behavior; use `TODO_TECHDEBT` when unsure.

## File & Symbol References

- Use the `file_path:line_number` pattern whenever pointing at code in prose or review comments.
- In PR descriptions, link the exact lines rather than pasting snippets that will drift.

## Language-Specific Rules

**Python — always `uv`, never `pip`/`.venv/bin/python` unless explicitly told otherwise:**

- `uv sync` / `uv add <pkg>` for dependencies
- `uv run python …` / `uv run pytest` / `uv run ruff …` for execution
- `pyproject.toml` as the manifest, not `requirements.txt`

**Shell / CLI work — modern tools over legacy:**

- `fd` instead of `find`
- `rg` (ripgrep) instead of `grep`

## Things to Strip (Anti-Patterns)

- Error handling, fallbacks, or validation for things that cannot happen. Trust internal callers; only validate at real system boundaries (user input, external APIs).
- Feature flags or backwards-compat shims when you can just change the code.
- Renaming an unused var to `_var` instead of deleting it.
- Re-exporting types "for compatibility" that nothing consumes.
- `// removed X` comments where the diff already tells the story.
- Half-finished refactors — ship the complete change or don't start.

## Before You Submit the Edit

Check:

1. Can any new code be deleted without losing behavior? Delete it.
2. Are all comments justified by _why_, not _what_?
3. Are TODO prefixes specific, with why + blockers where relevant?
4. Does the diff introduce abstraction the current caller does not need? Collapse it.
5. Does Python code use `uv`, and shell code use `fd` / `rg`?
