# Agent Skills <!-- omit in toc -->

Reusable skills for Claude Code, Gemini, and Codex.

- [Architecture](#architecture)
- [Symlink Map](#symlink-map)
- [Makefile Workflows](#makefile-workflows)
- [npx Install \& Coexistence](#npx-install--coexistence)
- [Makefile Targets](#makefile-targets)

## Architecture

Three repos and one third-party directory work together:

| Location                                       | What it holds                                     | Role                           |
| ---------------------------------------------- | ------------------------------------------------- | ------------------------------ |
| `~/workspace/agent-skills/skills/` (this repo) | 21 reusable skills                                | **SoT for skills**             |
| `~/workspace/configs/agents/`                  | `AGENTS.md`, `MEMORIES.md`                        | **SoT for agent instructions** |
| `~/.agents/skills/`                            | Third-party skills (find-skills, vercel-\*, etc.) | Managed by `npx skills add`    |
| `personal/configs/` (this repo)                | Snapshots of tool configs                         | Read-only backup (not SoT)     |

## Symlink Map

```mermaid
graph TB
    subgraph sources["Sources of Truth"]
        skills["~/workspace/agent-skills/skills/*"]
        instructions["~/workspace/configs/agents/"]
        thirdparty["~/.agents/skills/*"]
    end

    subgraph claude["~/.claude/"]
        claude_skills["skills/cmd-foo, session-commit, ..."]
        claude_md["CLAUDE.md"]
        claude_3p["skills/find-skills, vercel-*, ..."]
    end

    subgraph gemini["~/.gemini/"]
        gemini_skills["antigravity/skills/cmd-foo, ..."]
        gemini_md["GEMINI.md"]
    end

    subgraph codex["~/.codex/"]
        codex_skills["skills/cmd-foo, ..."]
        codex_md["AGENTS.md"]
    end

    subgraph backup["personal/configs/ (this repo)"]
        snap["claude/ gemini/ codex/ snapshots"]
    end

    skills -->|symlink| claude_skills
    skills -->|symlink| gemini_skills
    skills -->|symlink| codex_skills

    instructions -->|"AGENTS.md symlink"| claude_md
    instructions -->|"MEMORIES.md symlink"| gemini_md
    instructions -->|"AGENTS.md symlink"| codex_md

    thirdparty -->|symlink| claude_3p

    claude -->|"make sync (copy)"| snap
    gemini -->|"make sync (copy)"| snap
    codex -->|"make sync (copy)"| snap
```

## Makefile Workflows

```mermaid
graph LR
    repo["agent-skills/skills/*"]

    subgraph outbound["Symlink OUT"]
        link["make link-skills"]
    end

    subgraph inbound["Copy IN"]
        sync["make sync"]
    end

    claude_dir["~/.claude/skills/"]
    gemini_dir["~/.gemini/antigravity/skills/"]
    codex_dir["~/.codex/skills/"]
    snapshots["personal/configs/"]

    repo -->|"symlink"| link
    link --> claude_dir
    link --> gemini_dir
    link --> codex_dir

    claude_dir -->|"file copy"| sync --> snapshots
    gemini_dir -->|"file copy"| sync
    codex_dir -->|"file copy"| sync
```

- **`make link-skills`** creates symlinks FROM this repo INTO all tool dirs (Claude, Gemini, Codex)
- **`make sync`** copies FROM tool dirs INTO `personal/configs/` (one-way backup for git history)

## npx Install & Coexistence

| Skill type | Source of truth | Installed via | Symlink target |
|---|---|---|---|
| **Your skills** | this repo | `make link-skills` | `~/workspace/agent-skills/skills/*` |
| **Third-party** | `~/.agents/skills/` | `npx skills add` | `~/.agents/skills/*` |

```mermaid
graph TB
    subgraph npx_flow["npx skills add (any repo)"]
        direction TB
        clone["1. Clone repo from GitHub"]
        store["2. Store in ~/.agents/skills/"]
        symlink["3. Create symlinks in ~/.claude/skills/"]
        clone --> store --> symlink
    end

    subgraph restore["After npx, run: make link-skills"]
        direction TB
        yours["Your skills: repointed → ~/workspace/agent-skills/skills/*"]
        theirs["Third-party skills: untouched → ~/.agents/skills/*"]
    end

    npx_flow --> restore
```

- `npx skills add` and `make link-skills` both write to `~/.claude/skills/` — whichever runs last wins for overlapping names
- **In practice**: run `npx skills add` for third-party skills, then `make link-skills` to restore yours
- This works because `make link-skills` only creates symlinks for skills that exist in your repo — third-party skills are left alone

## Makefile Targets

| Target             | Description                                                                  |
| ------------------ | ---------------------------------------------------------------------------- |
| `make link-skills` | Symlink repo skills into Claude, Gemini, and Codex (repoints if needed)      |
| `make list-skills` | List all skills with descriptions                                            |
| `make sync`        | Backup all tool configs into `personal/configs/`                             |
| `make test`        | Validate skill frontmatter and repo consistency                              |
| `make status`      | Show repository status                                                       |
