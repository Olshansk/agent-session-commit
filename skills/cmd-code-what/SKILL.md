---
name: cmd-code-what
description: Catch the user up on what the agent has been doing in the current session with 3-5 ultra-tight bullet points. Use when the user invokes /cmd-what, asks "what are you doing", "what did you do", "catch me up", "status", "where are we", or otherwise needs a fast situational summary of in-flight agent work.
disable-model-invocation: true
---

# What <!-- omit in toc -->

Give the user a high-signal, low-noise snapshot of what's happened in this session so they can re-enter the loop without scrolling back.

## Output format

Reply with **3-5 bullet points only**. No preamble, no closing summary, no headers, no follow-up questions. Each bullet must be:

```
- **1-3 word label**: explanation in less than 120 characters
```

Hard rules:

- **3-5 bullets, no more, no less in spirit** (4 is the sweet spot)
- **Label**: 1-3 words, bolded, title-case or kebab-case, names a concrete thing (file, action, decision, blocker)
- **Explanation**: a single clause, **< 120 characters including the label**, present tense or past tense — never future tense ("will", "going to")
- No nested bullets, no code fences, no links, no emoji unless one is genuinely load-bearing
- Skip anything the user already knows from the last 1-2 turns — focus on what they'd miss if they just walked back to the terminal

## What to include (in priority order)

1. **Current focus** — what file/task is actively being worked on right now
2. **Most recent concrete change** — what just got written, edited, run, or decided
3. **Blocker or open question** — anything waiting on the user, or that's stuck
4. **Next step** — the very next action the agent intends to take, if obvious
5. **Notable side effects** — files created, branches touched, processes started, only if relevant

## What to leave out

- Restating the original user request verbatim
- Tool-call narration ("I ran ls, then grep, then…")
- Anything that happened more than ~10 turns ago unless it's still load-bearing
- Hedging, qualifiers, or meta-commentary about the summary itself

## Example

User: `/cmd-what`

Good response:

```
- **Editing**: refactoring `auth/session.py` to drop the legacy cookie path
- **Tests**: 14/16 passing, 2 failing on token refresh edge case
- **Blocked**: need to know if expired refresh tokens should silently re-auth or 401
- **Next**: wire the chosen behavior into `refresh_token()` once you decide
```

Bad response (too verbose, narrates tool calls, future-tense, missing labels):

```
- I started by reading the auth module and then I grepped for cookie usage
- I'm planning to refactor the session handling but first I want to check with you
- The tests will probably need updates too
```
