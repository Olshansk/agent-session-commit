# Agent Session Commit <!-- omit in toc -->

Capture session learnings to `AGENTS.md` for cross-tool AI interoperability.

- [Overview](#overview)
- [Why AGENTS.md?](#why-agentsmd)
- [Usage](#usage)
- [What Gets Captured](#what-gets-captured)
- [Installation](#installation)
- [Verification](#verification)
- [Configuration](#configuration)
- [License](#license)

## Overview

This plugin helps you build a knowledge base that works across AI coding assistants (Claude Code, Cursor, Windsurf, etc.) by:

- **Updating AGENTS.md** with patterns, preferences, and project insights
- **Initializing AGENTS.md** if it doesn't exist (like `/init` but for AGENTS.md)
- **Keeping CLAUDE.md minimal** as a pointer to the authoritative AGENTS.md

## Why AGENTS.md?

`AGENTS.md` is an emerging standard for AI-readable project documentation that works across different AI tools. By consolidating your project knowledge in `AGENTS.md`, you get consistent behavior whether using Claude Code, Cursor, Windsurf, or other AI assistants.

`CLAUDE.md` is kept minimal, pointing to `AGENTS.md` as the single source of truth.

## Usage

Run the command anytime during a session to capture learnings:

```
/session-commit
```

The command will:
1. Check if `AGENTS.md` exists (creates it if missing)
2. Analyze the session for valuable learnings
3. Propose changes and wait for your confirmation
4. Apply approved changes to `AGENTS.md`
5. Ensure `CLAUDE.md` points to `AGENTS.md`

## What Gets Captured

- **Coding patterns**: Style preferences, naming conventions
- **Architecture decisions**: Why things are structured a certain way
- **Gotchas**: Pitfalls discovered during development
- **Project conventions**: How this codebase does things
- **Debugging insights**: What to check when things break
- **Workflow preferences**: How you like to work

## Installation

Clone or download this repository:

```bash
git clone https://github.com/olshansky/agent-session-commit.git ~/.claude/plugins/agent-session-commit
```

Or add as a git submodule in your project:

```bash
git submodule add https://github.com/olshansky/agent-session-commit.git .claude-plugins/agent-session-commit
```

## Verification

To verify the plugin is loaded:

```bash
claude --debug
```

Look for "agent-session-commit" in the plugin loading output.

## Configuration

No configuration required. The plugin works out of the box.

## License

MIT License - see [LICENSE](LICENSE) for details.
