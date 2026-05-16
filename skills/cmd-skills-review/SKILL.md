---
name: cmd-skills-review
description: Audit personal skills for redundancy, verbosity, weak triggers, and overlap. Runs a Claude→Codex review loop, presents per-item approval checkboxes, then applies approved edits and updates README and agent metadata. Use when asked to "review my skills", "audit my skills", "revisit my skills", or "clean up my skills". Accepts an optional skill name to scope the review to a single skill.
disable-model-invocation: false
---

# Skills Review <!-- omit in toc -->

Audit one skill or all skills, get a second opinion from Codex, then apply only what you approve.

- [When to use](#when-to-use)
- [Instructions](#instructions)
- [Codex prompt](#codex-prompt)
- [Apply phase](#apply-phase)

## When to use

- "review my skills" / "audit my skills" / "revisit my skills" / "clean up my skills"
- "review the cmd-foo skill" — single-skill mode
- Before publishing or sharing the skills repo
- When the skill catalog has grown and feels bloated

## Instructions

### 0. Determine scope

If the user named a specific skill (e.g. "review cmd-pr-edgecase"), set `TARGET=skills/cmd-pr-edgecase/SKILL.md`.
Otherwise, set `TARGET=skills/cmd-*/SKILL.md` (all personal skills).

### 1. Inventory

Read every `SKILL.md` in scope. For each skill, record:

| Field | What to capture |
|---|---|
| Name | `name:` from frontmatter |
| Description length | word count (rough) |
| Has trigger phrases | yes / no |
| `disable-model-invocation` | true / false / missing |
| Overlaps with | list any skills with similar purpose |

Print the inventory table before proceeding so the user can orient.

### 2. Claude's analysis

For each skill (or the single target), produce a proposal row:

| Field | Values |
|---|---|
| Issue type | `verbose` / `weak-trigger` / `missing-trigger` / `redundant` / `rename` / `merge-candidate` / `looks-good` |
| Suggested fix | one concrete sentence — what to change and how |
| Priority | 🔴 breaking / 🟡 worth fixing / 🟢 minor |

Flag pairs that substantially overlap and note which one should be canonical.

### 3. Codex review

Write the inventory + proposals to a tempfile, then invoke Codex for a second opinion:

```bash
PROPOSAL_FILE=$(mktemp -t skills-proposal.XXXXXX.md)
OUT_FILE=$(mktemp -t skills-codex.XXXXXX.md)

# Write proposal to tempfile using the Write tool, then:

codex exec \
  --sandbox read-only \
  --skip-git-repo-check \
  --color never \
  --output-last-message "$OUT_FILE" \
  "$(cat <<PROMPT
You are reviewing a set of Claude Code personal agent skills.

Read the proposal file at $PROPOSAL_FILE. It contains:
- An inventory table of each skill's name, trigger coverage, and flags
- Claude's proposed improvements (issue type + suggested fix)

Your job:
1. For each proposed change: agree / disagree / modify. One line per item.
2. Flag anything Claude missed — skills with weak or missing triggers, descriptions that won't auto-trigger reliably, overlaps Claude didn't catch.
3. Identify which descriptions are too long (agent descriptions should be scannable, not exhaustive).
4. Flag any skill whose purpose is fully covered by another skill.

Constraints:
- Do NOT suggest new skills. Focus on improving what exists.
- Be specific. Vague feedback ("make it better") is useless.
- If a skill looks solid, say so.

Output format (markdown, no preamble):

## Codex verdict per proposal
[table: Skill | Claude's proposal | Codex verdict (agree/disagree/modify) | Codex note]

## Missed issues
[bullets — things Claude didn't flag, with skill name and specific concern]

## Overall assessment
[2-3 sentences on the catalog health]
PROMPT
)" < /dev/null
```

Show Codex's raw output verbatim under a `## Codex review` heading.

### 4. Synthesize

Merge Claude + Codex input into a final approval table. One row per proposed change:

```markdown
| # | Skill | Change | Source | Priority |
|---|-------|--------|--------|----------|
| 1 | cmd-pr-edgecase | Tighten description — remove first two sentences | Both agree | 🟡 |
| 2 | cmd-codex-review-plan | Add trigger "second opinion on plan" | Codex flagged | 🟡 |
| 3 | cmd-pr-follow-up | Merge into cmd-pr-scope-sweep (near-duplicate) | Claude flagged, Codex agrees | 🔴 |
```

Where Claude and Codex disagree, include both positions and note the disagreement. Don't auto-resolve in Claude's favor.

### 5. Approval gate

Present the final table with per-item checkboxes using `AskUserQuestion`. Group by priority (🔴 first).

Ask: "Which changes should I apply?"

Options (multi-select):
- Each item as its own checkbox: `#N — <skill> — <one-line summary>`
- "Apply all 🔴 items"
- "Apply all 🟡 items"
- "Skip everything"

Do not proceed until the user responds. If the user selects nothing, stop and confirm.

### 6. Apply approved changes

For each approved item, edit the relevant `SKILL.md` in `~/workspace/agent-skills/skills/<skill-name>/`.

After all edits:

1. **Update `README.md`** — update the description in the skills table for any edited skill; remove the row for any deleted skill; add a row for any renamed skill.
2. **Update `~/.claude/CLAUDE.md`** — if the change affects how the skill is triggered or described, update the corresponding entry in the Custom Skills section.
3. **Update `agents/AGENTS.md`** — same as above; both files should stay in sync.
4. Run `make link-skills` from `~/workspace/agent-skills` to re-link any renamed or new skill directories.

Report a summary table of what was applied:

| Skill | Change applied | Files updated |
|---|---|---|
| cmd-pr-edgecase | Description trimmed | SKILL.md, README.md |

## Codex prompt

The exact prompt is embedded in [step 3](#3-codex-review). Key requirements when adapting:

- Feed Codex the inventory + proposals file — not raw SKILL.md content — so it reviews Claude's reasoning, not just the raw text.
- Demand per-item verdicts so synthesis is mechanical, not interpretive.
- Allow Codex to flag issues Claude missed; this is the main value of the second pass.
- Read-only sandbox — Codex must not edit files.

## Apply phase

- Only edit files for approved items. No silent scope creep.
- For merges or deletes, confirm once more with the user before destructive action (removing a SKILL.md directory).
- If `codex exec` errors with auth, tell the user to run `codex login` and stop.
