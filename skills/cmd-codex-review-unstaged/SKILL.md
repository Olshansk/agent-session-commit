---
name: cmd-codex-review-unstaged
description: Get a second opinion on what Claude just implemented from Codex (codex exec headless mode). Pipes Claude's summary plus the working-tree diff to codex, asks codex to leverage cmd-pr-follow-up and cmd-pr-edgecase methodology to surface bugs, test gaps, edge cases, and simplification opportunities, then synthesizes a prioritized iteration plan from the feedback. Triggers on "/cmd-codex-review-unstaged", "review my changes with codex", "have codex review what I just did", or after a non-trivial implementation pass before commit.
disable-model-invocation: false
---

# Codex Review Unstaged <!-- omit in toc -->

Use `codex exec` as an independent reviewer on the working-tree changes Claude just made. Codex sees only the summary + diff (no conversation history), so its critique catches things Claude rationalized into "good enough" during implementation. The output is a prioritized iteration plan — what to fix now, what to defer, what to reject.

- [When to use](#when-to-use)
- [Instructions](#instructions)
- [Codex prompt](#codex-prompt)
- [Output format](#output-format)
- [Notes](#notes)

## When to use

- After Claude finishes a non-trivial implementation pass and before commit
- When the user says "review my changes with codex", "have codex check what I just did", or `/cmd-codex-review-unstaged`
- As an outside cross-check before opening a PR — complements `cmd-pr-follow-up` (Claude self-review) and `cmd-pr-edgecase` (edge-case sweep) by adding a fresh pair of eyes that didn't write the code

## Instructions

### 1. Build Claude's implementation summary

Write a short summary of what was just implemented. Keep it **factual, not promotional**:

- What was the goal?
- What files changed and why?
- What design decisions were made (and what was rejected)?
- What was deliberately deferred (TODOs, follow-ups, scope cuts)?
- What was tested manually vs. covered by automated tests?

This summary anchors codex's review — without it, codex will judge the diff against a generic standard instead of the actual intent.

### 2. Capture the diff

Default scope: **`git diff HEAD`** — captures both staged and unstaged working-tree changes since the last commit.

```bash
DIFF_FILE=$(mktemp -t codex-diff.XXXXXX.patch)
SUMMARY_FILE=$(mktemp -t codex-summary.XXXXXX.md)
OUT_FILE=$(mktemp -t codex-review.XXXXXX.md)

git diff HEAD > "$DIFF_FILE"
git status --short >> "$DIFF_FILE"
```

If the user explicitly asks for unstaged-only or branch diff, swap in:
- Unstaged only: `git diff`
- Branch vs main: `git diff main...HEAD`
- Include untracked: append `git ls-files --others --exclude-standard` separately

Write the summary from step 1 verbatim to `$SUMMARY_FILE` using the Write tool.

**Sanity check before invoking codex:**
- If `$DIFF_FILE` is empty (no changes), tell the user there's nothing to review and stop.
- If the diff is enormous (>50k lines), warn the user — codex will still run but the review quality drops on huge surfaces. Suggest narrowing scope (e.g., per-file or per-phase review).

### 3. Run codex in headless review mode

```bash
codex exec \
  --sandbox read-only \
  --skip-git-repo-check \
  --color never \
  --output-last-message "$OUT_FILE" \
  "$(cat <<PROMPT
You are reviewing a working-tree diff produced by another coding agent (Claude).

You will receive two files:
- $SUMMARY_FILE — Claude's own summary of what it implemented and why
- $DIFF_FILE — the raw \`git diff HEAD\` output plus \`git status --short\`

Read both before reviewing.

You also have access to two skill methodology references (read them before forming your review — they describe what to look for):
- ~/.codex/skills/cmd-pr-follow-up/SKILL.md — post-implementation reflection methodology (incomplete tasks, idiomatic concerns, modularity, simplification, comments/prose)
- ~/.codex/skills/cmd-pr-edgecase/SKILL.md — edge case and failure mode methodology (test gaps, malformed inputs, integration risks)

Apply BOTH methodologies to this diff. Then go further: look for issues those skills do not cover.

Your job:
1. **Correctness bugs** — logic errors, off-by-ones, wrong conditionals, race conditions, incorrect API usage. Cite file:line.
2. **Test gaps** — code paths added without tests, edge cases not covered, regression risks. Cite which test file should exist or be extended.
3. **Edge cases & failure modes** — what happens with empty input, null, concurrent calls, malformed data, network failure, partial state.
4. **Adjacent improvements** — things the diff touches that could be cleaned up in the same pass (dead code nearby, stale comments, naming inconsistencies).
5. **Simplification opportunities** — over-engineering, premature abstraction, defensive code for impossible states, dead branches.
6. **Idiomatic / convention violations** — where the diff diverges from the project's patterns (look at surrounding files in the diff for the local convention).
7. **What Claude likely missed** — read the summary critically. Did Claude defer something that actually matters? Claim test coverage that isn't there? Skip a constraint?
8. **What's good** — 1-3 honest bullets on what the implementation gets right. No flattery.

Constraints:
- Do NOT modify files. This is a read-only review.
- Be specific: cite \`file_path:line_number\` for every finding. Vague critique is useless.
- Rank findings by severity (critical / high / medium / low).
- If the implementation is solid, say so. Do not invent issues.

Output format (markdown):

## Verdict
One sentence: ship-as-is | minor-tweaks | needs-rework | blocked

## Critical / High
[bullets — bugs, missing tests for risky paths, broken invariants — with file:line]

## Medium
[bullets — edge cases, simplification opportunities, idiomatic concerns — with file:line]

## Low / Adjacent
[bullets — nice-to-haves, follow-up TODOs, stale-comment cleanup — with file:line]

## What Claude Likely Missed
[bullets called out from reading the summary against the diff]

## What's Good
[1-3 honest bullets]
PROMPT
)" < /dev/null
```

Stream codex's progress to the user as it runs. Capture the final review from `$OUT_FILE`.

> **Note:** the prompt references `$SUMMARY_FILE` and `$DIFF_FILE` by absolute path. Since codex runs read-only in the same working directory, it will read those tempfiles when instructed. Use full paths in the heredoc (substituted by the shell) so codex can locate them without ambiguity.

### 4. Present codex's raw feedback

Show the contents of `$OUT_FILE` to the user verbatim under a heading:

```markdown
## Codex review

> Independent review from `codex exec` — diff + summary only, no conversation context.

<contents of $OUT_FILE>
```

Do NOT paraphrase. The user wants codex's voice.

### 5. Synthesize an iteration plan

Read codex's findings and convert them into a concrete iteration plan. For each finding, decide:
- **Apply now** — fix in this iteration before commit
- **Defer with TODO** — legitimate but out of scope; add a `TODO_TECHDEBT` / `TODO_IDEA` comment in the relevant file
- **Reject** — wrong, irrelevant, or codex misunderstood context Claude has

Don't blindly accept everything. If a finding is wrong (codex missed context, misread the diff, or proposed something contrary to the project's conventions), mark it rejected and explain why.

### 6. Cleanup

```bash
rm -f "$DIFF_FILE" "$SUMMARY_FILE" "$OUT_FILE"
```

## Codex prompt

The exact prompt is embedded in [step 3](#3-run-codex-in-headless-review-mode). Key requirements when adapting it:
- Tell codex it's reviewing another agent's diff (sets tone)
- Point codex at the skill methodology files in `~/.codex/skills/` — those are symlinked to the repo and codex can read them in read-only mode
- Demand `file:line` references — vague critique is useless
- Force a verdict line for triage at a glance
- Allow codex to say "looks good" — no manufactured issues

## Output format

After codex returns, present the result as three sections in order:

### 1. Codex's raw review

Quoted verbatim under a `## Codex review` heading.

### 2. Iteration plan

Prioritized checklist Claude will execute (or propose to execute) next. Group by decision:

```markdown
**Apply now (P0):**
- [ ] `path/to/file.py:42` — fix off-by-one in pagination loop
- [ ] `path/to/test_file.py` — add test for empty-list case

**Apply now (P1):**
- [ ] `path/to/other.py:88` — extract duplicated normalization helper

**Defer with TODO:**
- [ ] `path/to/file.py:120` — add `TODO_TECHDEBT` for connection pooling
      Why deferred: not blocking; needs separate evaluation of pgbouncer vs in-app pooling

**Rejected:**
- [ ] Codex suggestion: "Wrap entire handler in try/except"
      Why rejected: framework already converts exceptions to 500s; adding try/except would swallow stack traces
```

### 3. Changelog

Table summarizing every codex finding and what Claude decided:

| S | Finding | Severity | Decision | Reason |
|---|---------|----------|----------|--------|
| 🟢 | Off-by-one in pagination at `loader.py:42` | High | Apply now | Genuine bug, codex caught it |
| 🟡 | Connection pooling | Medium | Defer | TODO_TECHDEBT added; out of scope |
| 🔴 | Wrap handler in try/except | Low | Reject | Framework handles it; would hide errors |
| 🟢 | Add empty-list test in `test_loader.py` | Medium | Apply now | Real gap, test is small |

> 🟢 Apply now · 🟡 Defer (with TODO) · 🔴 Reject · ⚪ Already addressed

End with a one-line tl;dr: e.g., "_3 fixes to apply, 1 TODO to add, 1 suggestion rejected. Verdict: minor-tweaks._"

### 6. Ask before applying

After presenting the iteration plan, **ask the user** whether to apply the P0/P1 fixes now or wait. Don't auto-apply — the user wants to see the plan first.

## Notes

- **Codex needs auth** — if `codex exec` errors with auth issues, tell the user to run `codex login` and stop.
- **Read-only sandbox** — codex cannot modify files even if it tries. This is intentional.
- **Skill paths are symlinked** — `~/.codex/skills/cmd-pr-follow-up/SKILL.md` resolves to this repo via `make link-skills`. If codex reports it can't read those paths, the user may need to run `make link-skills` from `~/workspace/agent-skills`.
- **Don't loop** — one codex review per invocation. After applying fixes, the user can re-run for another pass if desired.
- **Untracked files** — `git diff HEAD` does NOT show untracked files. If the implementation added new files that aren't yet tracked, mention this to the user and offer to `git add -N` them so they appear in the diff (intent-to-add stages the path without content, making the diff include them).
- **Companion skill** — pair with `cmd-codex-review-plan` (pre-implementation plan review) for full coverage: codex reviews the plan before execution AND the diff after.
