---
name: mermaid-render
description: >
  Render and display Mermaid diagrams inline in iTerm2.
  Use when creating, editing, or iterating on mermaid diagrams.
  Triggers on mermaid diagram work — flowcharts, sequence, state, class, ER, and XY charts.
allowed-tools: Read Write Edit Bash
---

# Mermaid Diagram Renderer <!-- omit in toc -->

Render mermaid diagrams to PNG and display them inline in iTerm2. Built for fast visual iteration.

- [Workflow](#workflow)
- [Prerequisites](#prerequisites)
- [Rendering](#rendering)
- [Iteration Rules](#iteration-rules)

## Workflow

Every time you generate or modify mermaid code, immediately render and display it. Never ask "want me to render?" — just do it.

**Write the mermaid code:**

```bash
cat > /tmp/mermaid-diagram.mmd << 'MERMAID'
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action]
    B -->|No| D[End]
MERMAID
```

**Render and display:**

```bash
"${CLAUDE_SKILL_DIR}/scripts/render.sh" /tmp/mermaid-diagram.mmd
```

If the user provides a specific file path, use that instead of `/tmp/mermaid-diagram.mmd`.

## Prerequisites

On first use, check that dependencies are available:

```bash
which mmdc || echo "MISSING: Run 'npm install -g @mermaid-js/mermaid-cli'"
which imgcat || echo "MISSING: Install iTerm2 shell integration"
```

If `mmdc` is missing, tell the user to install it. Do not install it automatically.

## Rendering

The `render.sh` script handles rendering with sensible defaults. It supports these flags:

- `--theme <name>` — mermaid theme: `default`, `dark`, `forest`, `neutral` (default: `default`)
- `--width <px>` — output width in pixels (default: `1200`)
- `--bg <color>` — background color (default: `transparent`)
- `--css <path>` — custom CSS file for styling
- `--output <path>` — custom output path (default: replaces `.mmd` with `.png`)

**Examples:**

```bash
# Dark theme
"${CLAUDE_SKILL_DIR}/scripts/render.sh" /tmp/mermaid-diagram.mmd --theme dark

# Wider output for complex diagrams
"${CLAUDE_SKILL_DIR}/scripts/render.sh" /tmp/mermaid-diagram.mmd --width 2400

# Custom output location
"${CLAUDE_SKILL_DIR}/scripts/render.sh" /tmp/mermaid-diagram.mmd --output ~/Desktop/diagram.png
```

## Iteration Rules

- After each user edit request, update the `.mmd` file and re-render immediately
- Show the diagram after every change — the user should never have to ask
- Keep the `.mmd` file path consistent within a session so edits accumulate
- For syntax help, defer to the `cmd-mermaid-diagram` skill which has comprehensive syntax references
- If `mmdc` reports a syntax error, show the error message and fix the mermaid code before retrying
