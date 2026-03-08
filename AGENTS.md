# AGENTS.md <!-- omit in toc -->

- [Project Overview](#project-overview)
- [Source of Truth](#source-of-truth)
- [Project Structure](#project-structure)
- [Dashboard Workflow](#dashboard-workflow)
- [Supported Tools](#supported-tools)
- [Skill Authoring Standards](#skill-authoring-standards)
- [Documentation Standards](#documentation-standards)

## Project Overview

- Multi-skill catalog for agentic CLIs by [Daniel Olshansky](https://olshansky.info)
- Canonical distribution path: `npx skills add olshansk/agent-skills`
- Follows the [Agent Skills](https://agentskills.io/home) pattern, inspired by [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)
- Live dashboard: [skills-dashboard.olshansky.info](https://skills-dashboard.olshansky.info/)
- Skills: `session-commit`, `skills-dashboard`

## Source of Truth

| Skill type | Source of truth | Installed via |
|---|---|---|
| **Your skills** | `~/workspace/agent-skills/skills/` (this repo) | `make link-skills` |
| **Third-party skills** | `~/.agents/skills/` | `npx skills add` |

- **Edit your skills here** → symlinks in `~/.claude/skills/` propagate changes instantly
- **Never edit** skills directly in `~/.claude/skills/` — those are symlinks
- `make link-skills` symlinks into `~/.claude/skills/`, `~/.gemini/antigravity/skills/`, and `~/.codex/skills/`

> **After `npx skills add olshansk/agent-skills`:** always run `make link-skills` to restore direct symlinks. npx creates copies that break the live-edit flow. Third-party skills are unaffected.

## Project Structure

- `skills/` — installable skills
  - `session-commit`, `skills-dashboard` — **Polished** (official distribution)
  - `cmd-*` — **Personal** (local use, slash-command style)
  - `makefile` — **Personal** (template-driven Makefile creation)
- `personal/` — personal configurations and references (ignored by git)
  - `configs/` — tool configuration snapshots (Claude, Gemini, Codex)
- `.github/workflows/skills-validate.yml` — CI workflow for skill validation
- `index.html` — root GitHub Pages dashboard
- `Makefile` — local orchestration (link-skills, sync)

## Dashboard Workflow

- The `skills-dashboard` skill has a scraper script at `skills/skills-dashboard/scripts/scrape_and_build.py`
- The installed skill copy lives at `~/.claude/skills/skills-dashboard/scripts/scrape_and_build.py`
- After modifying the script, sync the repo copy: `cp ~/.claude/skills/skills-dashboard/scripts/scrape_and_build.py skills/skills-dashboard/scripts/`
- After regenerating, always copy to root: `cp skills/skills-dashboard/index.html index.html`
- GitHub Pages serves from root `index.html` — the live site at `skills-dashboard.olshansky.info` won't update until this file is pushed
- GitHub Pages CDN caches aggressively; use `?v=N` query param or hard refresh to verify updates

## Supported Tools

| Tool        | Install path                                   | Local setup          |
| ----------- | ---------------------------------------------- | -------------------- |
| Claude Code | `npx skills add olshansk/agent-skills`         | `make link-skills`   |
| Codex CLI   | `npx skills add olshansk/agent-skills`         | `make link-skills`  |
| Gemini CLI  | `npx skills add olshansk/agent-skills`         | `make link-skills`  |
| OpenCode    | `npx skills add olshansk/agent-skills`         | `make link-skills`  |

## Skill Authoring Standards

Directory pattern:

```text
skills/<skill-name>/
  SKILL.md
  scripts/        # optional
  references/     # optional
  assets/         # optional
  commands/       # optional — per-tool command overrides
```

`SKILL.md` requirements:

- YAML frontmatter is required with at least `name` and `description`
- `name` must match the skill directory name and be kebab-case
- `description` should say what it does and when to use it
- Keep `SKILL.md` concise; move extended content to `references/`

Scripts:

- Use `scripts/` for reusable or complex command logic
- Scripts must be non-interactive and safe for agent execution
- Prefer structured stdout and diagnostic stderr in scripts

## Documentation Standards

- Code blocks must be comment-free and directly copy-pastable
- No `#` comments inside fenced code blocks
- Quickstart instructions come before explanatory content
- Use bullet points over paragraphs
