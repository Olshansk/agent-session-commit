---
name: cmd-done-check
description: Ask the agent whether it finished everything or has more to do — a lightweight completeness gate for the end of any task
disable-model-invocation: false
---

# Done Check

A quick self-interrogation to catch loose ends before declaring a task complete.

## Instructions

Answer each question honestly. If anything is incomplete, say so and ask the user whether to continue.

### 1. Did you do everything the user asked?

- Re-read the original request. Is every explicit ask addressed?
- Did you skip or defer anything without telling the user?
- Did you say "I'll also..." or "next, we should..." and then not do it?

### 2. Did you leave any loose ends?

- Are there TODOs, FIXMEs, or placeholder values you introduced that should be resolved now?
- Are there commented-out blocks, debug prints, or temporary stubs in the output?
- Are there follow-up steps you mentioned but didn't take?

### 3. Did you handle side effects?

- Are there related files, configs, or tests that should be updated but weren't?
- Did any rename, move, or deletion leave dangling references?
- If you added a skill/command/export — is it wired up and discoverable?

### 4. Are docs and metadata consistent?

- If you added or changed something user-facing, is the README or AGENTS.md updated?
- Are variable names, comments, and doc strings consistent with what shipped?

## Output

**If everything is done:** say "Done — nothing left." in one line.

**If something is incomplete:** list each item as a bullet with what's missing and why, then ask:

> Want me to continue and handle these now, or are you good?

Do not pad the response. One sentence per finding.
