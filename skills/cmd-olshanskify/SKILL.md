---
name: cmd-olshanskify
description: Apply Olshansky's personal style to docs, code, blog posts, or presentations using template-driven rules. Invoke manually via /cmd-olshanskify — pick a content type, point at the target, and the agent rewrites or proposes edits that match the canonical style guide in templates/.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Olshanskify <!-- omit in toc -->

Rewrite or edit content so it matches Olshansky's voice and conventions. Templates encode the rules; this skill picks the right template and applies it.

- [1. Pick a Template](#1-pick-a-template)
- [2. Inspect the Target](#2-inspect-the-target)
- [3. Propose the Olshanskified Version](#3-propose-the-olshanskified-version)
- [4. Apply on Approval](#4-apply-on-approval)
- [5. Evolving the Templates](#5-evolving-the-templates)

## 1. Pick a Template

Templates live in `templates/` — one per content type. Add a new template when a new content type appears; update an existing template when a new rule emerges.

| Content type | Template | Use when |
|---|---|---|
| Documentation (READMEs, AGENTS.md, guides) | [`templates/docs.md`](templates/docs.md) | Editing any markdown-heavy reference material |
| Code (any language) | [`templates/code.md`](templates/code.md) | Editing source files, proposing refactors, writing new code |
| Blog post | [`templates/blog.md`](templates/blog.md) | Drafting or polishing posts for olshansky.info / substack / similar |
| Presentation / slides | [`templates/presentation.md`](templates/presentation.md) | Editing slide decks, talk outlines, conference abstracts |

If the user does not specify a content type, ask:

> Which Olshanskify template should I apply — docs, code, blog, or presentation? (Or is this a new type worth adding to `templates/`?)

## 2. Inspect the Target

Before proposing edits:

1. Read the target file(s) in full.
2. Read the chosen template end-to-end.
3. Note any pre-existing style choices in the target that conflict with the template — surface conflicts explicitly rather than silently overriding.

## 3. Propose the Olshanskified Version

Show the user a diff or side-by-side before writing. Format:

```markdown
## Olshanskify: {target_path}

Template applied: **{template_name}**

### Rules triggered
- {rule from template} → {how it reshapes this content}
- ...

### Proposed changes
- {file}:{lines} — {one-line summary of the edit}
- ...

### Conflicts / judgment calls
- {anything where the template and the existing content disagreed, and how you resolved it}
```

**Do not edit yet.** Wait for approval.

## 4. Apply on Approval

After the user confirms, apply the edits. Respect the global rule: **the user commits manually** — do not run `git commit` or `git push`.

## 5. Evolving the Templates

Templates are living documents. Update them when:

- The user corrects a style choice ("no, always use X" / "drop the Y pattern").
- A cross-skill signal surfaces a rule worth codifying. For example, `cmd-pr-gh-comments` proposes updates to `templates/code.md` whenever PR feedback came from `@olshansk` (see that skill's step 10).
- A new content type appears — add a new template file and an entry to the table above.

When proposing a template edit, show:

1. The rule to add (or change), in the template's existing tone.
2. The source of the rule (which conversation, PR, or file surfaced it).
3. A quick example of before/after if the rule is non-obvious.

Never silently mutate a template. Every change is approval-gated.
