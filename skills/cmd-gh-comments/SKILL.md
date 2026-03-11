---
name: cmd-gh-comments
description: Triage and resolve GitHub PR review comments with categorized action plans and approval-gated execution
disable-model-invocation: true
---

# Tend to GitHub PR Comments <!-- omit in toc -->

Pull all review comments from the current branch's PR, build a plan to address each one, align with the developer, then execute.

- [1. Prerequisites](#1-prerequisites)
- [2. Identify the PR](#2-identify-the-pr)
- [3. Pull All Comments](#3-pull-all-comments)
- [4. Assess and Categorize](#4-assess-and-categorize)
- [5. Present the Plan](#5-present-the-plan)
- [6. Execute the Plan](#6-execute-the-plan)
- [7. Wrap Up](#7-wrap-up)

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

## 3. Pull All Comments

Fetch three types of comments and combine them.

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

For each comment, extract: `id`, `node_id`, `user.login`, `body`, `path`, `line`/`original_line`, `diff_hunk`, `in_reply_to_id`, `created_at`.

**Filter out:**

- Comments authored by the current user
- Bot comments (`user.type == "Bot"`)
- Already-resolved threads

**Group** inline review comments into threads by `in_reply_to_id`. The latest non-author comment in a thread determines the thread's status.

If zero comments remain after filtering, report "No open PR comments to address" and stop.

## 4. Assess and Categorize

For each comment or thread, read the comment body, the referenced file at the indicated line, and the diff hunk. Classify into one of these categories:

| Category | Description | Example |
|---|---|---|
| **Fix** | Clear, actionable code change requested | "This should use `===` not `==`" |
| **Investigate** | Needs codebase exploration before deciding | "Is this duplicated anywhere else?" |
| **Discuss** | Design question, trade-off, or needs clarification | "Should we use strategy A or B here?" |
| **Acknowledge** | FYI or praise, no action needed | "Nice refactor" |
| **Outdated** | Comment on code that has already changed | Diff hunk no longer matches file |

**Rules:**

- For **Fix** items: read the actual file before proposing a change. Do not guess.
- For **Investigate** items: note what to explore but do not explore yet.
- For **Discuss** items: summarize the question and prepare to surface it.
- For **Outdated** detection: check if the `diff_hunk` still matches the current file content or if `position` is `null`.

## 5. Present the Plan

**Stop here and present the plan to the user.** Use this format:

```markdown
## PR Comment Triage: {pr_url}

### Fix ({count})
- [ ] **{file}:{line}** — {summary of what to change}
  > {abbreviated reviewer comment}

### Investigate ({count})
- [ ] **{file}:{line}** — {what to explore and why}
  > {abbreviated reviewer comment}

### Discuss ({count})
- [ ] **{file}:{line}** — {question or design decision}
  > {abbreviated reviewer comment}

### Acknowledge ({count})
- {comment summary} — will resolve, no action needed

### Outdated ({count})
- {comment summary} — code has changed, will resolve
```

Ask the user:

> Here is the plan for addressing the PR comments. Do you want to:
> 1. Proceed as-is
> 2. Reclassify any items (e.g., move a Fix to Discuss)
> 3. Skip specific items
>
> Let me know before I start making changes.

**Do not proceed until the user confirms.**

## 6. Execute the Plan

Work through the approved plan in this order:

1. **Fix** items first — make code changes one at a time
2. **Investigate** items — explore the codebase, then either fix or surface findings to the user
3. **Discuss** items — present findings and context, ask the user for direction

If an Investigate or Discuss item becomes clear during execution, reclassify it to Fix and proceed.

After all items are addressed, show a summary:

```markdown
## Changes Made

| File | Line | Category | Action Taken |
|------|------|----------|--------------|
| ... | ... | Fix | Changed X to Y |
| ... | ... | Investigate | Found Z, no change needed |
| ... | ... | Discuss | User decided to defer |
```

## 7. Wrap Up

Ask the user:

> All comments have been addressed. Ready to:
> 1. Commit with message "Tended to github comments"
> 2. Push to remote
> 3. Resolve the addressed comment threads on GitHub
>
> Proceed with all three? Or would you like to review the changes first?

**Do not proceed until the user confirms.**

**Commit and push:**

```bash
git add <specific changed files>
```

```bash
git commit -m "Tended to github comments"
```

```bash
git push
```

**Resolve comment threads** using the GraphQL API. For each addressed thread (Fix, Acknowledge, Outdated categories), get the thread ID from the comment's `node_id`:

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

Skip resolution for **Discuss** items the user deferred.

**Report final status:**

```markdown
## Done

- {N} comments addressed
- {M} threads resolved on GitHub
- Commit: {short_sha}
- PR: {pr_url}
```
