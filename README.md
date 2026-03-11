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

| Skill                          | Description                                                                          |
| ------------------------------ | ------------------------------------------------------------------------------------ |
| [`cmd-chain-halt-code-reviewer`](skills/cmd-chain-halt-code-reviewer/SKILL.md) | Review protocol code for chain halt risks, non-determinism, and onchain behavior bugs |
| [`cmd-clean-code`](skills/cmd-clean-code/SKILL.md) | Improve code readability without altering functionality using idiomatic best practices |
| [`cmd-code-cleanup`](skills/cmd-code-cleanup/SKILL.md) | Remove dead code and duplication with a 5-phase systematic approach |
| [`cmd-gh-comments`](skills/cmd-gh-comments/SKILL.md) | Triage and resolve GitHub PR review comments with categorized action plans |
| [`cmd-gh-issue`](skills/cmd-gh-issue/SKILL.md) | Create structured GitHub issues from conversation context using `gh` CLI |
| [`cmd-idiot-proof-docs`](skills/cmd-idiot-proof-docs/SKILL.md) | Simplify documentation for clarity and scannability with approval-gated edits |
| [`cmd-pr-build-context`](skills/cmd-pr-build-context/SKILL.md) | Build high-signal PR context with diff analysis, risk assessment, and discussion questions |
| [`cmd-pr-conflict-resolver`](skills/cmd-pr-conflict-resolver/SKILL.md) | Resolve merge conflicts with context-aware 3-tier classification and escalation |
| [`cmd-pr-description`](skills/cmd-pr-description/SKILL.md) | Generate concise PR descriptions by analyzing the diff against a base branch |
| [`cmd-pr-review-prepare`](skills/cmd-pr-review-prepare/SKILL.md) | Prepare branch for code review by building context and identifying issues |
| [`cmd-pr-sweep`](skills/cmd-pr-sweep/SKILL.md) | Review changes for test gaps, simplification, naming consistency, reuse, and TODO quality |
| [`cmd-pr-test-plan`](skills/cmd-pr-test-plan/SKILL.md) | Generate manual test plans with verified commands and pass/fail criteria |
| [`cmd-productionize`](skills/cmd-productionize/SKILL.md) | Transform apps into production-ready deployments with framework-specific optimization |
| [`cmd-proofread`](skills/cmd-proofread/SKILL.md) | Proofread posts for spelling, grammar, repetition, logic, weak arguments, and broken links |
| [`cmd-python-stylizer`](skills/cmd-python-stylizer/SKILL.md) | Analyze Python code for naming, structure, nesting, and cognitive load reduction |
| [`cmd-rfc-review`](skills/cmd-rfc-review/SKILL.md) | Review RFCs for problem clarity, compliance, security, and performance using SCQA |
| [`cmd-rss-feed-generator`](skills/cmd-rss-feed-generator/SKILL.md) | Generate Python RSS feed scrapers with hourly GitHub Actions integration |
| [`cmd-scope-sweep`](skills/cmd-scope-sweep/SKILL.md) | Final pass to identify missed items, edge cases, and risks before closing scope |
| [`makefile`](skills/makefile/SKILL.md) | Create or improve Makefiles with templates (python-uv, fastapi, nodejs, go, flutter) |
| [`mermaid-render`](skills/mermaid-render/SKILL.md) | Render and display Mermaid diagrams inline in iTerm2 or Ghostty |

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=olshansk/agent-skills&type=date&legend=top-left)](https://www.star-history.com/#olshansk/agent-skills&type=date&legend=top-left)

## Demo of `skills-dashboard`

A live dashboard of the skills.sh ecosystem is available at **[skills-dashboard.olshansky.info](https://skills-dashboard.olshansky.info/)**.

It shows publisher distribution, install counts, top skills, and the long-tail power law of adoption. Regenerate it yourself with the `skills-dashboard` skill.

![Skills Dashboard](skills-dashboard.png)
