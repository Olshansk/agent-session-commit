---
name: cmd-email-md
description: Convert markdown to email-safe HTML with inline styles and cross-client compatibility. Use when writing newsletters, transactional emails, or any HTML email from markdown source.
disable-model-invocation: true
---

# Markdown to Email HTML

Convert markdown into a complete, self-contained HTML email with inline CSS, table-based layout, and cross-client compatibility (Gmail, Outlook, Apple Mail).

## Workflow

### 1. Determine input

- If the user provided a file path, read the `.md` file
- If the user provided inline markdown, use that directly
- If neither, ask: "Which markdown file should I convert, or paste the content?"

### 2. Parse frontmatter

Extract YAML frontmatter from the top of the markdown. All fields are optional — use defaults for anything missing.

| Field | Default | Description |
|---|---|---|
| `preheader` | (none) | Hidden inbox preview text |
| `brand-color` | `#2563eb` | Primary accent (links, buttons, highlights) |
| `heading-color` | `#1a1a1a` | h1-h3 color |
| `body-color` | `#333333` | Body text color |
| `background-color` | `#f4f4f4` | Outer background |
| `content-background` | `#ffffff` | Inner content area |
| `font-family` | `Arial, Helvetica, sans-serif` | Safe font stack |
| `font-size` | `16px` | Base body size |
| `line-height` | `26px` | Body line height (must be px for Outlook) |
| `content-width` | `600px` | Max content width |
| `header-logo` | (none) | URL to logo image |
| `footer-text` | (none) | Footer text (unsubscribe, address, etc.) |

### 3. Load references

Read the following files for technical rules and component templates:

- `references/email-html-compatibility.md` — cross-client rules, document structure, quirks
- `references/email-components.md` — HTML snippets with `{{variable}}` placeholders

### 4. Convert markdown to email HTML

Walk through the markdown content and generate email-safe HTML:

- Use the **Complete Wrapper** template as the outer structure
- Map each markdown element to its corresponding component template
- Replace all `{{variable}}` placeholders with frontmatter values (or defaults)
- Apply **all CSS inline** — no `<style>` blocks in `<body>`
- Use **tables for layout** — never `<div>` for structure
- Include Outlook conditional comments for `max-width` fix
- Include preheader `<div>` if `preheader` is set
- Include header with logo if `header-logo` is set
- Include footer if `footer-text` is set

**Markdown element mapping:**

| Markdown | Email component |
|---|---|
| `# Heading` | Heading (h1-h4) with size per level |
| Paragraph | Paragraph with inline styles |
| `**bold**`, `*italic*`, `~~strike~~` | Inline `<strong>`, `<em>`, `<del>` |
| `[text](url)` | Styled `<a>` with brand-color |
| `- item` / `1. item` | Unordered/Ordered list |
| `- [ ] task` | Task list with Unicode checkboxes |
| `` `code` `` | Inline code |
| ` ```code block``` ` | Code block (dark theme) |
| `> quote` | Blockquote with left border |
| `![alt](src)` | Image with explicit dimensions |
| `---` | Horizontal rule |
| `==highlight==` | `<mark>` with background color |

**Special directives** (fenced with `:::`):

| Directive | Behavior |
|---|---|
| `:::hero` | Full-width section with brand-color background, white text |
| `:::callout[type]` | Highlighted box — type: `info`, `tip`, `warning`, `danger` |
| `:::button[text](url)` | CTA button with VML fallback |
| `:::button.secondary[text](url)` | Secondary button variant |
| `:::centered` | Center-aligned text block |
| `:::footer` | Footer section (overrides `footer-text` frontmatter) |

### 5. Write output

- If input was a file (e.g., `newsletter.md`), write to `newsletter.html` in the same directory
- If input was inline, ask the user for an output path
- The output must be a complete, self-contained HTML document — ready to paste into any email sending tool

### 6. Summary

Report:
- Output file path
- Theme values applied (brand color, font, content width)
- Any warnings (e.g., unsupported markdown features skipped, images without dimensions)

## Constraints

- **No `<style>` in `<body>`** — Gmail strips it. Only allowed in `<head>` for responsive media queries.
- **No flexbox, grid, or CSS variables** — not supported in email clients
- **No `<button>` elements** — use `<a>` tags styled as buttons
- **No JavaScript** — always blocked
- **No external CSS** — everything inline
- **Tables for layout** — `<div>` only for non-structural content (e.g., preheader hiding)
- **px units only** — no `rem`, `em`, `vh`, `vw`, or `calc()`
- **Explicit dimensions on images** — always set `width` and `height`
- **Absolute URLs** — all `src` and `href` must be fully qualified

## Example Input

```markdown
---
preheader: "Your weekly update is here"
brand-color: "#6366f1"
header-logo: "https://example.com/logo.png"
footer-text: "Acme Inc. | 123 Main St | [Unsubscribe](https://example.com/unsub)"
---

:::hero
# Welcome to the Weekly Update
Everything you need to know, in one email.
:::

## What's New

We shipped **three major features** this week:

- Real-time collaboration
- Dark mode support
- Export to PDF

:::callout[tip]
Try dark mode by going to Settings > Appearance.
:::

:::button[Try it now](https://example.com/app)

## By the Numbers

| Metric | This Week | Last Week |
|---|---|---|
| Active Users | 12,450 | 11,200 |
| Signups | 890 | 720 |

> "This is the best update yet!" — A happy user

---

Thanks for reading. See you next week!
```
