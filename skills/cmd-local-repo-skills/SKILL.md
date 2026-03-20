---
name: cmd-local-repo-skills
description: Scaffold cross-tool repo-local skills with canonical source in .agents/skills and symlinks for Claude, Codex, and Codex-home
disable-model-invocation: true
---

# Repo-Local Skill Manager <!-- omit in toc -->

Create or refactor repo-local skills that work across Claude, Codex, and Codex-home using a single canonical source in `.agents/skills/`.

- [Architecture](#architecture)
- [Phase 1: Gather Context](#phase-1-gather-context)
- [Phase 2: Scaffold the Skill](#phase-2-scaffold-the-skill)
  - [2a. Create canonical source](#2a-create-canonical-source)
  - [2b. Create symlinks](#2b-create-symlinks)
  - [2c. Update .gitignore](#2c-update-gitignore)
- [Phase 3: Verify](#phase-3-verify)
- [Templates](#templates)

## Architecture

```
repo-root/
├── .agents/skills/<name>/SKILL.md                        # Canonical source of truth
├── .claude/skills/<name> → ../../.agents/skills/<name>   # Per-skill symlink
├── .codex/skills/<name> → ../../.agents/skills/<name>    # Per-skill symlink
├── .codex-home/skills/<name> → ../../.agents/skills/<name>  # Per-skill symlink
└── .gitignore                                            # Whitelist entries for all paths
```

Key rules:

- `.agents/skills/` is the single source of truth — all other paths are per-skill symlinks
- Each tool directory (`.claude/skills/`, `.codex/skills/`, `.codex-home/skills/`) contains per-skill symlinks pointing back to `.agents/skills/<name>`
- Per-skill symlinks are used instead of directory-level symlinks so externally installed skills (e.g. via `npx skills add`) coexist without conflict
- `.gitignore` uses a base `skills/` ignore rule, then whitelists specific paths
- An optional `evals/` directory inside `.agents/skills/<name>/` is always gitignored

## Phase 1: Gather Context

Before asking questions, run discovery:

```bash
ls .claude/commands/ 2>/dev/null
ls .agents/skills/ 2>/dev/null
grep -n "^skills/" .gitignore 2>/dev/null
```

Present what you found, then use `AskUserQuestion` with these questions (max 4 per call):

1. **Mode**: "Do you want to (a) create a NEW repo-local skill from scratch, or (b) refactor an existing `.claude/commands/` file into the cross-tool skill structure?"
2. **Skill name**: "What should the skill be called? (kebab-case, e.g. `grove-api-review`)"
3. **Description**: "One-line description of what the skill does."
4. **If commands exist**: "Which command file should I migrate?" (list the files found in `.claude/commands/`)

## Phase 2: Scaffold the Skill

### 2a. Create canonical source

Create the canonical directory:

```bash
mkdir -p .agents/skills/<name>
```

**If creating new:**

Create `.agents/skills/<name>/SKILL.md` with frontmatter and a minimal skeleton. Ask the user to provide or iterate on the skill content.

**If refactoring from `.claude/commands/`:**

1. Read the source command file (e.g., `.claude/commands/<name>.md`)
2. Create `.agents/skills/<name>/SKILL.md` with YAML frontmatter added
3. Convert the top-level header to include `<!-- omit in toc -->`
4. Do NOT delete the original command file yet — offer in Phase 3

### 2b. Create per-skill symlinks

Each skill needs a symlink in every tool's skills directory. This approach allows external skills (e.g. from `npx skills add`) to coexist.

```bash
mkdir -p .claude/skills .codex/skills .codex-home/skills
ln -sf ../../.agents/skills/<name> .claude/skills/<name>
ln -sf ../../.agents/skills/<name> .codex/skills/<name>
ln -sf ../../.agents/skills/<name> .codex-home/skills/<name>
```

Check that the symlinks resolve correctly:

```bash
test -f .claude/skills/<name>/SKILL.md && echo "OK" || echo "BROKEN"
```

If a repo already uses a directory-level symlink (`.claude/skills → ../.agents/skills`), migrate to per-skill symlinks first:

```bash
# Only if .claude/skills is itself a symlink to ../.agents/skills
rm .claude/skills .codex/skills .codex-home/skills
mkdir -p .claude/skills .codex/skills .codex-home/skills
for skill in .agents/skills/*/; do
  name=$(basename "$skill")
  ln -s "../../.agents/skills/$name" ".claude/skills/$name"
  ln -s "../../.agents/skills/$name" ".codex/skills/$name"
  ln -s "../../.agents/skills/$name" ".codex-home/skills/$name"
done
```

### 2c. Update .gitignore

The gitignore must be updated carefully to preserve existing entries.

**Step 1 — Check if the base `skills/` rule exists:**

```bash
grep -n "^skills/" .gitignore
```

**Step 2 — Check if entries for this skill already exist:**

```bash
grep "<name>" .gitignore
```

**Step 3 — Append or insert the whitelist block.**

If NO `skills/` section exists, append the full block from the [gitignore template](#gitignore-block-template).

If a `skills/` section already exists (adding a 2nd+ skill), only add the NEW skill-specific lines. The base rules (`skills/`, `!.agents/skills/`, `!.claude/skills`, `!.codex/skills`, `!.codex-home/skills`) already exist — do NOT duplicate them. Insert the new lines after the last entry:

```gitignore
# Only these lines are new for an additional skill:
!.agents/skills/<name>/
!.agents/skills/<name>/SKILL.md
.agents/skills/<name>/evals/
```

Never duplicate a line that already exists in `.gitignore`.

## Phase 3: Verify

Run these checks and report results:

```bash
# Verify per-skill symlinks resolve correctly
readlink .claude/skills/<name>
readlink .codex/skills/<name>
readlink .codex-home/skills/<name>

# Verify skill content is accessible through each symlink
head -3 .claude/skills/<name>/SKILL.md
head -3 .codex/skills/<name>/SKILL.md
head -3 .codex-home/skills/<name>/SKILL.md

# Verify git tracks the canonical skill file
git status .agents/skills/<name>/SKILL.md
```

If refactoring, ask: "The original command file at `.claude/commands/<file>` still exists. Should I delete it now that the skill has been migrated?"

**Present summary:**

```
Skill: <name>
Canonical: .agents/skills/<name>/SKILL.md
Per-skill symlinks:
  .claude/skills/<name> → ../../.agents/skills/<name>      → ✅
  .codex/skills/<name> → ../../.agents/skills/<name>       → ✅
  .codex-home/skills/<name> → ../../.agents/skills/<name>  → ✅
Gitignore: ✅ updated
```

## Templates

### SKILL.md frontmatter template <!-- omit in toc -->

```
 ---
 name: <skill-name>
 description: <one-line description>
 disable-model-invocation: true
 ---

 # Skill Title <!-- omit in toc -->
```

### Gitignore block template <!-- omit in toc -->

Full block for the first skill in a repo (replace `<name>` with the skill name):

```gitignore
# Skills
# Default: ignore generic skills/ trees from external skill repos.
# Exception: keep repo-local cross-tool skills tracked via per-skill symlinks.
skills/
!.agents/skills/
!.agents/skills/<name>/
!.agents/skills/<name>/SKILL.md
.agents/skills/<name>/evals/
# Per-skill symlinks — track each symlink so all tools discover the skill
!.claude/skills/
!.claude/skills/<name>
!.codex/skills/
!.codex/skills/<name>
!.codex-home/skills/
!.codex-home/skills/<name>
```

For additional skills, append only the new skill-specific lines:

```gitignore
!.agents/skills/<name>/
!.agents/skills/<name>/SKILL.md
.agents/skills/<name>/evals/
!.claude/skills/<name>
!.codex/skills/<name>
!.codex-home/skills/<name>
```

### Symlink commands template <!-- omit in toc -->

Per-skill setup (run for each new skill):

```bash
mkdir -p .agents/skills/<name> .claude/skills .codex/skills .codex-home/skills
ln -sf ../../.agents/skills/<name> .claude/skills/<name>
ln -sf ../../.agents/skills/<name> .codex/skills/<name>
ln -sf ../../.agents/skills/<name> .codex-home/skills/<name>
```
