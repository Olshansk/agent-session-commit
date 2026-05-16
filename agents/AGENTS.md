# Olshansky's AGENTS.md <!-- omit in toc -->

- [Writing Code](#writing-code)
- [Python](#python)
- [CLI Tools](#cli-tools)
- [Documentation](#documentation)
- [Agent Rules Integration](#agent-rules-integration)
- [Git Workflow Integration](#git-workflow-integration)
- [Global Configs](#global-configs)
- [MCP Server Management](#mcp-server-management)
- [Context Loading Strategy](#context-loading-strategy)
- [Development Commands](#development-commands)
- [Custom Skills](#custom-skills)
- [Communication Format Preferences](#communication-format-preferences)
- [General Guidelines in Code](#general-guidelines-in-code)
- [Plan Files](#plan-files)
- [Logging Conventions](#logging-conventions)
- [TODO Comment Standards](#todo-comment-standards)
- [Response Status Tags](#response-status-tags)

## Writing Code

- Bias toward less code when it still solves the problem.
- Prefer standard or open source libraries/tools over reinventing them.
- Focus on solving the problem, not cleverness.
- Optimize for simplicity and speed to resolution.

## Python

**Always use `uv` for Python projects unless explicitly told otherwise.**

- Use `uv sync`, not `pip install`.
- Use `uv run python`, not `python` or `.venv/bin/python`.
- Use `uv run <tool>` for pytest, ruff, mypy, and other tools.
- Create `pyproject.toml` for dependencies, not `requirements.txt`.
- Use `uv add <package>` to add dependencies.

### Docstrings

- Trivial helpers need only a one-line summary plus Args/Returns when useful.
- Non-trivial functions require a `How:` section with numbered steps, one per logical action.
- Trigger `How:` when a function:
  - Calls an external service.
  - Tolerates multiple input shapes or SDK versions.
  - Has fallback, retry, address normalization, or other non-obvious failure behavior.
  - Performs more than roughly five steps a reader cannot reconstruct from names.
  - Is the entry point for a flow spanning multiple modules.
- Shape: summary, `How:`, Args, Returns.

## CLI Tools

Prefer modern CLI tools over legacy alternatives:

| Task | Use | Instead of |
|---|---|---|
| Find files | `fd` | `find` |
| Search content | `rg` | `grep` |

Use command examples only when they add task-specific value; avoid long command tutorials in responses.

## Documentation

- Add a Table of Contents for documentation.
- Ignore the top level or deeply nested headers using `<!-- omit in toc -->`.
- Prefer bullets and subheaders over long paragraphs, without overdoing it.
- Start with the payoff, then details. Do not add filler like "this is scalable" without concrete value.
- Always add syntax highlighting to fenced code blocks.
- Follow documentation patterns from great products.
- Provide easy copy-paste onboarding instructions.
- Do not put multiple commands plus comments in one code block. Use separate labeled blocks instead.
- Reference specific functions with `file_path:line_number`.
- Follow Keep a Changelog format for changelog updates.

## Agent Rules Integration

@~/workspace/agent-rules

- Use `/check` for comprehensive quality checks.
- Use `/commit` for structured commits with conventional format and emoji prefixes.
- Use `/implement-task` for methodical task implementation with planning phases.
- Use `/clean` to fix formatting and linting issues across a codebase.
- Use `/context-prime` to load comprehensive project understanding.

## Git Workflow Integration

- **User commits manually:** Do not ask "should I commit?" or offer to commit.
- Conventional commit format: `type(scope): description`.
- Emoji prefixes: ✨ feat, 🐛 fix, 📝 docs, ♻️ refactor.
- Run quality checks before commits.
- Do not commit during active quality check processes.

## Global Configs

**Source of truth for shell and system configuration:** `~/workspace/configs`

- `.zshrc` — main zsh entrypoint; sources all `zshrc.d/` modules in order.
- `zshrc.d/core/` — PATH setup, shared env, lazy-loaded tools.
- `zshrc.d/development/` — language toolchains (node at `005.node.sh`, python, postgres, etc.).
- `zshrc.d/ai-tools/`, `zshrc.d/cloud/`, `zshrc.d/blockchain/`, `zshrc.d/utilities/` — domain-specific config.
- `scripts/` — shell utility scripts (benchmarking, validation, optimization).
- `claude/` — Claude-specific config, sessions, skills, tasks, plans.
- `AGENTS.md` — repo-local agent notes for this config repo.

When debugging PATH, shell startup, or tool-not-found issues, check `zshrc.d/` modules first.
When modifying shell config, edit files in `~/workspace/configs/zshrc.d/` (not `~/.zshrc` directly).

## MCP Server Management

- Use `~/workspace/agent-rules/global-rules/mcp-sync.sh` to synchronize MCP configurations.
- Review configuration differences across Claude Desktop, Cursor, and VS Code.
- Switch between local development and global npm packages as needed.

## Context Loading Strategy

1. Read `README.md` and `AGENTS.md` or the tool-specific instruction file.
2. List project structure with `git ls-files | head -50`.
3. Review configuration files such as `package.json`, `pyproject.toml`, `Cargo.toml`, and equivalents.
4. Understand the development workflow before editing.

## Development Commands

**Makefile First:** Before suggesting raw commands, check `make help`.

- Prefer `make <target>` over raw commands because project Makefiles source env files, activate the right venv, and stay aligned with CI.
- Use `make help-unclassified` when a target may exist but is not listed in the main help.
- If no Makefile exists, fall back to documented commands in `AGENTS.md`, `CONTRIBUTING.md`, or `README.md`.
- If docs do not define a command, use the language-standard toolchain with the project package manager.

## Custom Skills

**Source of truth:** `~/workspace/agent-skills/skills/` is canonical for personal skills.

- When asked to update, edit, or create a skill, always work in `~/workspace/agent-skills/skills/<skill-name>/` regardless of current directory.
- When any personal skill changes, update `~/workspace/agent-skills/README.md` and relevant agent metadata so the skill stays discoverable.
- Runtime path `~/.claude/skills/` contains symlinks back to the repo via `make link-skills`; never edit runtime symlink targets directly.
- After `npx skills add olshansk/agent-skills`, run `make link-skills` in `~/workspace/agent-skills` to restore direct symlinks.
- Skill directories contain `SKILL.md` with YAML frontmatter. Most `cmd-*` skills have `disable-model-invocation: true`; `cmd-plan-store` may auto-trigger on phrases like "store this plan" or "save this plan for later".
- Naming conventions:
  - Personal global skills always use `cmd-`.
  - Repo-specific skills use the repo name prefix, or ask if ambiguous.
- See `../README.md#available-skills` for the canonical skill catalog.
- Reference skill: `cmd-makefile/` contains Makefile conventions, templates, and patterns.

## Communication Format Preferences

**Default to tables** whenever presenting structured data. Prefer a table over a bullet list whenever there are 3+ items with 2+ attributes.

**Always use color-coded severity emoji** in the leftmost column of any table that contains items needing attention. Never bury risk in prose paragraphs.

| Emoji | Severity | When to use |
|---|---|---|
| 🔴 | Critical / blocking | Stop and act now; tests broken, data loss risk, merge blocked |
| 🟠 | High | Fix before merging; likely regression or behavior change |
| 🟡 | Medium | Review soon; non-blocking but needs eyes |
| 🟢 | Good / informational | No action needed; explicit all-clear |
| ✅ | Success | Task completed cleanly |
| ❌ | Failure | Task failed or item is broken |
| ⚠️ | Cascading / unknown | Side-effects outside the immediate scope |

**Rules:**

- Any output section that contains risk items MUST use this color system — not free-form prose.
- When a section has zero risk items, end it with an explicit 🟢 all-clear line rather than omitting the section.
- Never mix severity into bullet prose when a table fits.

**Markdown table preview files:**

- When a response includes a Markdown table that is wide or important enough to reuse/share, or has at least 4 columns or at least 6 rows, also write that table to `/tmp/table_<YYYYMMDD_HHMMSS>_<randomsuffix>.md`.
- Write the exact Markdown table the user sees, preserving links, inline code, and emoji. If the table needs context, add one short Markdown heading above it in the temp file.
- Immediately below the table in the chat response, add a preview tip using the actual file path.
- Tip format: `💡 Tip: view the formatted table by running mdtt /tmp/table_20260516_143022_a7f3.md`
- Example filename: `/tmp/table_20260516_143022_a7f3.md`
- Only show the `mdtt` tip after the file is created. Skip temp-file creation for small/simple tables, sensitive content, code/documentation examples, and tasks where the user explicitly requests no filesystem writes.

| Use case | Preferred shape |
|---|---|
| Test results | Matrix with ✅/❌/🔴/⏭️ status and one-line details |
| Before/after diffs | Feature diff table with severity emoji |
| Behavioral matrices | Config/env combinations mapped to expected behavior |
| Bug summaries | 🔴/🟡 severity + Bug, Root Cause, Fix columns |
| Cascading impact | 🔴/🟡/🟢 Risk table with File, Why, Action columns |
| Planning/comparison | Tables when comparing 3+ items across 2+ dimensions |

## General Guidelines in Code

- Be concise yet clear; do not sacrifice needed context.
- Trim comment noise while preserving meaning.
- Follow language best practices.
- Break long paragraphs or run-on sentences into bullets.
- Start standalone sentences on new lines.
- Never remove content from the original input when transforming user-provided prose unless explicitly asked.
- When responding to multiple questions or topics at once, number each item so follow-ups can reference them.
- In prose, code comments, and docs, put each numbered or lettered list item on its own line.

### Refactoring Safety

**Carry forward all write paths.** When refactoring code that persists data, verify all write paths are preserved, not only the happy-path read/response.

Audit every `db.commit()`, `db.flush()`, cache invalidation, and attribute assignment before and after extraction.

Avoid extracting a function that writes `metadata_json` into a callback that only returns data unless another finalization step writes the metadata.

## Plan Files

When asked to "save this plan for later" or "document this for later", write to the project's `plans/` directory:

```text
plans/{name}_{yyyy}_{mm}_{dd}.md
```

Example: `plans/frontend-logic-cleanup_2026_03_28.md`.

## Logging Conventions

When adding logging, establish and follow emoji plus color conventions for scannable output.

| Emoji | Level | When to use |
|---|---|---|
| `🔍` | info | Starting a long analysis, search, or extraction |
| `🔧` | info | Generating or mutating artifacts |
| `✅` | info | Successful completion with summary stats |
| `⚠️` | warning | Partial failure or non-fatal fallback |
| `🚨` | warning/error | Critical failure, data loss risk, or broken dependency |

| Color | Priority | When to use |
|---|---|---|
| Red | 🔴 High | Stop and fix now |
| Yellow | 🟡 Medium | Review soon |
| Green | 🟢 Informational | No action needed |
| Cyan | Entity names | Schema names, file names, IDs, dataset names |

## TODO Comment Standards

Use specific TODO prefixes:

| Prefix | Use |
|---|---|
| `TODO:` | General improvements or future work |
| `TODO_IMPROVE:` | Code quality and refactoring |
| `TODO_OPTIMIZE:` | Performance improvements |
| `TODO_IDEA:` | Potential features or enhancements |
| `TODO_CONSIDERATION:` | Design decisions to revisit |
| `TODO_TECHDEBT:` | Technical debt |
| `TODO_IN_THIS_PR:` | Work to complete in the current PR |
| `TODO_REMOVE_LATER:` | Temporary code removable after a named condition |
| `FIXME:` | Known bugs |
| `HACK:` | Temporary workarounds |
| `NOTE:` | Important explanations or warnings |

TODOs must include:

- What needs to be done.
- Why it is deferred or needed.
- How to implement it when useful.
- What blocks it when relevant.

When a deferred improvement, rejected suggestion, design tradeoff, or "maybe later" comes up:

1. Check whether a relevant TODO already exists.
2. If not, ask: "Should we add a TODO or TODO_{TYPE} for this? What priority/prefix?"
3. Add the TODO with proper context if confirmed.

For `TODO_REMOVE_LATER`, place the TODO directly above the temporary branch and include what can be removed, when it is safe to remove, and why the branch exists. If unsure whether behavior is temporary, use `TODO_TECHDEBT` instead.

## Response Status Tags

End every response with exactly one tag on its own line:

| Tag | Meaning |
|---|---|
| `[✅ AGENT - SUCCESS ✅]` | All done, all green |
| `[🔴 AGENT - HIT AN ERROR 🔴]` | Task failed |
| `[⚠️ AGENT - PARTIAL COMPLETION ⚠️]` | Some done, blockers remain |
| `[🤔 AGENT - NEEDS HUMAN INPUT 🤔]` | Needs decision, approval, or clarification |

Use `NEEDS HUMAN INPUT` when the user still needs to approve a plan or code that has not been committed/deployed. Use `SUCCESS` only when the requested work is fully applied. When unsure, prefer `NEEDS HUMAN INPUT`.
