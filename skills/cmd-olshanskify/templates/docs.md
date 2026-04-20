# Olshanskify Template: Docs

Use when editing READMEs, AGENTS.md files, guides, runbooks, or any markdown reference material.

## Voice & Shape

- **Lead with the payoff.** First line states what the reader gets or does, not what the doc is "about".
- **Bullets beat paragraphs.** Any paragraph over ~3 sentences becomes a bulleted list.
- **One sentence per line** when sentences stand alone — makes diffs clean and skimming easy.
- **No fluff.** Drop throat-clearing like "this doc covers…", "it is scalable", "as mentioned above". If removing a line does not lose information, remove it.
- **Number multi-part answers** (`### 1.`, `### 2.`) so the reader can reference specific items in follow-ups.

## Structure

- **Table of Contents at the top** for anything non-trivial. Ignore the document title with `<!-- omit in toc -->` and hide deeply nested headers the same way.
- **Quickstart before explanation.** Copy-pasta instructions first, justification and internals after.
- **Tables for comparisons** whenever there are 3+ items across 2+ dimensions. Use emoji status columns where relevant:
  - ✅ / ❌ / 🔴 / ⏭️ for test-like results
  - 🔴 Critical fix / 🟡 Improvement / 🟢 New feature / ⚪ Neutral / ⚙️ Infra for diffs

## Code Blocks

- **Always specify the language** on fenced blocks (```` ```bash ````, ```` ```python ````, ```` ```markdown ````).
- **No `#` comments inside code blocks.** Code blocks must be directly copy-pastable.
- **One command per block.** Never chain multiple commands inside a single block with `#` comments between them. Split into separate blocks, each with a bold header above it.

  **Bad:**

  ````markdown
  ```bash
  # Step 1
  command-one
  # Step 2
  command-two
  ```
  ````

  **Good:**

  ````markdown
  **Do thing:**

  ```bash
  command-one
  ```

  **Do other thing:**

  ```bash
  command-two
  ```
  ````

## References & Links

- Reference specific functions with the `file_path:line_number` pattern so readers can click through.
- Prefer links to living sources (repo files, dashboards) over static snippets that rot.
- Only link to URLs you are confident about. Never guess a URL.

## Formatting Hygiene

- No emojis unless the user explicitly asks for them. Exception: the emoji status columns above, which are structural, not decorative.
- No trailing "this doc is a work in progress" disclaimers — if it is incomplete, ship it and iterate.
- No "see also: everything" dumping grounds at the bottom. Link inline where the reference actually helps the reader.

## Before You Submit the Edit

Check:

1. Could the first sentence be the whole doc? If yes, trim aggressively.
2. Are all code blocks copy-pastable with no manual edits?
3. Does every table earn its row count, or is it two rows that should be prose?
4. Is the ToC in sync with the headings?
