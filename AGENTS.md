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

| Asset type | Source of truth | Installed via |
|---|---|---|
| **Your skills** | `~/workspace/agent-skills/skills/` (this repo) | `make link-skills` |
| **Agent instructions** | `~/workspace/agent-skills/agents/` (this repo) | `make link-skills` |
| **Third-party skills** | `~/.agents/skills/` | `npx skills add` |

### How `make link-skills` works <!-- omit in toc -->

`make link-skills` creates symlinks in each tool's skills directory from **both** sources:

```text
~/.claude/skills/
~/.codex/skills/          ← each gets symlinks to both sources
~/.gemini/antigravity/skills/

Sources (in priority order):
  1. ~/.agents/skills/<name>/        ← third-party (linked first)
  2. ~/workspace/agent-skills/skills/<name>/  ← repo (linked second, wins on conflict)
```

- Repo skills override third-party skills of the same name
- Third-party-only skills (e.g. `grove`, `gstack`) are visible to all tools
- **Edit your skills in the repo** → symlinks propagate changes instantly
- **Never edit** skills directly in `~/.claude/skills/` — those are symlinks

> **After `npx skills add olshansk/agent-skills`:** always run `make link-skills` to restore direct symlinks. npx creates copies that break the live-edit flow. Third-party skills are unaffected.

## Project Structure

- `agents/` — global agent instructions (`AGENTS.md`, `MEMORIES.md`), symlinked to `~/.claude/`, `~/.codex/`, `~/.gemini/`
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

**Naming conventions:**
- Personal global skills: always prefix with `cmd-`
- Repo-specific skills: prefix with the repo name (e.g., `grove-`, `pocket-`) or ask if ambiguous
- No `cmd-` prefix for polished distribution skills intended for public install

Scripts:

- Use `scripts/` for reusable or complex command logic
- Scripts must be non-interactive and safe for agent execution
- Prefer structured stdout and diagnostic stderr in scripts

## Modifying Skills (Add, Edit, Remove)

Whenever any skill is added, edited, or removed in `skills/`, update **all** of the following:

1. **`README.md`** — add, update, or remove the hyperlinked row in the appropriate table (link format: `[skill-name](skills/skill-name/SKILL.md)`). Keep the table sorted alphabetically.
2. **`~/.claude/CLAUDE.md`** — add, update, or remove the entry in the "Task skills" list under "Custom Skills"
3. **`make link-skills`** — run to create or clean up symlinks
4. **Verify** — confirm the skill appears (or is removed) in `~/.claude/skills/` after linking

For personal skills, do not treat `README.md` or tool metadata as optional. If a skill is only for local slash-command use, it still needs the README row and agent metadata to stay discoverable.

After installing/removing 3rd-party skills (`npx skills add ...`), run `make sync-external-skills` to refresh the "3rd Party Skills" table in `README.md` (auto-generated between `<!-- BEGIN: 3rd-party-skills -->` markers from `~/.agents/skills/`).

## Documentation Standards

- Code blocks must be comment-free and directly copy-pastable
- No `#` comments inside fenced code blocks
- Quickstart instructions come before explanatory content
- Use bullet points over paragraphs
