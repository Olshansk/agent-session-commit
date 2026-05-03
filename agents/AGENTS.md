# Olshansky's AGENTS.md <!-- omit in toc -->

- [Writing Code](#writing-code)
- [Python](#python)
- [CLI Tools (Search & Find)](#cli-tools-search--find)
- [Documentation](#documentation)
- [Agent Rules Integration](#agent-rules-integration)
- [Git Workflow Integration](#git-workflow-integration)
- [MCP Server Management](#mcp-server-management)
- [Context Loading Strategy](#context-loading-strategy)
- [Custom Skills](#custom-skills)
- [General Guidelines in code](#general-guidelines-in-code)
- [Logging Conventions](#logging-conventions)
- [TODO Comment Standards](#todo-comment-standards)
- [Response Status Tags](#response-status-tags)

## Writing Code

- Bias to writing less code if possible
- Leverage standard or open source libraries/tools rather than reinvesting the wheel
- Focus on solving the problem, not trying to be a "clever engineer"
- Be motivated by simplicity and speed to problem resolution, not "nerd sniping" anyone

## Python

**Always use `uv` for Python projects unless explicitly told otherwise.**

- Use `uv sync` instead of `pip install`
- Use `uv run python` instead of `python` or `.venv/bin/python`
- Use `uv run <tool>` for running tools (pytest, ruff, mypy, etc.)
- Create `pyproject.toml` for dependencies, not `requirements.txt`
- Use `uv add <package>` to add dependencies

## CLI Tools (Search & Find)

**Prefer modern CLI tools over legacy alternatives:**

| Task | Use | Instead of |
|------|-----|------------|
| Find files | `fd` | `find` |
| Search content | `rg` | `grep` |

**`fd` - Fast file finder:**

```bash
# Find files by extension
fd -e md                        # All markdown files
fd -e py -e pyi                 # Python files

# Find files by name pattern
fd "test_.*\.py$"               # Test files
fd -H .env                      # Include hidden files (-H)

# Find and execute
fd -e py -x wc -l               # Count lines in all Python files
```

**`rg` (ripgrep) - Fast content search:**

```bash
# Basic search
rg "TODO"                       # Search for TODO in all files
rg "def.*async" -t py           # Search in Python files only

# Context and output
rg "error" -C 3                 # Show 3 lines context
rg "pattern" -l                 # List files only (no content)
rg "pattern" -c                 # Count matches per file

# Advanced
rg "class \w+" -o               # Show only matching part
rg "import" --glob "*.py"       # Filter by glob pattern
```

**Why these tools:**
- 10-100x faster than `find`/`grep`
- Respect `.gitignore` by default
- Better defaults and ergonomics
- Colorized output

## Documentation

When writing READMes, start with the following direction:

- Table of Contents: Always add a Table of Contents for documentation
- Ignoring Headers in ToC: ignore the top level or deeply nested headers using <!-- omit in toc -->
- Language: Bias to bullet points and subheadders over paragraphs, but don't over do it.
- Content: start with the payoff and details below. Don't add content like "this is scalable" that doesn't create real value add
- Triple quotes: always add the appropriate syntax highlighting. For example: ```bash...`
- References: Use industry best practices from great products as a reference for how they write their documentation
- Copy-pasta: Provide easy-copy pasta instructions that enable developers to onboard brainlessley
- Code blocks: Never put multiple commands in a single code block with comments. Instead, use separate code blocks with bold headers:

  **Bad:**
  ```bash
  # Step 1: Do thing
  command-one

  # Step 2: Do other thing
  command-two
  ```

  **Good:**
  ```markdown
  **Do thing:**

  ```bash
  command-one
  ```

  **Do other thing:**

  ```bash
  command-two
  ```
  ```

## Agent Rules Integration

@~/workspace/agent-rules

### Common Development Commands <!-- omit in toc -->

- Use `/check` for comprehensive quality checks (linting, type checking, security)
- Use `/commit` for structured commits with conventional format and emoji prefixes
- Use `/implement-task` for methodical task implementation with planning phases
- Use `/clean` to fix all formatting and linting issues across codebase
- Use `/context-prime` to load comprehensive project understanding

### Documentation Standards <!-- omit in toc -->

- Reference specific functions with `file_path:line_number` format
- Generate LLM-optimized documentation with file references
- Follow Keep a Changelog format for changelog updates
- Include table of contents for longer documentation

### Multi-Language Quality Patterns <!-- omit in toc -->

**Python (uv):**

```bash
# Dependency management (prefer uv over pip)
uv sync --all-extras        # Install deps (not pip install)
uv run python script.py     # Run scripts (not .venv/bin/python)
uv run pytest               # Run tools through uv

# Quality checks
uv run ruff check --fix .
uv run ruff format .
uv run mypy .
```

**Python (legacy/pip):**

```bash
black .
isort .
flake8 . --extend-ignore=E203
mypy .
```

**JavaScript/TypeScript:**

```bash
npx prettier --write .
npx eslint . --fix
npx tsc --noEmit
```

**Swift:**

```bash
swift-format --in-place .
swiftlint --fix
```

## Git Workflow Integration

- **User commits manually:** Do not ask "should I commit?" or offer to commit. I prefer to review changes and commit myself.
- Conventional commit format: `type(scope): description`
- Emoji prefixes: ✨ feat, 🐛 fix, 📝 docs, ♻️ refactor
- Run quality checks before commits
- No commits during active quality check processes

## MCP Server Management

- Use `~/workspace/agent-rules/global-rules/mcp-sync.sh` to synchronize MCP configurations
- Review configuration differences across Claude Desktop, Cursor, VS Code
- Switch between local development and global npm packages

## Context Loading Strategy

1. Read README.md and AGENTS.md (or tool-specific instruction file)
2. List project structure (`git ls-files | head -50`)
3. Review configuration files (package.json, Cargo.toml, etc.)
4. Understand development workflow

## Custom Skills

**Source of truth:** `~/workspace/agent-skills/skills/` is the canonical location for all skills.

- When asked to update, edit, or create a skill, **always work in `~/workspace/agent-skills/skills/<skill-name>/`** regardless of the current working directory
- When any personal skill changes, **always update `~/workspace/agent-skills/README.md` and relevant agent metadata** so the skill stays discoverable
- Runtime path `~/.claude/skills/` contains symlinks back to the repo (via `make link-skills`)
- Edits in the repo propagate instantly through symlinks — no copy step needed

> **After `npx skills add olshansk/agent-skills`:** always run `make link-skills` in `~/workspace/agent-skills` to restore direct symlinks. npx creates copies that break the live-edit flow.

Each skill directory contains a `SKILL.md` with YAML frontmatter. Most `cmd-*` skills have `disable-model-invocation: true` (user invokes manually via `/cmd-*`). Exception: `cmd-plan-store` auto-triggers on phrases like "store this plan" / "save this plan for later".

**Naming conventions:**
- Personal global skills: always prefix with `cmd-`
- Repo-specific skills: prefix with the repo name (e.g., `grove-`, `pocket-`) or ask for a name if ambiguous

**Reference skills:**

- `cmd-makefile/` - Makefile conventions, templates, and patterns. Read `SKILL.md` for guidelines, check `templates/` for starter files.

**Task skills (invoke with `/name`):**

- `cmd-agent-persona-set` - Prime the agent with a behavioral persona for the conversation
- `cmd-code-what` - Catch the user up on what the agent CLI has been doing in 3-5 ultra-tight `**label**: explanation` bullets
- `cmd-codex-review-plan` - Pipe the current plan to `codex exec` for an outside review, then revise the plan with a changelog of accepted/rejected suggestions
- `cmd-codex-review-unstaged` - Pipe Claude's implementation summary + `git diff HEAD` to `codex exec`, get a review applying cmd-pr-follow-up + cmd-pr-edgecase methodology, then synthesize a prioritized iteration plan (apply/defer/reject)
- `cmd-docs-idiot-proof` - Simplify documentation for clarity
- `cmd-email-md` - Convert markdown to email-safe HTML with inline styles
- `cmd-gh-issue` - Create GitHub issues from conversation context
- `cmd-latest-msg` - Store or retrieve the latest agent message to /tmp/agents/{agent}/
- `cmd-olshanskify` - Apply Olshansky's personal style to docs, code, blog posts, or presentations via templates in `templates/`
- `cmd-plan-store` - Capture conversation plans/decisions into structured markdown in `plans/`
- `cmd-pr-build-context` - Build high-signal PR context for review
- `cmd-pr-conflict-resolver` - Resolve merge conflicts with 3-tier classification
- `cmd-pr-description` - Generate concise PR descriptions
- `cmd-pr-edgecase` - Review PR for test gaps, logic edge cases, failure modes
- `cmd-pr-follow-up` - Post-implementation reflection: missed work, simplifications, idiomatic fixes
- `cmd-pr-gh-comments` - Holistically triage PR comments: line-range context, adjacent-improvement sweeps, approval-gated resolution, optional AGENTS.md refinement, proposes cmd-olshanskify template updates when comments come from @olshansk
- `cmd-pr-review-prepare` - Prepare branch for code review
- `cmd-pr-scope-sweep` - Final pass to identify missed items and risks
- `cmd-pr-sculpt-code` - Reshape code quality: naming, structure, TODOs, surface area
- `cmd-pr-test-plan` - Generate manual test plans for PRs
- `cmd-productionize` - Transform apps into production-ready deployments
- `cmd-review-chain-halt` - Review protocol code for chain halt risks
- `cmd-review-rfc` - Review RFCs using SCQA framework
- `cmd-session-commit` - Capture session learnings and update AGENTS.md
- `cmd-skills-dashboard` - Scrape skills.sh and generate an interactive HTML dashboard
- `cmd-skills-local-repo` - Scaffold cross-tool repo-local skills and agent instructions
- `cmd-write-proofread` - Proofread posts for spelling, grammar, repetition, logic, and weak arguments

## Communication Format Preferences

When presenting structured comparisons, use markdown tables with emoji status columns:

- **Test results**: Matrix with ✅/❌/🔴/⏭️ status per item and one-line details
- **Before/After diffs**: Feature diff tables with severity emoji (🔴 Critical fix, 🟡 Improvement, 🟢 New feature, ⚪ Neutral, ⚙️ Infra)
- **Behavioral matrices**: Config/env combinations → expected behavior per row
- **Bug summaries**: Bug | Root Cause | Fix columns
- **Planning/comparison**: Use tables over prose whenever there are 3+ items being compared across 2+ dimensions

## General Guidelines in code

- Be concise yet clear—don't sacrifice context.
- Trim comment noise while preserving meaning.
- Follow best practices for the language in use.
- Break long paragraphs (>3 sentences) or run-on sentences into bullet points.
- Start new sentences on new lines when they stand alone.
- Never remove any content from the original input.
- When responding to multiple questions or topics at once, number each item (### 1., ### 2., etc.) so the user can easily reference specific points in follow-ups.
- In prose (including code comments and docs), put each numbered/lettered list item on its own line. Do not inline them as "either (a) foo, or (b) bar" — break to separate lines to reduce cognitive reading load.

## Plan Files

When asked to "save this plan for later" or "document this for later", write to the project's `plans/` directory using the naming convention:

```
plans/{name}_{yyyy}_{mm}_{dd}.md
```

Example: `plans/frontend-logic-cleanup_2026_03_28.md`

## Logging Conventions

When adding logging to any project, establish and follow emoji + color conventions for scannable output.

### Emoji prefixes by intent

| Emoji | Level | When to use |
|-------|-------|-------------|
| `🔍` | info | Starting a long analysis, search, or extraction |
| `🔧` | info | Generating or mutating artifacts (migrations, exports, writes) |
| `✅` | info | Successful completion — always include summary stats (count, timing) |
| `⚠️` | warning | Partial failure — some items failed, non-fatal fallback |
| `🚨` | warning/error | Critical failure — all items failed, data loss risk, broken dependency |

### Color markup for action-item prioritization

Use color markup (Rich, ANSI, or equivalent for the project's logging stack) when surfacing issues that need human attention:

| Color | Priority | When to use |
|-------|----------|-------------|
| Red | 🔴 High — stop and fix now | All files unreadable, corrupt state, empty output when data expected |
| Yellow | 🟡 Medium — review soon | Some items failed, low confidence, gaps or anomalies in data |
| Green | 🟢 Informational — no action needed | Cache hit, clean run, all items processed successfully |
| Cyan | Entity names | Always use for schema names, file names, IDs, dataset names |

### Examples (Rich markup — adapt syntax to project's logging stack)

```python
# Entry
logger.info("🔍 Starting extraction for [bold cyan]%s[/bold cyan] (%d files)", name, n)

# Clean exit
logger.info("✅ Complete for [bold cyan]%s[/bold cyan]: [bold green]%d files[/bold green] in %.2fs", name, n, elapsed)

# Partial failure
logger.warning("⚠️  [bold cyan]%s[/bold cyan]: [bold yellow]%d/%d items failed[/bold yellow]", name, errors, total)

# Critical failure
logger.error("🚨 Failed for ALL files in [bold cyan]%s[/bold cyan] — [bold red]check dependencies[/bold red]", name)
```

## TODO Comment Standards

Use specific TODO prefixes to categorize action items:

**Standard prefixes:**
- `TODO:` - General improvements or future work (default)
- `TODO_IMPROVE:` - Code quality improvements, refactoring opportunities
- `TODO_OPTIMIZE:` - Performance improvements, efficiency gains
- `TODO_IDEA:` - Potential features or enhancements to consider
- `TODO_CONSIDERATION:` - Design decisions that may need revisiting
- `TODO_TECHDEBT:` - Technical debt to address later
- `TODO_IN_THIS_PR:` - Tasks to complete within the current pull request
- `TODO_REMOVE_LATER:` - Temporary code that should be removed once a condition is met
- `FIXME:` - Known bugs or issues that need fixing
- `HACK:` - Temporary workarounds that should be replaced
- `NOTE:` - Important explanations or warnings for developers

**Required context for TODOs:**
- **What:** Clear description of what needs to be done
- **Why:** Context on why this is deferred or needed
- **How (optional):** Implementation hints if not obvious
- **Blocked (optional):** What's blocking this work

**Prompting for TODOs:**
When discussion surfaces a deferred improvement, rejected suggestion, design tradeoff,
or "maybe later" consideration, the agent should ask whether to capture it:
  "Should we add a TODO or TODO_{TYPE} for this?"

This includes cases where I say "don't do X", "skip X for now", decline a suggestion,
or ask why we are not using a more structured/idiomatic approach.

The agent should:
1. Check if a relevant TODO already exists
2. If not, ask: "Should we add a TODO or TODO_{TYPE} for this? What priority/prefix?"
3. Add the TODO with proper context if confirmed

Example:

```python
# TODO_OPTIMIZE: Implement connection pooling for better performance
#       Why: Current approach creates new connection per request
#       Blocked: Need to evaluate pgbouncer vs application-level pooling

# TODO_TECHDEBT: Refactor to use dataclasses instead of dicts
#       Why: Type safety and IDE autocomplete
#       Priority: Low - works fine, just not ideal

# TODO_IDEA: Support batch operations for bulk imports
#       Why: Users importing large datasets hit rate limits
```

**Temporary code branches (`TODO_REMOVE_LATER`):**

When adding a code branch that exists only as temporary remediation (e.g., backfilling legacy data, handling a migration edge case, supporting a deprecated path), place `TODO_REMOVE_LATER` directly above the branch entry point. Include:

- **What** can be removed (the branch and any supporting helpers)
- **When** it is safe to remove (the condition that makes it obsolete)
- **Why** the branch exists (what legacy state or transition it handles)

```python
# TODO_REMOVE_LATER: Backfill missing widget_id for pre-v2 records — remove once
#   all active records have been backfilled (tracked in JIRA-1234).
#   Why: v1 records lack widget_id; this branch synthesizes one on read.
if not record.widget_id:
    ...
```

Do NOT use `TODO_REMOVE_LATER` for permanent behavior. Only mark branches that are genuinely temporary. If unsure whether code is temporary, use `TODO_TECHDEBT` instead.

## Response Status Tags

End every response with exactly one of these tags (on its own line):

- `[✅ AGENT - SUCCESS]` - Task completed successfully, all items green
- `[✔️ AGENT - DONE]` - Task completed (neutral outcome, neither particularly good nor bad)
- `[❌ AGENT - FAILURE]` - Task attempted but failed or encountered errors
- `[🔴 AGENT - PARTIAL]` - Task partially completed; some items succeeded but others are blocked or failed. Always pair with a prominent blockers summary showing exactly what failed and why.
- `[⏳ AGENT - WAITING]` - Blocked on external process or async operation
- `[⏳ AGENT - INPUT NEEDED]` - Blocked waiting for user input, clarification, or approval
- `[🤔 AGENT - UNSURE]` - Uncertain about approach, results, or requirements; needs guidance

**Choosing the right tag:**
- If the user asked you to do something and you **proposed a plan or wrote code but haven't committed/deployed yet**, use `INPUT NEEDED` — the user still needs to confirm or say "do it"
- `DONE` / `SUCCESS` means the work is **fully applied** (committed, deployed, etc.), not just described or staged
- When in doubt between `DONE` and `INPUT NEEDED`, prefer `INPUT NEEDED` — it's cheaper to over-ask than to prematurely close the loop
