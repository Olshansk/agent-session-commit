---
name: cmd-golden-tests
description: "Set up or extend golden/snapshot tests for a project. Covers fixture design, Makefile targets, snapshot storage, diff workflow, and update protocol."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Golden Tests

Golden (snapshot) tests capture the exact output of a pipeline or subsystem as a reference file, then fail any run that deviates from it. They are the highest-fidelity regression check: if anything in the pipeline changes — parsing, mapping, migration, export — the diff tells you exactly what shifted.

## Reference Implementation

The paradigm for this skill comes from `boredm/gint_to_boredm`. Read it before adapting anything:

- Makefile targets: `makefiles/golden.mk`
- Snapshot scripts: `scripts/golden_thompson.py`
- Fixtures: `server/tests/fixtures/`
- Workflow golden: `golden.md`

---

## The Five Setup Questions

Answer these before writing any code or Makefile targets.

### 1. What is the fixture / on-device schema?

The input data the pipeline runs against. Must be:
- **Checked in** to the repo (or clearly documented how to obtain it)
- **Small enough** to run in CI without special infra
- **Representative** of real edge cases, not just happy-path data

In boredm: real `.gpj` files in `thompson_sample/` (binary, not committed to the main repo — seeded via `make seed-thompson`).

### 2. What is the API under test?

How the system is invoked in the golden test. Three patterns:

| Pattern | Use when | Example |
|---------|----------|---------|
| **Direct function call** | Testing a pure transformation | `schema_grouping.build_grouping_outputs(schemas)` |
| **HTTP endpoint via TestClient** | Testing a route end-to-end | `POST /api/units/generate-migrations/{schema}` |
| **Full workflow via manifest** | Testing the entire pipeline | Run wf1–wf7, read manifest from disk |

Avoid mixing patterns in the same golden — pick the right scope.

### 3. What is the golden truth dataset?

The reference snapshot file. Key design choices:

**Semantic golden (single compact file):**
- Extracts a stable subset of the output (row counts, field counts, match types, transformation types)
- Intentionally excludes volatile fields: timestamps, file paths, binary hashes, job IDs
- Sorts all dict keys for deterministic JSON output
- Good for: full-pipeline end-to-end tests

**Phase-level goldens (per-schema per-phase files):**
- One file per `{phase}_{schema}.json` — e.g., `wf1_grouping_file_group_1.json`
- Captures the intermediate state after each workflow phase
- Good for: pinpointing which phase introduced a regression

**Unit-test-style fixture (step-by-step JSON):**
- Inline expected values alongside inputs in the same file
- Steps: `baseline → mutation → restored`
- Good for: idempotency tests, lifecycle tests

### 4. When and how do you update it?

Never silently. The update workflow must be:

1. Run the full pipeline
2. Inspect the diff (unified diff, colorized)
3. Decide: expected change or regression?
4. Only then run the explicit update command

Makefile targets enforce this:

```makefile
golden-{dataset}-verify   # compare without running pipeline
golden-{dataset}-update   # rewrite golden from latest output
golden-{dataset}-wf       # run pipeline + compare (fails on diff)
```

### 5. How do you handle failures, updates, false positives, and false negatives?

| Scenario | Action |
|----------|--------|
| **Expected change** (feature added, behavior improved) | Inspect diff → `make golden-{dataset}-update` → commit both code and golden |
| **Regression** (pipeline broke something) | Fix root cause, never update golden to hide it |
| **False positive** (volatile field leaked into snapshot) | Remove volatile field from snapshot extractor, not from golden |
| **False negative** (golden too coarse, misses real change) | Add a phase-level golden or tighten the snapshot to cover the missed surface |

---

## Makefile Target Naming Convention

Follow this naming pattern. Replace `{dataset}` with the fixture dataset name (e.g., `thompson`).

```makefile
## Golden Tests
golden-{dataset}-test          ## Unit-test-like suite; pytest against JSON fixtures; no server needed
golden-{dataset}-wf            ## Full end-to-end workflow + semantic manifest comparison; server required
golden-{dataset}-verify        ## Compare latest manifest to golden without re-running workflow
golden-{dataset}-update        ## Rewrite semantic golden from latest manifest output
golden-{dataset}-phase-verify  ## Compare all phase-level goldens ({phase}_{schema}.json files)
golden-{dataset}-phase-update  ## Update all phase-level goldens from latest manifest
```

Separate into two modes in the help output:

```
[Golden — unit-like]
  golden-{dataset}-test         Fast; no server; pytest fixtures

[Golden — full workflow]
  golden-{dataset}-wf           Slow; server required; full e2e
  golden-{dataset}-verify       Compare only; no re-run
  golden-{dataset}-update       Rewrite golden (inspect diff first!)
```

---

## Snapshot Storage Layout

```
server/tests/fixtures/
  {dataset}_semantic_wf_verification_golden.json   # single compact semantic golden
  {dataset}_schema_grouping_golden.json            # unit-test-style fixture
  {dataset}_unit_migration_golden.json             # lifecycle fixture with steps
  {dataset}_phase_goldens/
    wf1_grouping_{schema}.json
    wf2_mapping_{schema}.json
    wf3_units_{schema}.json
    wf3b_migrations_{schema}.json
    wf4_normalized_{schema}.json
    wf5_qc_{schema}.json
    wf6_exports_{schema}.json
    wf7_insights_{schema}.json
```

---

## Snapshot Script Pattern

A standalone script (not pytest) manages semantic and phase goldens. Key functions:

```python
def build_snapshot(manifest: dict) -> dict:
    """Extract stable, deterministic subset from full pipeline manifest."""
    # 1. Pull only the fields you care about (row counts, match types, etc.)
    # 2. Exclude volatile fields: timestamps, paths, binary hashes, job IDs
    # 3. Sort all nested dicts for deterministic output

def compare_to_golden(snapshot: dict, golden_path: Path) -> bool:
    """Unified diff, colorized. Returns True if match."""
    # Uses difflib.unified_diff with red/green color codes

def write_golden(golden_path: Path, snapshot: dict) -> None:
    """Rewrite golden file. Sort keys, trailing newline."""
    # json.dumps(data, indent=2, sort_keys=True) + "\n"
```

CLI flags:
```
--verify           compare latest manifest to golden (default)
--update-golden    rewrite semantic golden
--phase-goldens    verify per-phase files
--update-phase-goldens  rewrite per-phase files
--schema           target a specific schema only
--all-schemas      run across all schemas
```

---

## What NOT to Put in a Golden

These leak into diffs and cause false positives:

- Timestamps (`created_at`, `updated_at`, dataset directory names with dates)
- File system paths (absolute or dataset-relative)
- Binary content or checksums
- Cache fingerprints, job IDs, run UUIDs
- Full JSON payloads when a count or summary suffices

---

## Adding Golden Tests to a New Repo

1. Answer the five setup questions above
2. Seed fixture data and document the seed command (`make seed-{dataset}`)
3. Write the snapshot extractor script (`scripts/golden_{dataset}.py`)
4. Write pytest fixtures for unit-test-like checks (`server/tests/test_*_golden.py`)
5. Add Makefile targets following the naming convention above
6. Run once, capture baseline, commit golden files alongside code
7. Add to CI: fail build on golden diff, never auto-update in CI
