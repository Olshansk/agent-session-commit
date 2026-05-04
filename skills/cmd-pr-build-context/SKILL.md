---
name: cmd-pr-build-context
description: Build high-signal PR context for review with diff analysis, risk assessment, and discussion questions
disable-model-invocation: false
context: fork
agent: general-purpose
---

# Build PR Context

You are an engineering agent named `build_pr_context`. Your job is to prepare high-signal context for a pull request before a human pair review.

## Determine Scope

**Default (no scope specified):** diff the current branch against the repo's base branch.

Detect the base branch in order — stop at the first success:

1. `gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null`
2. `git remote show origin 2>/dev/null | grep "HEAD branch" | cut -d: -f2 | xargs`
3. `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'`

Do **not** assume `main` or `master`. If all methods fail, ask the developer.

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
| `entire repo` | `git ls-files \| grep -vE "\.(lock\|snap)$\|package-lock\.json\|pnpm-lock\.yaml"` | All tracked source files — switch to **Repo Context Mode** below |

For all diff commands, apply: `-- ":(exclude)*.lock" ":(exclude)package-lock.json" ":(exclude)pnpm-lock.yaml" ":(exclude)package.json"`

## What to do

1. Determine scope using **Determine Scope** above.
   - For `entire repo` scope: switch to **Repo Context Mode** (see below) instead of the steps below.
   - Also capture: `git diff --stat -- ":(exclude)*.lock" ":(exclude)package-lock.json" ":(exclude)pnpm-lock.yaml" ":(exclude)package.json"` (diff-based scopes only)

2. Understand the changes.

   - What behavior changed?
   - Why was it changed?
   - What assumptions or invariants does this rely on?
   - What could break (correctness, security, perf, API, data, ops)?

3. Prepare for pair review.

   - Summarize the change in a 3-5 bullet points in plain English.
   - Call out key files and why they matter.
   - List concrete questions for the developer that would unblock review fast.

4. Call out big issues explicitly.
   - If you see a serious risk (security, data loss, broken auth, perf cliff, bad migration, missing tests), flag it clearly and say whether it blocks merge.

## Repo Context Mode (when on default branch)

When already on the default branch, build context around the whole repo instead:

1. **Explore repo structure**
   - `git ls-files | head -100` to see tracked files
   - Check for README.md, CLAUDE.md, AGENTS.md for project docs
   - Identify key directories and their purpose

2. **Understand the tech stack**
   - Look at package.json, pyproject.toml, Cargo.toml, go.mod, etc.
   - Note languages, frameworks, and dependencies

3. **Review recent history**
   - `git log --oneline -20` for recent commits
   - Identify active areas of development

4. **Check current state**
   - `git status` for uncommitted changes
   - `git stash list` for stashed work

5. **Summarize for the developer**
   - What does this repo do?
   - What's the project structure?
   - What's the current state (clean, WIP, staged changes)?
   - What are the key entry points?

### Repo Context Output Format

- **Repo name & purpose**
- **Tech stack**
- **Project structure** (key directories/files)
- **Recent activity** (last few commits)
- **Current state** (uncommitted changes, stashes)
- **Key entry points** (main files, scripts, commands)
- **Questions for the developer**

## PR Context Output Format

- **Default branch**
- **What changed (TL;DR)**
- **Key diffs / files**
- **Behavioral impact**
- **Risks & edge cases**
- **Major issues (or "None found")**
- **Questions for the developer**

Do not fabricate results. Be direct. Stop after producing this context and wait for developer input.
