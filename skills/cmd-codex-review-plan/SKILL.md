---
name: cmd-codex-review-plan
description: Get a second opinion on the current plan from Codex (codex exec headless mode) before leaving plan mode. Pipes the plan to codex, captures critique and gap analysis, then proposes a revised plan with an explicit changelog of what changed and what was rejected. Triggers on "/cmd-codex-review-plan", "review plan with codex", "ask codex about this plan", or before approving auto mode on an exit-plan prompt.
disable-model-invocation: false
---

# Codex Review Plan <!-- omit in toc -->

Use `codex exec` as an independent reviewer on the plan currently in scope. Codex sees only the plan (no conversation history), so its critique is a genuine outside perspective — useful right before exiting plan mode and switching to auto execution.

- [When to use](#when-to-use)
- [Instructions](#instructions)
- [Codex prompt](#codex-prompt)
- [Output format](#output-format)
- [Notes](#notes)

## When to use

- Right before approving "Yes, and use auto mode" on an `ExitPlanMode` prompt
- Any time the user says "review plan with codex", "second opinion from codex", or `/cmd-codex-review-plan`
- After a non-trivial plan has been drafted and the user wants an outside critique before execution

## Instructions

### 1. Locate the plan

Use the most recent plan in conversation context — typically the body of the last `ExitPlanMode` call, or the latest plan markdown the user is reviewing. If multiple candidates exist, ask the user which one. **Do not invent or summarize** — pass the plan verbatim.

### 2. Write the plan to a tempfile

Codex reads from stdin reliably only if the input is a file or a piped heredoc. Use a tempfile to avoid quoting issues:

```bash
PLAN_FILE=$(mktemp -t codex-plan.XXXXXX.md)
OUT_FILE=$(mktemp -t codex-review.XXXXXX.md)
```

Write the plan verbatim into `$PLAN_FILE` using the Write tool.

### 3. Run codex in headless review mode

```bash
codex exec \
  --sandbox read-only \
  --skip-git-repo-check \
  --color never \
  --output-last-message "$OUT_FILE" \
  - < "$PLAN_FILE"
```

Pass the prompt from [Codex prompt](#codex-prompt) as the initial argument, and the plan via stdin. Concretely:

```bash
codex exec \
  --sandbox read-only \
  --skip-git-repo-check \
  --color never \
  --output-last-message "$OUT_FILE" \
  "$(cat <<'PROMPT'
You are reviewing an implementation plan written by another coding agent (Claude).
The plan follows in the <stdin> block.

Your job:
1. Identify GAPS — requirements, edge cases, failure modes, or dependencies the plan misses.
2. Identify RISKS — fragile assumptions, ordering hazards, breaking-change risks, test coverage holes.
3. Identify SIMPLIFICATIONS — anything over-engineered, premature abstraction, or scope that should be deferred.
4. Identify CONCRETE FIXES — for each issue, suggest the smallest change that addresses it.

Constraints:
- Do NOT rewrite the whole plan. Critique it.
- Do NOT execute commands or modify files. This is a read-only review.
- Be specific: cite file paths, phase numbers, or step numbers from the plan.
- If the plan is solid, say so. Do not invent issues.

Output format (markdown):

## Verdict
One sentence: ship-as-is | minor-tweaks | needs-rework

## Gaps
- [bullet per gap, with phase/file reference]

## Risks
- [bullet per risk, with phase/file reference and severity: high/medium/low]

## Simplifications
- [bullet per simplification opportunity]

## Concrete Suggestions
- [numbered list of specific actionable changes to apply to the plan]

## What's Good
- [1-3 bullets on what the plan gets right — keep this honest, not flattery]
PROMPT
)" < "$PLAN_FILE"
```

Stream codex's progress to the user as it runs (don't background it — the user wants to watch). Capture the final message from `$OUT_FILE`.

### 4. Present codex's raw feedback

Show the contents of `$OUT_FILE` to the user verbatim under a heading:

```markdown
## Codex review

> Independent review from `codex exec` — no conversation context, plan only.

<contents of $OUT_FILE>
```

### 5. Synthesize a revised plan

Read codex's suggestions and decide, item by item, what to apply. Then produce:

1. **Revised plan** — the original plan with codex's accepted suggestions integrated.
2. **Changelog** — a table showing each codex suggestion and what you did with it.

Don't blindly accept everything codex says. If a suggestion is wrong, irrelevant, or misunderstands context Claude has and codex doesn't, mark it rejected and explain why.

### 6. Cleanup

```bash
rm -f "$PLAN_FILE" "$OUT_FILE"
```

## Codex prompt

The exact prompt is embedded in [step 3](#3-run-codex-in-headless-review-mode). Key requirements when adapting it:
- Tell codex it's reviewing another agent's plan (sets expectations for tone)
- Demand specific references (phase numbers, file paths) — vague critique is useless
- Explicitly forbid command execution (read-only review)
- Require a verdict line so the user can triage at a glance
- Allow codex to say "looks good" — don't force it to manufacture issues

## Output format

After codex returns, present the result as three sections in order:

### 1. Codex's raw review

Quoted verbatim under a `## Codex review` heading. Don't paraphrase — the user wants codex's voice, not Claude's summary of codex.

### 2. Revised plan

Same shape as the original plan (phases, action items, risks, etc.) with accepted changes integrated. Mark new or modified items with a leading marker so they're easy to spot:

| Marker | Meaning |
|--------|---------|
| 🆕 | New item added based on codex feedback |
| ✏️ | Existing item modified based on codex feedback |
| ➖ | Item removed based on codex feedback |

### 3. Changelog

Table with one row per codex suggestion:

| S | Codex Suggestion | Decision | Reason |
|---|------------------|----------|--------|
| 🟢 | Add rollback step to phase 2 | Applied | Valid — the migration can fail mid-write |
| 🟡 | Split phase 1 into two phases | Partial | Kept as one phase, but added explicit checkpoints |
| 🔴 | Use a feature flag for the rename | Rejected | Overkill — the function is internal and has 2 callers |

> 🟢 Applied · 🟡 Partial / modified · 🔴 Rejected · ⚪ Deferred to follow-up

End with a one-line tl;dr of net changes (e.g., "_Added 1 phase, modified 2 steps, rejected 1 suggestion._").

## Notes

- **Codex needs auth** — if `codex exec` errors with auth issues, tell the user to run `codex login` and stop.
- **Read-only sandbox** — codex cannot modify files even if it tries. This is intentional.
- **`--skip-git-repo-check`** — lets the skill work outside git repos (e.g., scratch dirs).
- **`--output-last-message`** — gives a clean final message without progress event noise.
- **Don't loop** — one codex review per invocation. If the user wants another pass after revisions, they re-run the skill.
- **Plan mode caveat** — if invoked from plan mode, the only file edits available are via Write/Edit on the tempfiles, which is fine. The Bash call to `codex exec` is allowed; it's just running an external tool, not modifying repo files.
