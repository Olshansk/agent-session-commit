---
name: cmd-pr-test-plan
description: Generate manual test plans for PR changes — focused on hands-on verification a developer would do, not unit-test edge cases
disable-model-invocation: false
context: fork
agent: general-purpose
---

# PR Test Plan

Generate a manual test plan for the changes in the current branch. The plan should focus on what a developer/reviewer needs to **manually verify** — real user flows, integration behavior, and observable outcomes. Leave input validation, error branches, and edge cases to unit tests.

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
| `last commit` / `last 1 commit` | `git diff HEAD~1...HEAD -- <excludes>` | Changes in the most recent commit |
| `last N commits` | `git diff HEAD~N...HEAD -- <excludes>` | Changes in the last N commits |
| `entire repo` | `git ls-files \| grep -vE "\.(lock\|snap)$\|package-lock\.json\|pnpm-lock\.yaml"` | All tracked source files; no diff — generate a full application test plan covering all major flows and integration points |

For all diff commands, apply: `-- ":(exclude)*.lock" ":(exclude)package-lock.json" ":(exclude)pnpm-lock.yaml" ":(exclude)package.json"`

## Instructions

### Step 1: Determine scope

Use **Determine Scope** above to resolve the scope and get the diff (or file list for `entire repo`).

### Step 2: Gather change context

Run all of these and capture the results:

```bash
git diff $BASE_BRANCH...HEAD --name-only
git diff $BASE_BRANCH...HEAD --stat
git log $BASE_BRANCH..HEAD --oneline
```

For non-branch scopes (`unstaged`, `last N commits`), adapt the commands accordingly — replace `$BASE_BRANCH...HEAD` with the scoped range (e.g. `HEAD~N...HEAD`), and replace `git log` with `git log HEAD~N..HEAD --oneline`.

### Step 3: Detect project tooling

Check what's available in the project so you can reference real commands (not generic guesses):

- **Makefile targets**: `make help 2>/dev/null || grep -E '^[a-z_-]+:.*##' Makefile makefiles/*.mk 2>/dev/null`
- **Package manager**: Look for `pyproject.toml` (uv/pip), `package.json` (npm/pnpm), `Cargo.toml` (cargo), `go.mod` (go)
- **Test runners**: Look for `pytest.ini`, `pyproject.toml [tool.pytest]`, `jest.config.*`, `.mocharc.*`
- **Project docs**: Read `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, or `README.md` for project-specific test/build instructions
- **CI config**: Check `.github/workflows/`, `Makefile`, or `Taskfile.yml` for existing test commands

**Prefer project Makefile targets and documented commands over raw tool invocations.** If the project has `make test_unit`, use that instead of `uv run pytest tests/unit/`.

### Step 4: Categorize changes and confirm with user

Group changed files into categories. Common categories (adapt based on actual changes):

- **Feature code** -- new commands, API routes, services, UI components
- **Configuration / docs** -- config files, markdown, schemas, manifests
- **Tests** -- new or modified test files
- **Build / deploy** -- Makefiles, CI, Dockerfiles, scripts
- **Deletions** -- removed files or deprecated code

Present the detected categories to the user with a summary of what changed in each. Ask them to confirm or adjust before generating the full plan.

Example confirmation format:

```
I found 3 change areas in this branch:

1. CLI agent mode -- new --agent flag on setup command (cli/commands/setup.py, cli/cli.py)
2. Skills restructuring -- SKILL.md rewrite, new reference docs, deleted shell scripts
3. Test fixes -- E2E test stability improvements (4 test files)

Should I generate the test plan for all 3, or would you like to adjust?
```

### Step 5: Generate the test plan

For each confirmed category, generate a test section following these rules:

#### Severity & importance markers

Tag every test step with one of these emojis in the step title:

| Emoji | Meaning | When to use |
|-------|---------|-------------|
| 🔴 | **Critical** | Core functionality — if this fails, the feature is broken |
| 🟢 | **Expected** | Standard behavior that should work — moderate confidence but worth verifying |
| 🔵 | **Nice-to-have** | Polish, UX, non-blocking — skip if short on time |

Example: `1a. 🔴 **Pre-register a profile end-to-end**`

#### Formatting rules

- **Numbered sections** with separator lines (`---`) between them
- **Numbered sub-steps** within each section (1a, 1b, 1c...)
- Each sub-step has an **emoji tag + bold title** describing what to test
- Each sub-step has a **copy-paste command** in a fenced code block (or manual UI steps if applicable)
- Each sub-step has a **"Verify:"** line stating what success looks like
- **One command per code block** -- never stack multiple commands in one block with comments between them
- Use **Makefile targets** when available instead of raw tool commands
- For commands requiring env vars, put them inline: `GROVE_API_URL=http://localhost:8000 make test_e2e_suite`

#### What to focus on (and what to skip)

**DO include — things you must verify manually:**
- Happy-path user flows end-to-end (the main thing the feature does)
- Integration points — does component A actually talk to component B correctly?
- State transitions — does data persist, propagate, and display correctly across the system?
- Resumption / retry behavior — if a multi-step process fails midway, does retry work?
- UI rendering — does the new section/field/page show up and look right?
- API response shape — do new fields appear in real responses?
- Existing behavior preserved — does the change break anything that was already working?

**DO NOT include — leave these for unit tests:**
- Invalid input validation (wrong types, missing fields, malformed data)
- Boundary values and off-by-one checks
- Error message wording verification
- Permission/auth edge cases (401/403 responses)
- Schema validation failures

#### Failure-path test column

For any changed file that has multi-phase logic (e.g., validate → external I/O → DB write), add a "Failure-path" column to the test coverage table:

```
| File Changed           | Unit | Integration | E2E | Failure-path |
|------------------------|------|-------------|-----|--------------|
| routes/account.py      | ❌   | ❌          | ✅  | ❌           |
| db/display_names.py    | ✅   | ❌          | ❌  | ⏭️           |
```

**The "Failure-path" column** asks: does at least one test inject a failure into a *non-first* phase of multi-phase work?

- For a route that does `verify token → DB read → external API call → DB write`, a failure-path test mocks the external API to raise and asserts the route logs context and returns a typed error (not a silent 500).
- Mark `⏭️` only for files with no exception-bearing branches (pure utilities, type definitions).
- For route handlers and DB helpers with multi-step logic, `❌` is the default until a test exists.

#### Quick smoke test section

Always end with a "Quick Smoke Test" section -- the 2-3 commands a reviewer would run if they only have 60 seconds. Tag each with the appropriate emoji.

### Step 6: Write output

1. **Write the plan** to `TEST_PLAN.md` in the repo root
2. **Print a summary** to the terminal showing the section count and a one-liner per section

Terminal summary format:

```
Wrote TEST_PLAN.md with 4 sections:

  1. CLI Agent Mode -- 4 test steps (🔴×2, 🟢×1, 🔵×1)
  2. Skills Restructuring -- 3 test steps (🔴×1, 🟢×2)
  3. Automated Tests -- 2 test steps (🟢×2)
  4. Quick Smoke Test -- 3 commands

Run `cat TEST_PLAN.md` to view the full plan.
```

## Style Reference

Follow the same style used in `cmd-pr-description`:
- **Bold the what**, plain text the how
- No fluff -- every step must verify something real that a human needs to see
- Copy-paste ready -- a reviewer should never need to edit a command
- Separate code blocks -- one command per block, bold header above it
