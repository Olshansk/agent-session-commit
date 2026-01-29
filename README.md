# Agent Session Commit

**One command to make your AI assistants share a brain.**

Capture session learnings to `AGENTS.md`—a single source of truth that works across Claude Code, Cursor, Windsurf, and Gemini.

## Quick Install

```bash
git clone https://github.com/olshansky/agent-session-commit.git ~/.claude/plugins/agent-session-commit
```

Then run:

```
/session-commit
```

## Why This Exists

Every AI coding session teaches you something. But that knowledge disappears when the session ends—or lives only in one tool's context.

**AGENTS.md solves this.** It's an emerging standard for AI-readable project documentation. This plugin captures learnings and writes them to AGENTS.md, so every AI tool gets the same context.

## What It Does

1. Reviews existing AGENTS.md to avoid duplicates
2. Analyzes session for valuable learnings
3. Proposes changes with visual formatting:
   - ➕ Additions
   - 🔄 Modifications
   - ➖ Removals
4. Waits for your confirmation
5. Creates CLAUDE.md/GEMINI.md pointing to AGENTS.md

## What Gets Captured

| Category | Examples |
|----------|----------|
| Patterns | Code style, naming conventions |
| Architecture | Why things are structured a certain way |
| Gotchas | Pitfalls discovered during development |
| Debugging | What to check when things break |

## Alternative Installation

Add as a git submodule in your project:

```bash
git submodule add https://github.com/olshansky/agent-session-commit.git .claude-plugins/agent-session-commit
```

## Verification

```bash
claude --debug
```

Look for "agent-session-commit" in the plugin loading output.

## License

MIT
