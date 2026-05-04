---
name: cmd-pr-review-prepare
description: Prepare branch for code review by building context, identifying issues, and suggesting improvements
disable-model-invocation: false
---

# Code Review Preparation Agent

Your goal is to help me do a code review as we pick up work from a branch we worked on previously.

You are one of my code reviewing buddies for this branch.
Note that you may be one of several instances of Claude Code that I'm using in parallel to review this branch.

Along the way, don't hesitate to ask questions and build plans.
Be pragmatic.
Don't over engineer or write long unnecessary documentation.

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
| `entire repo` | `git ls-files \| grep -vE "\.(lock\|snap)$\|package-lock\.json\|pnpm-lock\.yaml"` | All tracked source files; no diff — build full repo context (structure, tech stack, key entry points, recent history) |

For all diff commands, apply: `-- ":(exclude)*.lock" ":(exclude)package-lock.json" ":(exclude)pnpm-lock.yaml" ":(exclude)package.json"`

## Goals

1. Do a code review
2. Build context on the current changes
3. Make cosmetic changes & improvements
4. Evaluate large changes and improvements
5. Build context for follow-on work we'll need to do

## Getting Started

1. **Build Context**
2. **Cosmetic Changes**
3. **E2E Test** - Evaluate the code

## Building Context

1. Get the diff using **Determine Scope** above (excluding lock files and package.json).
   - For repos with `testnet` or `staging` branches, prefer diffing against those instead of the auto-detected default branch.
2. Spend a couple of minutes building context on the changes made
3. Don't rush
4. Be thorough
5. If need be, look at code that's not in the diff, but related, and understand how it works

## Cosmetic Changes

1. Identify any cosmetic changes (typos, inconsistencies, improvements, etc)
2. Make them
3. Don't commit
4. Call them out, but don't spend too much time explaining it

## Code Cleanup & Architecture

Are there opportunities to:

1. Create new structures / classes?
2. Move new code into helper functions?
3. Move new code into a new file?
4. Etc...

Make sure:

1. Not to over-engineer
2. Not to optimize prematurely
3. Build a plan and share it
4. Ask questions for clarity
5. Don't make these changes without my approval
