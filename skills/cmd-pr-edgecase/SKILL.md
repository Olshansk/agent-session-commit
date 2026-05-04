---
name: cmd-pr-edgecase
description: Review branch changes for test gaps, logic edge cases, failure modes, and integration risks
disable-model-invocation: false
---

# PR Edge Case Review

Review branch changes for logic correctness. This skill finds what breaks, not what looks bad — use `cmd-sculpt-code` for code quality.

## Determine Scope

**Default (no scope specified):** diff the current branch against the repo's base branch.

Detect the base branch in order — stop at the first success:

1. `gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null`
2. `git remote show origin 2>/dev/null | grep "HEAD branch" | cut -d: -f2 | xargs`
3. `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'`

Do **not** assume `main` or `master`. If all methods fail, ask the user.

Once resolved, run:

```bash
git diff <base>...HEAD -- ":(exclude)*.lock" ":(exclude)package-lock.json" ":(exclude)pnpm-lock.yaml" ":(exclude)package.json"
```

**If the user specifies a scope**, use the corresponding command instead:

| Scope | Command | What it covers |
|---|---|---|
| `unstaged` | `git diff HEAD -- <excludes>` | All uncommitted changes (staged + unstaged) |
| `last commit` / `last 1 commit` | `git diff HEAD~1...HEAD -- <excludes>` | Changes in the most recent commit |
| `last N commits` | `git diff HEAD~N...HEAD -- <excludes>` | Changes in the last N commits |
| `entire repo` | `git ls-files \| grep -vE "\.(lock\|snap)$\|package-lock\.json\|pnpm-lock\.yaml"` | All tracked source files; no diff — apply all dimensions to the full current state of the codebase |

For all diff commands, apply: `-- ":(exclude)*.lock" ":(exclude)package-lock.json" ":(exclude)pnpm-lock.yaml" ":(exclude)package.json"`

## Instructions

1. **Determine scope** using **Determine Scope** above — ask if still unclear after applying those rules.
2. **Read all changed files in full** before reviewing — understand the context around the diff, not just the changed lines.
3. **Review each dimension** below. For each finding, cite `file_path:line_number`.

## Dimensions

### 1. Test Gaps

- New code paths without corresponding tests
- Missing edge case coverage: empty inputs, zero values, nil/null, boundary values
- Error paths that aren't tested (what happens when the DB call fails? the API returns 500?)
- Testable helpers or utilities that lack unit tests
- Existing tests that may be invalidated by the changes

### 2. Logic Simplification

- Conditional branches that can be collapsed or are mutually exclusive
- Defensive code that can't trigger (checking for nil after a constructor that never returns nil)
- Redundant validation (checking the same condition at multiple layers)
- Complex boolean expressions that could be a single predicate
- Switch/match statements missing cases or with unreachable default branches

### 3. Edge Cases & Failure Modes

- What happens with empty collections, zero-length strings, negative numbers?
- Concurrent access: race conditions, double-submission, stale reads
- Partial failures: what if step 2 of 3 fails? Is state left consistent?
- Resource exhaustion: unbounded loops, unlimited retries, growing memory
- Time-dependent behavior: timezone issues, DST, clock skew, expiry edge cases
- Integer overflow, floating-point precision, string encoding issues
- Off-by-one errors in loops, pagination, slicing

### 4. Integration Risks

- Breaking changes to public APIs, function signatures, or data formats
- Database migration safety: can it be rolled back? Does it lock tables?
- Dependency version changes: breaking updates, deprecation warnings
- Configuration changes that could affect other environments
- Feature flags or environment checks that may behave differently in prod
- Backward compatibility: will existing clients/callers still work?

## Output Format

For each dimension, output:

```
### [Dimension Name]

- **[file:line]** — Finding description
  Risk: [what could go wrong]
  Suggestion: [how to address it]
```

If a dimension has no findings, output: `No issues found.`

## Final Summary

End with:
1. **Top 3-5 risks** ranked by severity (what is most likely to cause a production incident?)
2. **Recommended test cases** to add before merging
