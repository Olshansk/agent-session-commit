# agent-skills <!-- omit in toc -->

[![Codex CLI](https://img.shields.io/badge/Codex%20CLI-00A67E)](#)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-D27656)](#)
[![Gemini CLI](https://img.shields.io/badge/Gemini%20CLI-678AE3)](#)
[![OpenCode](https://img.shields.io/badge/OpenCode-3B82F6)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-red.svg)](https://opensource.org/licenses/MIT)

> [!NOTE]
> My personal and public agent skills. [Olshansky.info](https://olshansky.info)

## What is this? <!-- omit in toc -->

- Olshansky's day-to-day agent skills
- Follows the [Agent Skills](https://agentskills.io/home) pattern for cross-tool skill distribution
- Inspired by [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)

## Table of Contents <!-- omit in toc -->

- [Quickstart](#quickstart)
- [Available Skills](#available-skills)
  - [Polished Skills](#polished-skills)
  - [Personal Skills (`cmd-*`)](#personal-skills-cmd-)
- [Star History](#star-history)
- [Demo of `skills-dashboard`](#demo-of-skills-dashboard)
- [How It Works](#how-it-works)

## Quickstart

```bash
npx skills add olshansk/agent-skills
```

Then ask your agent to run any installed skill:

- _"resolve merge conflicts"_
- _"close the loop on this session"_
- _"idiot proof the documentation"_
- _"generate skills dashboard"_

> [!TIP]
> Start with [`session-commit`](skills/session-commit/SKILL.md) — it turns every coding session into durable knowledge by extracting patterns, decisions, and gotchas into your `AGENTS.md`. Future sessions (and future agents) pick up right where you left off.

## Available Skills

### Polished Skills

Skills I've polished for public use.

| Skill                                                  | What it does                                                  | Trigger examples                                           |
| ------------------------------------------------------ | ------------------------------------------------------------- | ---------------------------------------------------------- |
| [`session-commit`](skills/session-commit/SKILL.md)     | Captures session learnings and updates `AGENTS.md` safely     | "run session commit", "close the loop", "update AGENTS.md" |
| [`skills-dashboard`](skills/skills-dashboard/SKILL.md) | Scrapes skills.sh and generates an interactive HTML dashboard | "generate skills dashboard", "show skills ecosystem"       |

### Personal Skills (`cmd-*`)

Skills I use daily but might rename or delete in the future. I prefix them with `cmd-` so I can easily also leverage them as custom slash commands in claude code.

| Skill                                                                          | Description                                                                                   |
| ------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| [`cmd-chain-halt-code-reviewer`](skills/cmd-chain-halt-code-reviewer/SKILL.md) | Review protocol code for chain halt risks, non-determinism, and onchain behavior bugs         |
| [`cmd-gh-issue`](skills/cmd-gh-issue/SKILL.md)                                 | Create structured GitHub issues from conversation context using `gh` CLI                      |
| [`cmd-idiot-proof-docs`](skills/cmd-idiot-proof-docs/SKILL.md)                 | Simplify documentation for clarity and scannability with approval-gated edits                 |
| [`cmd-local-repo-skills`](skills/cmd-local-repo-skills/SKILL.md)               | Scaffold cross-tool repo-local skills with canonical source in `.agents/skills/` and symlinks |
| [`cmd-pr-build-context`](skills/cmd-pr-build-context/SKILL.md)                 | Build high-signal PR context with diff analysis, risk assessment, and discussion questions    |
| [`cmd-pr-conflict-resolver`](skills/cmd-pr-conflict-resolver/SKILL.md)         | Resolve merge conflicts with context-aware 3-tier classification and escalation               |
| [`cmd-pr-description`](skills/cmd-pr-description/SKILL.md)                     | Generate concise PR descriptions by analyzing the diff against a base branch                  |
| [`cmd-pr-gh-comments`](skills/cmd-pr-gh-comments/SKILL.md)                     | Triage and resolve GitHub PR review comments with categorized action plans                    |
| [`cmd-pr-review-prepare`](skills/cmd-pr-review-prepare/SKILL.md)               | Prepare branch for code review by building context and identifying issues                     |
| [`cmd-pr-edgecase`](skills/cmd-pr-edgecase/SKILL.md)                           | Review branch changes for test gaps, logic edge cases, and failure modes                      |
| [`cmd-pr-test-plan`](skills/cmd-pr-test-plan/SKILL.md)                         | Generate manual test plans with verified commands and pass/fail criteria                      |
| [`cmd-productionize`](skills/cmd-productionize/SKILL.md)                       | Transform apps into production-ready deployments with framework-specific optimization         |
| [`cmd-proofread`](skills/cmd-proofread/SKILL.md)                               | Proofread posts for spelling, grammar, repetition, logic, weak arguments, and broken links    |
| [`cmd-follow-up`](skills/cmd-follow-up/SKILL.md)                               | Post-implementation reflection — surface missed work, simplifications, and idiomatic fixes    |
| [`cmd-sculpt-code`](skills/cmd-sculpt-code/SKILL.md)                           | Reshape code for readability, naming, structure, TODOs, and reduced surface area              |
| [`cmd-rfc-review`](skills/cmd-rfc-review/SKILL.md)                             | Review RFCs for problem clarity, compliance, security, and performance using SCQA             |
| [`cmd-rss-feed-generator`](skills/cmd-rss-feed-generator/SKILL.md)             | Generate Python RSS feed scrapers with hourly GitHub Actions integration                      |
| [`cmd-scope-sweep`](skills/cmd-scope-sweep/SKILL.md)                           | Final pass to identify missed items, edge cases, and risks before closing scope               |
| [`makefile`](skills/makefile/SKILL.md)                                         | Create or improve Makefiles with templates (python-uv, fastapi, nodejs, go, flutter)          |
| [`mermaid-render`](skills/mermaid-render/SKILL.md)                             | Render and display Mermaid diagrams inline in iTerm2 or Ghostty                               |

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=olshansk/agent-skills&type=date&legend=top-left)](https://www.star-history.com/#olshansk/agent-skills&type=date&legend=top-left)

## Demo of `skills-dashboard`

A live dashboard of the skills.sh ecosystem is available at **[skills-dashboard.olshansky.info](https://skills-dashboard.olshansky.info/)**.

It shows publisher distribution, install counts, top skills, and the long-tail power law of adoption. Regenerate it yourself with the `skills-dashboard` skill.

![Skills Dashboard](skills-dashboard.png)

## How It Works

### Symlink Architecture <!-- omit in toc -->

Two sources of truth feed into every tool's skills directory:

```mermaid
graph TB
    classDef workspace fill:#d4e6f1,stroke:#2980b9,stroke-width:2px,color:#000
    classDef dotdir fill:#fadbd8,stroke:#e74c3c,stroke-width:2px,color:#000

    subgraph sources["Source of Truth"]
        thirdparty["~/.agents/skills/*<br/>(third-party skills)"]
        repo["~/workspace/agent-skills/<br/>·  skills/*  ·  agents/*  ·<br/>(your skills)"]
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

    repo -->|"symlink (wins on conflict)"| claude_skills
    repo -->|"symlink (wins on conflict)"| gemini_skills
    repo -->|"symlink (wins on conflict)"| codex_skills
    repo -->|"AGENTS.md"| claude_md
    repo -->|"AGENTS.md"| codex_md
    repo -->|"MEMORIES.md"| gemini_md

    thirdparty -->|"symlink"| claude_skills
    thirdparty -->|"symlink"| gemini_skills
    thirdparty -->|"symlink"| codex_skills

    class repo workspace
    class thirdparty,claude_skills,claude_md,gemini_skills,gemini_md,codex_skills,codex_md dotdir
```

| Skill type      | Source of truth       | Installed via      | Symlink target                      |
| --------------- | --------------------- | ------------------ | ----------------------------------- |
| **Your skills** | `skills/` (this repo) | `make link-skills` | `~/workspace/agent-skills/skills/*` |
| **Third-party** | `~/.agents/skills/`   | `npx skills add`   | `~/.agents/skills/*`                |

### Makefile Workflows <!-- omit in toc -->

```mermaid
graph LR
    classDef default color:#000

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

| Target             | Description                                                      |
| ------------------ | ---------------------------------------------------------------- |
| `make link-skills` | Symlink repo + third-party skills into Claude, Gemini, and Codex |
| `make list-skills` | List all skills with descriptions                                |
| `make sync`        | Backup tool configs into `~/workspace/configs/`                  |
| `make test`        | Validate skill frontmatter and repo consistency                  |

### After `npx skills add` <!-- omit in toc -->

`npx skills add` installs third-party skills into `~/.agents/skills/` and creates symlinks in `~/.claude/skills/`. Running `make link-skills` afterward restores your repo skills (which take precedence on name conflicts) and extends third-party skills to Codex and Gemini.
