---
name: cmd-latest-msg
description: Store or retrieve the latest agent message to /tmp/agents/{agent}/
disable-model-invocation: true
---

# Latest Message <!-- omit in toc -->

Persist the last agent message to disk for cross-agent visibility.

## Instructions

1. Parse the user's input after `/cmd-latest-msg`.

2. **`help`** (or no argument) — print usage and stop:

   ```
   Usage:
     /cmd-latest-msg save             — save your last message
     /cmd-latest-msg use <agent>      — read latest from claude|codex|gemini
     /cmd-latest-msg help             — show this usage
   ```

3. **`save`** — save the last assistant message:

   a. Determine which agent you are:
      - Claude Code → `claude`
      - Codex CLI → `codex`
      - Gemini CLI → `gemini`
      - Default → `claude`

   b. Create the output directory:

   ```bash
   mkdir -p /tmp/agents/<agent>
   ```

   c. Capture your **last assistant message** — the response you gave immediately before the user invoked this skill.

   d. Write it to two files using the Write tool:
      - `/tmp/agents/<agent>/latest.md` — always overwrite
      - `/tmp/agents/<agent>/<unix_timestamp>.md` — timestamped copy (use `date +%s` to get the timestamp)

   e. Confirm with:

   ```
   Stored to:
     /tmp/agents/<agent>/latest.md
     /tmp/agents/<agent>/<timestamp>.md
   ```

4. **`use <agent>`** — display another agent's latest message:

   a. Validate `<agent>` is one of: `claude`, `codex`, `gemini`.

   b. Read and display `/tmp/agents/<agent>/latest.md`.

   c. If the file doesn't exist, say: `No messages found for <agent>.`
