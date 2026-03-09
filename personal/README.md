# Agent Skills <!-- omit in toc -->

Reusable skills for Claude Code, Gemini, and Codex.

- [Architecture](#architecture)
- [Symlink Map](#symlink-map)
- [Makefile Workflows](#makefile-workflows)
- [npx Install \& Coexistence](#npx-install--coexistence)
- [Makefile Targets](#makefile-targets)

## Architecture

This repo and one third-party directory work together:

| Location                                       | What it holds                                     | Role                           |
| ---------------------------------------------- | ------------------------------------------------- | ------------------------------ |
| `~/workspace/agent-skills/` (this repo)        | Skills (`skills/`), agent instructions (`agents/`) | **Source-of-truth**            |
| `~/.agents/skills/`                            | Third-party skills (find-skills, vercel-\*, etc.) | Managed by `npx skills add`    |
| `~/workspace/agent-skills/personal/configs/`   | Snapshots of tool configs                         | Read-only backup               |

## Symlink Map

```mermaid
graph TB
    subgraph sources["Source of Truth"]
        repo["~/workspace/agent-skills/<br/>·  skills/*  ·  agents/*  ·  AGENTS.md  ·"]
        thirdparty["~/.agents/skills/*"]
    end

    subgraph claude["~/.claude/"]
        direction LR
        claude_skills["skills/*"]
        claude_md["CLAUDE.md"]
    end

    subgraph gemini["~/.gemini/"]
        direction LR
        gemini_skills["antigravity/skills/*"]
        gemini_md["GEMINI.md"]
    end

    subgraph codex["~/.codex/"]
        direction LR
        codex_skills["skills/*"]
        codex_md["AGENTS.md"]
    end

    backup["~/workspace/configs/<br/>(read-only backup)"]

    repo -->|"symlink"| claude_skills
    repo -->|"symlink"| gemini_skills
    repo -->|"symlink"| codex_skills
    repo -->|"AGENTS.md"| claude_md
    repo -->|"MEMORIES.md"| gemini_md
    repo -->|"AGENTS.md"| codex_md

    thirdparty -->|"symlink"| claude_skills
    thirdparty -->|"symlink"| gemini_skills
    thirdparty -->|"symlink"| codex_skills

    claude -.->|"make sync"| backup
    gemini -.->|"make sync"| backup
    codex -.->|"make sync"| backup
```

## Makefile Workflows

```mermaid
graph LR
    skills["agent-skills/skills/*"]
    agents["agent-skills/agents/"]

    subgraph outbound["Symlink OUT"]
        link["make link-skills"]
    end

    subgraph inbound["Copy IN"]
        sync["make sync"]
    end

    claude_dir["~/.claude/"]
    gemini_dir["~/.gemini/"]
    codex_dir["~/.codex/"]
    snapshots["~/workspace/configs/"]

    skills -->|"skills symlink"| link
    agents -->|"instructions symlink"| link
    link --> claude_dir
    link --> gemini_dir
    link --> codex_dir

    claude_dir -->|"file copy"| sync --> snapshots
    gemini_dir -->|"file copy"| sync
    codex_dir -->|"file copy"| sync
```

- **`make link-skills`** symlinks skills and agent instructions FROM this repo INTO all tool dirs (Claude, Gemini, Codex)
- **`make sync`** copies FROM tool dirs INTO `~/workspace/configs/` (one-way backup for git history)

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
