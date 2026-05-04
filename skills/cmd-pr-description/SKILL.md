---
name: cmd-pr-description
description: Generate a PR title and description, then commit, create/update the PR on approval
disable-model-invocation: false
---

# Quick PR Description <!-- omit in toc -->

Generate a concise PR description by analyzing the diff against a base branch.

Output the result in a markdown file named `PR_DESCRIPTION.md`.

Copy to clipboard: `cat PR_DESCRIPTION.md | pbcopy`

- [Determine Scope](#determine-scope)
- [Instructions](#instructions)
  - [1. Determine the base branch](#1-determine-the-base-branch)
  - [2. Analyze the changes](#2-analyze-the-changes)
  - [3. Generate the title and description using the format below](#3-generate-the-title-and-description-using-the-format-below)
  - [4. Ask user to approve, edit, or reject](#4-ask-user-to-approve-edit-or-reject)
  - [5. On approval: commit, create/update PR](#5-on-approval-commit-createupdate-pr)
- [Title Format](#title-format)
- [Output Format](#output-format)
- [Section Rules](#section-rules)
  - [tl;dr](#tldr)
  - [Summary](#summary)
  - [Feature Diff](#feature-diff)
  - [Details](#details)
  - [General Details](#general-details)
- [Example Output](#example-output)

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
| `entire repo` | `git ls-files \| grep -vE "\.(lock\|snap)$\|package-lock\.json\|pnpm-lock\.yaml"` | All tracked source files — generate a **codebase overview description** instead of a diff-based PR description |

For all diff commands, apply: `-- ":(exclude)*.lock" ":(exclude)package-lock.json" ":(exclude)pnpm-lock.yaml" ":(exclude)package.json"`

## Instructions

### 1. Determine the base branch

**If the user passed a branch name as an argument** (e.g. `/cmd-pr-description feature-branch`), use that as `BASE_BRANCH`. Skip auto-detection entirely.

**For `entire repo` scope:** skip diff analysis; use `git ls-files` and the repo's README/entry points to generate a codebase overview description. Jump directly to Step 3 with that as your source material.

**Otherwise**, use the detection methods in **Determine Scope** above to set `BASE_BRANCH`.

**Validation:** Verify `BASE_BRANCH` exists before proceeding:

```bash
git rev-parse --verify "$BASE_BRANCH" 2>/dev/null || git rev-parse --verify "origin/$BASE_BRANCH" 2>/dev/null
```

If the branch does not exist locally or on the remote, stop and ask the user to confirm the branch name.

### 2. Analyze the changes

```bash
git diff $BASE_BRANCH...HEAD --stat -- ":(exclude)*.lock" ":(exclude)package-lock.json" ":(exclude)pnpm-lock.yaml" ":(exclude)package.json"
git log $BASE_BRANCH..HEAD --oneline
```

### 3. Generate the title and description using the format below

Generate both a **PR title** (see [Title Format](#title-format)) and the full description body (see [Output Format](#output-format)).

Write the description to `PR_DESCRIPTION.md` and display both the title and description to the user.

### 4. Ask user to approve, edit, or reject

Use `AskUserQuestion` to present the generated title and description. Prefix the prompt with an emoji (e.g., `⏳`, `🤔`, or `📝`) and use square-bracketed numeric option labels so the user can reply with `[1]`, `[2]`, or `[3]`:

> ⏳ Please review and choose one:
>
> - **[1] Approve** as-is
> - **[2] Request changes** (provide feedback, re-generate)
> - **[3] Reject** (stop here)

Do NOT proceed to step 5 until the user explicitly approves.

### 5. On approval: commit, create/update PR

Once the user approves, execute the following steps in order:

**Step 5a — Commit unstaged changes (if any):**

```bash
git add -A && git commit -m "<generated title>"
```

If there are no unstaged/staged changes, skip this step.

**Step 5b — Push the branch:**

```bash
git push -u origin HEAD
```

**Step 5c — Create or update the PR:**

Check if a PR already exists for the current branch:

```bash
gh pr view --json number 2>/dev/null
```

If a PR exists, update it:

```bash
gh pr edit --title "<generated title>" --body "$(cat PR_DESCRIPTION.md)"
```

If no PR exists, create one. Always pass `--base` so the PR targets the correct branch (especially important when the base is not the repo default):

```bash
gh pr create --base "$BASE_BRANCH" --title "<generated title>" --body "$(cat PR_DESCRIPTION.md)"
```

## Title Format

PR titles must follow this format:

```
[KEYWORD] Summary
```

**Rules:**

- `KEYWORD` is an uppercase word that best categorizes the PR — not a fixed list. Common examples: `FEAT`, `FEATURE`, `FIX`, `BUG`, `REFACTOR`, `TECHDEBT`, `DOCS`, `TEST`, `CHORE`, `PERF`, `PERFORMANCE`, `CI`, `BUILD`, `STYLE`, `CLI`, `CONFIG`, `MIGRATION`, `SECURITY`, `API`, `UI`, `INFRA`
- Pick whichever keyword most accurately describes the PR — invent a new one if none of the above fit
- `Summary` is a concise imperative phrase (e.g., "Add session-based auth", "Fix null pointer in user lookup")
- Max 70 characters total
- No period at the end

**Examples:**

- `[FEAT] Add session-based authentication`
- `[FIX] Resolve race condition in queue worker`
- `[REFACTOR] Simplify middleware chain`
- `[DOCS] Update API reference for v2 endpoints`

## Output Format

```markdown
_tl;dr Single sentence, 120 characters max, summarizing the most important outcome of this PR._

## Summary

- **Subject/topic**: < 100 character explanation
- ...
- ...

## Feature Diff

| S    | Component                          | Before                                     | After                                    |
| ---- | ---------------------------------- | ------------------------------------------ | ---------------------------------------- |
| 🟢/🔴/… | 1-3 words describing the component | 1 sentence describing how it worked before | 1 sentence describing how it works after |
| …    | ...                                | ...                                        | ...                                      |

> 🔴 Critical fix · 🟡 Improvement · 🟢 New feature · ⚪ Neutral · ⚙️ Infra/tooling · ⚠️ Breaking

## Details

<details>
<summary>Technical Details</summary>

### Subsection Title

- **Subject/topic**: < 100 character explanation
- ...

### Another Subsection

- **Subject/topic**: < 100 character explanation
- ...

</details>
```

## GitHub Admonitions

Use [GitHub admonitions](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts) at the **very top** of the description (before the tl;dr) when the PR has important context that reviewers need upfront. Do NOT use admonitions by default — only when one of the situations below applies.

**Syntax:**

```markdown
> [!NOTE]
> Useful information that users should know, even when skimming content.

> [!TIP]
> Helpful advice for doing things better or more easily.

> [!IMPORTANT]
> Key information users need to know to achieve their goal.

> [!WARNING]
> Urgent info that needs immediate user attention to avoid problems.

> [!CAUTION]
> Advises about risks or negative outcomes of certain actions.
```

**When to use each type:**

| Type | When to use |
|------|-------------|
| `NOTE` | PR is a follow-up/review of another PR, replaces a previous approach, or has non-obvious scope context |
| `TIP` | PR unlocks a workflow or has a recommended migration/adoption path reviewers should know |
| `IMPORTANT` | PR requires a specific merge order, has deployment prerequisites, or needs coordinated rollout |
| `WARNING` | PR includes a breaking change, requires a migration, or has a tight deadline |
| `CAUTION` | PR touches sensitive systems (auth, billing, data deletion) or has irreversible side effects |

**Rules:**
- Maximum ONE admonition per PR description (pick the most important)
- Keep it to 1-3 sentences — enough context to orient the reviewer, not a full explanation
- Reference related PRs/issues by number (e.g., #509) so GitHub auto-links them
- Place BEFORE the tl;dr line

## Section Rules

### tl;dr

- Single sentence, **120 characters max** (hard ceiling)
- Product-level: what does the user/operator/developer get?
- No implementation details, no file names

### Summary

- 2-5 bullets, one per meaningful change (not per file)
- Min (2) and max (5) are hard floors and ceilings per section
- Bold phrase answers "what does the user/operator get?"
- Plain language after the dash: one sentence, no jargon
- No implementation details: reviewers will read the diff for that
- No fluff: skip "minor cleanup", "refactor", "update docs" unless they deliver real value
- **Order by priority/impact, highest first** — the first bullet should be the most important change in the PR
- Use backticks for code references: file names, paths, commands, config keys, env vars, endpoints, function names

### Feature Diff

- **Always include this section**
- Should have anywhere from 1-10 rows depending on the size of the PR
- One row per component, module, config, API, or behavior that changed
- "Component" = the thing that changed (endpoint, table, config key, module, behavior, etc.)
- "Before" = previous state, or `N/A` if new
- "After" = new state, or `Removed` if deleted
- Keep cells concise — short phrases, not sentences
- Group related rows; aim for 3-10 rows
- Good component examples: API endpoint, DB table/column, config key, env var, dependency version, CLI flag, permission, error behavior
- Use backticks for code references in Component, Before, and After cells (e.g., `sessions` table, `/auth/login`, `TOKEN_TTL`)
- **Legend**: Always include a one-line legend below the Feature Diff table as a blockquote: `> 🔴 Critical fix · 🟡 Improvement · 🟢 New feature · ⚪ Neutral · ⚙️ Infra/tooling · ⚠️ Breaking`
- **Severity column (S)**: Every row must have a severity emoji as the first column:

| Emoji | Label | When to use |
|-------|-------|-------------|
| 🔴 | Critical fix | Bug fix for broken/incorrect behavior |
| 🟡 | Improvement | Enhancement to existing behavior |
| 🟢 | New feature | Net-new capability |
| ⚪ | Neutral | Config, docs, chore, cleanup |
| ⚙️ | Infra/tooling | CI, build, dev tooling changes |
| ⚠️ | Breaking | Breaking change or deprecation |

### Details

- **Only include for larger PRs** (5+ files changed or multiple logical groups)
- Use collapsible `<details>` tags
- Group by feature/concern, not by file
- This is where implementation specifics go (file names, function names, migration details)
- Use backticks for code references (`file.py`, `get_user()`, `/api/v1/users`)
- 1-3 subsections, each with 3-5 bullets

### General Details

- **Use backticks everywhere for code references** — this applies to ALL sections (tl;dr excluded): file names (`file.py`), file paths (`src/auth/`), commands (`npm run build`), config keys (`TOKEN_TTL`), env vars (`NODE_ENV`), endpoints (`/api/v1/users`), function names (`getUser()`), table/column names (`sessions.token`)
- Italicize or bold keywords if it helps readability

## Example Output

```markdown
_tl;dr Users can now log in with email/password and stay authenticated across browser sessions._

## Summary

- **Session-based login**: Users authenticate with email/password and maintain sessions across browser restarts
- **Faster auth checks**: Session lookups use an indexed `token` column instead of scanning the full `users` table
- **Remember-me support**: Users can opt into 30-day sessions instead of the default 24-hour expiry

## Feature Diff

| S    | Component        | Before                     | After                                           |
| ---- | ---------------- | -------------------------- | ----------------------------------------------- |
| 🟢 | Auth method      | API key only               | Email/password + session cookie                 |
| 🟢 | Session duration | `N/A`                      | 24 hours (default), 30 days (remember-me)       |
| 🟢 | `sessions` table | `N/A`                      | New table with `user_id`, `token`, `expires_at` |
| 🟡 | Token lookup     | Full table scan on `users` | Indexed lookup on `sessions.token`              |
| 🟢 | `/auth/login`    | `N/A`                      | New endpoint                                    |
| 🟢 | `/auth/logout`   | `N/A`                      | New endpoint                                    |

> 🔴 Critical fix · 🟡 Improvement · 🟢 New feature · ⚪ Neutral · ⚙️ Infra/tooling · ⚠️ Breaking

## Details

<details>
<summary>Technical Details</summary>

### Authentication Service

- **New login service**: Handles JWT issuance, session creation, and cookie management
- Add `login_service.py` with session create/validate/revoke methods
- Integrate `/auth/login` and `/auth/logout` endpoints in `routes/auth.py`
- Support `remember_me` flag to toggle 24h vs 30d expiry

### Database Schema

- **New sessions table**: Stores active sessions with automatic expiry
- Add `sessions` table with `user_id`, `token`, `expires_at` columns
- Add B-tree index on `token` for O(1) lookups
- Add index on `expires_at` for cleanup job performance

</details>
```
