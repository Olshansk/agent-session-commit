---
name: cmd-pr-gh-comments
description: Holistically triage and resolve GitHub PR review comments — gather comments with full line ranges, study surrounding code context (TODOs, docstrings, related logic), hunt for adjacent improvements via rg, execute an approval-gated plan, optionally refine AGENTS.md style rules, and propose cmd-olshanskify template updates when feedback comes from @olshansk
disable-model-invocation: false
---

# Tend to GitHub PR Comments <!-- omit in toc -->

Pull all review comments from the current branch's PR, study their surrounding context, hunt for adjacent improvements, build a holistic plan, align with the developer, then execute.

- [1. Prerequisites](#1-prerequisites)
- [2. Identify the PR](#2-identify-the-pr)
- [3. Pull All Comments (with Line Ranges)](#3-pull-all-comments-with-line-ranges)
- [4. Gather Surrounding Context](#4-gather-surrounding-context)
- [5. Hunt for Adjacent Improvements](#5-hunt-for-adjacent-improvements)
- [6. Build the Holistic Plan](#6-build-the-holistic-plan)
- [7. Execute the Plan](#7-execute-the-plan)
- [8. Ask to Resolve Threads](#8-ask-to-resolve-threads)
- [9. Ask to Refine AGENTS.md Style](#9-ask-to-refine-agentsmd-style)
- [10. Ask to Update cmd-olshanskify Code Template](#10-ask-to-update-cmd-olshanskify-code-template)
- [11. Wrap Up](#11-wrap-up)

## 1. Prerequisites

Verify the environment is ready.

**Check authentication:**

```bash
gh auth status
```

If not authenticated, stop and tell the user to run `gh auth login`.

**Check current branch:**

```bash
git branch --show-current
```

Confirm you are not on the default branch. If you are, stop and ask the user to check out their feature branch.

## 2. Identify the PR

**Get PR details:**

```bash
gh pr view --json number,url,headRefName,baseRefName
```

If no PR exists for the current branch, stop and tell the user.

**Get repo owner/name:**

```bash
gh repo view --json nameWithOwner -q '.nameWithOwner'
```

Parse this into `{owner}` and `{repo}` for API calls below.

## 3. Pull All Comments (with Line Ranges)

Fetch every comment type and capture the full location span for each one.

**Inline review comments:**

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate
```

**Review-level comments:**

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews --paginate
```

**General PR conversation comments:**

```bash
gh api repos/{owner}/{repo}/issues/{pr_number}/comments --paginate
```

**Get current user for filtering:**

```bash
gh api user -q '.login'
```

For each inline comment, extract:

- `id`, `node_id`, `user.login`, `body`, `created_at`, `in_reply_to_id`
- `path`
- `start_line` (nullable — present for multi-line comments)
- `line` (the end line of the comment anchor)
- `original_start_line`, `original_line` (fallbacks if the comment is outdated)
- `start_side`, `side` (`LEFT` = base, `RIGHT` = head)
- `diff_hunk`
- `position` (null → comment is outdated)

Normalize every comment into `{file, start_line, end_line, side}` — if `start_line` is null, use `line` for both. This span is the **context window** used in the next step.

**Filter out:**

- Bot comments (`user.type == "Bot"`)
- Already-resolved threads

**Note:** Do NOT filter out comments authored by the current user. Users often leave self-review notes as action items.

**Group** inline review comments into threads by `in_reply_to_id`. The latest comment in a thread determines the thread's status.

If zero comments remain after filtering, report "No open PR comments to address" and stop.

## 4. Gather Surrounding Context

For each comment, read beyond the exact line range so the plan accounts for nearby intent, not just the flagged snippet.

For each `{file, start_line, end_line}`:

1. **Read a widened window.** Read the file with roughly 30 lines of padding on each side of the comment span. This captures the enclosing function, struct, or block.
2. **Scan for signals** inside that window and record them alongside the comment:
   - `TODO`, `TODO_*`, `FIXME`, `HACK`, `NOTE`, `XXX` markers
   - Docstrings / godocs / JSDoc immediately above the enclosing symbol
   - Inline comments explaining intent, invariants, or workarounds
   - Deprecation markers, feature flags, or version gates
   - Recently touched siblings in the same file (use `git blame -L start,end <file>` if the reviewer's concern might be historical)
3. **Locate the enclosing symbol.** Identify the function/method/class/struct that owns the commented lines — the plan should reason at that granularity, not just the flagged expression.
4. **Note cross-references.** If the comment references another symbol (e.g. "this duplicates `FooBar`"), mark it as a lookup target for the next step.

Record the gathered context as a compact note per comment — it feeds both the plan and the adjacent-improvement hunt.

## 5. Hunt for Adjacent Improvements

Look outside the PR diff for related code that would benefit from the same fix, using `rg` (ripgrep) and any signals from the user or from step 4.

For each comment, especially those classified as systemic (naming, pattern, anti-pattern, missing validation, etc.):

**Search for duplicates / siblings of the flagged pattern:**

```bash
rg "<pattern or symbol from the comment>" -n --hidden
```

**Search for related TODOs that would be closed by the same fix:**

```bash
rg "TODO|FIXME|HACK" -n <relevant_dir>
```

**Search for callers of the enclosing symbol** to see whether a fix ripples:

```bash
rg "\b<symbol>\b" -n -t <language>
```

**Ask the user** when signal is ambiguous:

> I see the reviewer flagged `<X>` at `<file>:<lines>`. Before planning, is there a broader pattern you'd like me to sweep for (e.g. other call sites, similar abstractions, sibling modules)? Or any area you explicitly want me to leave alone?

Collect each finding as an **adjacent improvement candidate** tagged with the originating comment. These do not become mandatory fixes — they become proposals in the plan that the user can accept, defer, or reject.

## 6. Build the Holistic Plan

Now classify every comment and merge in the adjacent improvements so the plan is one coherent pass, not a comment-by-comment checklist.

| Category | Description | Example |
|---|---|---|
| **Fix** | Clear, actionable code change requested | "This should use `===` not `==`" |
| **Investigate** | Needs codebase exploration before deciding | "Is this duplicated anywhere else?" |
| **Discuss** | Design question, trade-off, or needs clarification | "Should we use strategy A or B here?" |
| **Acknowledge** | FYI or praise, no action needed | "Nice refactor" |
| **Outdated** | Comment on code that has already changed | `position` is null or diff hunk no longer matches |

**Rules:**

- For **Fix** items, cite the real current file contents (not the diff hunk) when proposing a change.
- Group related comments that share a root cause into a single plan item.
- Surface **adjacent improvements** from step 5 as their own numbered proposals under each originating comment, each flagged `[adjacent]` and marked opt-in.
- Do not execute anything yet.

**Present the plan** to the user in this format:

```markdown
## PR Comment Triage: {pr_url}

### Fix ({count})
- [ ] **{file}:{start_line}-{end_line}** — {summary of what to change}
  > {abbreviated reviewer comment}
  - Context: {enclosing symbol, TODO/NOTE hits, relevant docstring}
  - [adjacent, opt-in] {related site at other_file:lines} — {why it may want the same fix}

### Investigate ({count})
- [ ] **{file}:{start_line}-{end_line}** — {what to explore and why}
  > {abbreviated reviewer comment}

### Discuss ({count})
- [ ] **{file}:{start_line}-{end_line}** — {question or design decision}
  > {abbreviated reviewer comment}

### Acknowledge ({count})
- {comment summary} — propose resolving, no action needed

### Outdated ({count})
- {comment summary} — code has changed, propose resolving

### Adjacent Improvements (opt-in)
- [ ] {file:lines} — {summary, tied back to originating comment}
```

Then ask:

> Here is the holistic plan for this PR's comments plus adjacent improvements I noticed. Do you want to:
> 1. Proceed as-is
> 2. Reclassify any items (e.g. move a Fix to Discuss)
> 3. Skip specific items or adjacent improvements
> 4. Add anything I missed
>
> Let me know before I start making changes.

**Do not proceed until the user confirms.**

## 7. Execute the Plan

Work through the approved plan in this order:

1. **Fix** items first — make code changes one at a time, grouped by file when possible.
2. **Adjacent improvements** the user accepted — apply them alongside the originating fix so the change is coherent.
3. **Investigate** items — explore, then either fix or surface findings to the user.
4. **Discuss** items — present findings and context, ask the user for direction.

If an Investigate or Discuss item becomes clear during execution, reclassify it to Fix and proceed.

After all items are addressed, show a summary:

```markdown
## Changes Made

| File | Lines | Category | Action Taken |
|------|-------|----------|--------------|
| ... | ...-... | Fix | Changed X to Y |
| ... | ...-... | Fix [adjacent] | Applied same fix at sibling site |
| ... | ...-... | Investigate | Found Z, no change needed |
| ... | ...-... | Discuss | User decided to defer |
```

## 8. Ask to Resolve Threads

**Do not auto-resolve.** Ask the user first.

> I'm ready to resolve the following {N} GitHub comment threads:
> - {short list grouped by category}
>
> Thumbs up to resolve all, or tell me which ones to keep open.

If the user gives a thumbs up (or names a subset), resolve those threads. Otherwise skip this step.

For each thread to resolve, look up the thread ID from the comment's `node_id`:

```bash
gh api graphql -f query='
query($nodeId: ID!) {
  node(id: $nodeId) {
    ... on PullRequestReviewComment {
      pullRequestReviewThread: thread {
        id
        isResolved
      }
    }
  }
}' -f nodeId="{comment_node_id}"
```

Then resolve:

```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread {
      isResolved
    }
  }
}' -f threadId="{thread_id}"
```

## 9. Ask to Refine AGENTS.md Style

After threads are resolved (or skipped), look across the comments you just addressed for recurring themes — style rules, naming conventions, review preferences, pattern prohibitions — that would belong in `AGENTS.md` so future PRs avoid the same feedback.

Ask the user:

> Based on these comments, I noticed a few patterns that could become durable rules (e.g. {one-line examples}). Want me to look for opportunities to improve the style guidance in `AGENTS.md`?

If **yes**:

1. Locate the relevant `AGENTS.md` (repo root first, then `~/.claude/CLAUDE.md` / `~/workspace/agent-skills/agents/AGENTS.md` if the user wants a global rule).
2. Draft a concrete diff — new bullet(s) or section, written in the existing tone.
3. Present the proposed edit and ask for approval **before** writing. Do not edit `AGENTS.md` without explicit confirmation.

If **no**: skip this step.

## 10. Ask to Update cmd-olshanskify Code Template

**Trigger condition:** one or more of the addressed comments were authored by `@olshansk` (the user). Determine this from each comment's `user.login` field captured in step 3. If no `@olshansk` comments are in scope, skip this step entirely.

When the condition is met, re-read the `@olshansk` comments you just addressed and look for durable, style-level signal — phrasing preferences, banned patterns, required conventions, TODO tagging rules — that belongs in the canonical code style template at `~/workspace/agent-skills/skills/cmd-olshanskify/templates/code.md`.

Ask the user:

> {N} of the resolved comments came from `@olshansk`. I spotted {K} that read like durable style rules (e.g. {one-line examples}). Want me to propose updates to `cmd-olshanskify/templates/code.md` so future code dodges the same feedback?

If **yes**:

1. Read `~/workspace/agent-skills/skills/cmd-olshanskify/templates/code.md` end-to-end.
2. For each candidate rule, check whether it is already covered. Skip duplicates; refine wording only when the new phrasing is clearly sharper.
3. Draft a concrete diff — new bullet(s) or a new subsection, written in the template's existing tone (short, imperative, grouped under the right heading).
4. Present the proposed edit inline and ask for approval **before** writing. Do not edit the template without explicit confirmation.
5. If the rule is not code-specific (e.g. it's about documentation phrasing or presentation voice), propose updating `templates/docs.md`, `templates/blog.md`, or `templates/presentation.md` instead — or suggest a brand-new template if no existing one fits.

If **no**: skip this step.

## 11. Wrap Up

Report final status:

```markdown
## Done

- {N} comments addressed ({K} adjacent improvements included)
- {M} threads resolved on GitHub ({skipped} kept open)
- AGENTS.md: {updated | proposed | skipped}
- cmd-olshanskify templates: {updated | proposed | skipped | n/a — no @olshansk comments}
- PR: {pr_url}
```

**Do not commit or push automatically.** The user commits manually — see the global rule in `~/.claude/CLAUDE.md` under "Git Workflow Integration".
