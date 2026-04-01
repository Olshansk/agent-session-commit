---
name: cmd-pr-edgecase
description: Review branch changes for test gaps, logic edge cases, failure modes, and integration risks
disable-model-invocation: false
---

# PR Edge Case Review

Review branch changes for logic correctness. This skill finds what breaks, not what looks bad — use `cmd-sculpt-code` for code quality.

## Instructions

1. **Identify the change scope** — ask if unclear:
   - Branch diff: `git diff main...HEAD`
   - Uncommitted: `git diff HEAD`
   - Specific files: user-provided list
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
