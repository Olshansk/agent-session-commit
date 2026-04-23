---
name: cmd-follow-up
description: Self-review after implementation — surface missed work, simplification opportunities, and idiomatic improvements
disable-model-invocation: false
---

# Follow-Up

Post-implementation reflection pass. Run after completing a task to catch loose ends and simplify before calling it done.

## Instructions

1. **Determine scope** — use the current branch diff unless the user specifies otherwise:
   - `git diff main...HEAD --name-only`
   - Fall back to staged changes if no branch diff exists
2. **Read all changed files in full** before reviewing.
3. **Answer each question below.** For every finding, cite `file_path:line_number` and fix it directly.
4. **If everything looks good**, say so briefly — don't invent busywork.

## Questions

### 1. Anything left undone?

- Are there TODOs, FIXMEs, or HACKs introduced in this diff that should be resolved now?
- Did you skip something the user asked for?
- Are there commented-out code blocks or placeholder values that shouldn't ship?
- Are there missing error cases, edge cases, or validations at system boundaries?
- Are there fallback/legacy code paths? If so, **ask the user explicitly** whether to keep, remove, or flag them — don't assume backward compatibility is wanted.

### 2. More idiomatic?

- Does the code follow the language's conventions and standard library patterns?
- Are there manual implementations of things the standard library or existing dependencies already provide?
- Does naming follow the project's existing conventions (check surrounding files)?
- Are there language-specific antipatterns? (e.g., Python: bare `except`, mutable default args; Go: exported names that shouldn't be; JS/TS: `any` types that should be narrowed)

### 3. More modular?

- Are there functions doing more than one thing that should be split?
- Is there duplicated logic across the diff that should be extracted?
- Are responsibilities in the right files/modules, or did something land in the wrong place?
- **Counter-check:** Don't extract abstractions for one-time code. Three similar lines is fine.

### 4. Simpler?

- Can any code path be removed or collapsed? (dead branches, unreachable conditions)
- Are there over-engineered patterns? (unnecessary factories, abstractions with one implementation, config for things that won't change)
- Can complex conditionals be simplified or inverted for early returns?
- Is there defensive code for impossible states? (internal callers you control, framework guarantees)

### 5. Web Frontend (Client, React, etc...)

- Check whether async data paths can leave the UI stale after the initial render; if so, add a rerender hook or generation guard.
- Split large renderers and event handlers when they mix loading, state updates, and HTML assembly.
- Centralize shared copy, labels, thresholds, and status text in helpers or constants instead of repeating inline strings.
- Prefer named helper functions for repeated UI fragments, metric formatting, and theme-specific overrides.
- Keep light/dark variants in sync, and verify empty states, filters, and responsive states after edits.

### 6. Comments & prose readable?

Applies to **block code comments, docstrings, and markdown prose ≥ 3 lines** — anywhere a reader hits a paragraph-shaped wall of text. Leave 1–2 line comments alone. Do not add new comments to satisfy this rule; the default is still "no comment." Governs *how* multi-line blocks are written, not *whether* they exist.

- **Open with a one-line summary.** The first line should state the subject in isolation, followed by a blank line.
- **Label sub-sections with a colon header** (e.g., `Context:`, `Workflow:`, `Why:`, `Caveats:`). One header per logical chunk.
- **Bullet points over prose.** Bias to bullets under each sub-header. Break run-on sentences across bullets.
- **Blank lines between sections.** Visual separation matters more than line length.
- **Readability over line-width.** Don't wrap-pack lines to hit a column limit at the cost of scannability.

**Before:**

    - Earnings SA for `CDPIdentityType` (humans): owner EOA is the user's CDP
      Embedded Wallet. The signer lives client-side in the user's browser; Grove
      has NO server-side signer for this EOA. The **client** deploys via
      `grove-app/src/lib/wallet/ensureEarningsDeployed.ts` by sending a
      paymaster-sponsored no-op UserOp. Server-side kickoff is a no-op for this
      identity class — attempting it guarantees a CDP `get_account` 404 because
      embedded EOAs are not Server-Wallet accounts.

**After:**

    Earnings SA for `CDPIdentityType` (humans).

    Context:
    - Owner EOA is the user's CDP Embedded Wallet.
    - The signer lives client-side in the user's browser; Grove has NO server-side signer for this EOA.

    Workflow:
    - The **client** deploys via `grove-app/src/lib/wallet/ensureEarningsDeployed.ts` by sending a paymaster-sponsored no-op UserOp.
    - Server-side kickoff is a no-op for this identity class — attempting it guarantees a CDP `get_account` 404 because embedded EOAs are not Server-Wallet accounts.

**Counter-check:** If restructuring would inflate a 3-line comment into 12 lines of scaffolding (headers, blank lines, single-bullet sections), leave it as prose. Structure pays off when there are multiple logical chunks.

## Output

For each question where you find something actionable:
- Show the finding with `file_path:line_number`
- Apply the fix directly
- One-line explanation of what changed and why

When there are multiple independent action items, prefer a markdown table to present them with columns like `Severity`, `Source`, `Finding`, and `Fix`.
Only use a table when it makes the review easier to scan for the user.
Do not force a table for single findings or tightly coupled issues where plain bullets are clearer.

If nothing actionable is found, say: "Clean — nothing to follow up on."
