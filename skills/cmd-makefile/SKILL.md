---
name: cmd-makefile
description: "Create or improve Makefiles with minimal complexity. Templates available: base, python-uv, python-fastapi, postgres, nodejs, go, chrome-extension, flutter, electron, static-site."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Makefile Helper

Create Makefiles that are simple, discoverable, and maintainable.

## Core Principles

1. **Default to rich help** - Use categorized help with emoji headers unless user requests minimal
2. **Default Chrome extensions to modular** - Use the modular `makefiles/*.mk` layout with shared colors/help for Chrome extension projects unless the repo is truly tiny
3. **Ask about structure upfront** - For new Makefiles, ask: "Flat or modular? Rich help or minimal?"
4. **Follow existing conventions** - Match the project's style if Makefile already exists
5. **Don't over-engineer** - Solve the immediate need, not hypothetical futures
6. **Use `uv run`** - Always run Python commands via `uv run` for venv context
7. **Explain decisions** - If choosing flat/minimal, explain why before generating

## When to Use This Skill

- Creating a new Makefile for a project
- Adding specific targets to an existing Makefile
- Improving/refactoring an existing Makefile
- Setting up CI/CD make targets
- Distributing pre-built binaries via GitHub Releases

## Quick Start

For new projects, use the appropriate template:

| Project Type | Template | Complexity | Asks upfront |
|-------------|----------|------------|------|
| Any project | `templates/base.mk` | Minimal | — |
| Python with uv | `templates/python-uv.mk` | Standard | — |
| Python FastAPI | `templates/python-fastapi.mk` | Full-featured | test split? prod target? `HEALTH_PATH`? |
| PostgreSQL + Alembic | `templates/postgres.mk` | Standard | `PG_PORT` (5433 default)? soft vs HARD reset? |
| Node.js | `templates/nodejs.mk` | Standard | — |
| Go | `templates/go.mk` | Standard | — |
| Chrome Extension | `templates/chrome-extension.mk` | Modular | — |
| Flutter App | `templates/flutter.mk` | Modular | — |
| Electron App | `templates/electron.mk` | Modular | — |
| Static Site (HTML/CSS/JS) | `templates/static-site.mk` | Standard | `DEPLOY_MODE` (rsync/gh-pages/netlify/vercel/none)? |

For templates in the "Asks upfront" column, run the Phase 2 interactive questions in §"Interaction Pattern" before scaffolding. Companion files:

- `templates/python-fastapi-env/.template.env` → project's `.template.env`
- `templates/python-fastapi-scripts/export_openapi_spec.py` → `scripts/export_openapi_spec.py`
- `templates/postgres-env/.template.env` → merge into project's `.template.env` (don't ship two)

### Chrome Extension Structure

The chrome extension template uses a modular structure:

```
Makefile                              # Main file with help + includes
makefiles/
  colors.mk                           # ANSI colors & print helpers
  common.mk                           # Shell flags, VERBOSE mode, guards
  build.mk                            # Build zip, version bump, releases
  dev.mk                              # Lint, clean, install
  test.mk                             # Unit tests, E2E tests, coverage
  env.mk                              # Environment setup, dependency checks
```

Copy from `templates/chrome-extension-modules/` to your project's `makefiles/` directory.

**Key features:**
- Use `makefiles/colors.mk` for ANSI color output and header helpers.
- Use `makefiles/common.mk` for shell flags, guard rails, and shared variables.
- Use `makefiles/env.mk` for environment checks and dependency sanity.
- Use `makefiles/build.mk` for build/package/release targets.
- Use `makefiles/dev.mk` for install, watch, clean, and other local workflows.
- Use `makefiles/test.mk` for typecheck, unit, and E2E targets when present.
- `build-release` - Version bump menu (major/minor/patch) + zip for Chrome Web Store
- `build-beta` - (Optional) GitHub releases with `gh` CLI
- `test-unit` / `test-e2e` - Vitest + Playwright testing
- `test-unit-<module>` / `test-e2e-<module>` - Per-module test targets
- `VERBOSE=1 make <target>` - Show commands for debugging

### Flutter App Structure

```
Makefile                    # Main file with help + includes
makefiles/
  colors.mk                # ANSI colors & print helpers
  common.mk                # Shell flags, VERBOSE mode, guards
  dev.mk                   # Setup, run simulator/device, devices, clean
  build.mk                 # iOS/Android builds (IPA, APK, AAB)
  deploy.mk                # TestFlight upload
  lint.mk                  # Dart analyze & format
```

Copy from `templates/flutter-modules/` to your project's `makefiles/` directory.

**Key features:**
- `flutter-run-ios` auto-boots simulator and waits for it
- `flutter-run-android` auto-launches emulator and waits for it
- `flutter-run-device` auto-detects or uses `FLUTTER_IOS_DEVICE` / `FLUTTER_ANDROID_DEVICE`
- `flutter-build-ipa` + `flutter-export-ipa` + `flutter-deploy-testflight` full iOS release workflow
- `flutter-export-ipa` re-exports IPA from existing archive without rebuilding
- `_check-asc-app` pre-flight App Store Connect validation (with ASC_API_KEY/ASC_API_ISSUER)
- `flutter-lint FIX=true` Dart formatting with FIX pattern
- `VERBOSE=1 make <target>` show commands for debugging

### Electron App Structure

```
Makefile                    # Main file with help + includes
makefiles/
  colors.mk                # ANSI colors & print helpers
  common.mk                # Shell flags, VERBOSE mode, guards
  dev.mk                   # Setup, dev server, debug, clean
  build.mk                 # Pack-check, dist (mac/win/linux), publish
  lint.mk                  # ESLint, Prettier, TypeScript, tests
```

Copy from `templates/electron-modules/` to your project's `makefiles/` directory.

**Key features:**
- `electron-dev` starts dev mode with hot-reload
- `electron-debug` launches with DevTools open
- `electron-clean` single target that removes artifacts, node_modules, and lock file
- `electron-pack-check` smoke-tests that the app loads without errors
- `electron-dist-mac` / `electron-dist-win` / `electron-dist-linux` cross-platform builds
- `electron-dist-all` builds for all platforms in one shot
- `electron-publish` publishes to GitHub Releases (requires `GH_TOKEN`)
- `electron-lint FIX=true` ESLint + Prettier with auto-fix pattern
- `electron-typecheck` TypeScript type checking
- `VERBOSE=1 make <target>` show commands for debugging

### Static Site (HTML/CSS/JS)

Plain static sites — landing pages, marketing pages, docs — with no bundler or SSR. Uses `npx --yes` for tooling so contributors don't need a local `package.json` or `node_modules`.

Copy `templates/static-site.mk` to your project root as `Makefile`.

Targets use `site-*` and `dev-*` prefixes (per §"Naming Conventions"). The template is deliberately slim — lint/link-check/image-optimization targets were cut because they're rarely run locally on a marketing page and collapse under the "too many granular `dev-*` quality targets" pitfall. Add them back only if a specific project needs them.

**Key features:**
- `site-serve` - local HTTP server via `python3 -m http.server` (falls back to `npx serve`). Override with `make site-serve PORT=9000 HOST=0.0.0.0`.
- `site-open` - open `$(ENTRY)` (default `index.html`) in the default browser (macOS `open` / Linux `xdg-open`).
- `site-status` - print site dir, entry, detected HTML pages, and tooling availability.
- `dev-format` - prettier `--write` across HTML/CSS/JS via `npx --yes`. No global install required, no `FIX=true` gate — always writes (formatting check-only is CI's job, not a local ergonomic).
- `dev-asset-report` - top 20 largest files (finds accidentally-committed hero images, uncompressed GIFs).
- `dev-build` - copies site into `$(BUILD_DIR)` (default `dist/`) via rsync with sensible excludes, then optionally minifies HTML/CSS/JS via `html-minifier-terser` (silently skipped if unavailable).
- `dev-deploy` - depends on `dev-build`; dispatches on `DEPLOY_MODE` (`rsync` | `gh-pages` | `netlify` | `vercel` | `none`). Fails fast with install hint if the selected tool is missing.
- `dev-clean` - removes `$(BUILD_DIR)/`.

**Config knobs (`?=` — override on command line):** `SITE_DIR`, `PORT`, `HOST`, `ENTRY`, `BUILD_DIR`, `DEPLOY_MODE`, `RSYNC_DEST`.

### PostgreSQL + Alembic

Standalone template for database operations. Use alongside `python-fastapi.mk` for a full stack, or independently for any Python project with PostgreSQL.

Copy `templates/postgres.mk` to your project root (or `include` it from your main Makefile).

**Key features:**
- `db-start` / `db-stop` / `db-clean` via plain `docker run` (default) with health-check wait loop. Docker Compose variant is commented at the bottom of the template for multi-service setups.
- `db-init` composite target (start + migrate).
- `db-reset` has two flavors via `HARD` flag:
  - `HARD=false` (default): kill connections → DROP DATABASE → CREATE → migrate. Fast, preserves container+volume.
  - `HARD=true`: `docker rm -f` container + `docker volume rm -f` + re-init. Use when container/volume itself is in a broken state.
- `db-migrate` / `db-revision` Alembic migrations via `uv run alembic`; **all Alembic recipes inline-source `.env`** (via `_check-env` guard) so a stale shell `DATABASE_URL` can't override the configured value.
- `db-migration-current` / `db-migration-history` / `db-migration-check` introspection.
- `db-shell` (psql) / `db-pgcli` / `db-pgweb` shell access.
- `db-pgcli` strips the SQLAlchemy `+psycopg` dialect marker before handing the URL to pgcli (pgcli doesn't understand dialect markers).
- `env-template` bootstrap target that copies `.template.env` → `.env` without overwriting.
- `db-logs` / `db-seed` utilities.
- All config via `?=` variables (`PG_CONTAINER`, `PG_DB`, `PG_USER`, `PG_PASSWORD`, `PG_PORT=5433`, `PG_IMAGE`).
- **Port 5433 by default** to dodge host Homebrew Postgres on 5432. Override with `make db-start PG_PORT=5432` if your machine is clean.
- **Driver**: template targets `psycopg[binary]>=3` (psycopg3). SQLAlchemy needs the `postgresql+psycopg://` dialect marker; add a pydantic-settings validator that normalizes `postgres://` / `postgresql://` → `postgresql+psycopg://` so Render's managed DB URL works verbatim.

## Interaction Pattern (Phased)

Run these phases top-to-bottom on any Makefile scaffolding / refactor request. Do **Phase 2 (Interactive questions) BEFORE writing any file** — the answers drive which template variants to emit.

### Phase 1 — Discovery

1. Is there already a Makefile? Read it first — match its conventions.
2. What stack / language? (Python+uv, FastAPI+Postgres, Node, Go, …)
3. What's the deployment target? (Render, Fly, Vercel, self-hosted, …) — affects `run-api-prod`.
4. How big is the project today, and how big will it reasonably grow? (≥5 targets expected → modular.)

### Phase 2 — Interactive questions (ask in ONE batch via `AskUserQuestion`)

Ask up front rather than iterating. Typical questions:

- **Structure**: flat single file or modular (`makefiles/*.mk`)?
- **Help style**: rich categorized help with emoji headers, or minimal?
- **Postgres port** (if Postgres used): `5433` (default, dodges host Homebrew Postgres on 5432) or `5432`?
- **Test granularity**: single `dev-test` (small/medium projects) or split `test-unit` / `test-integration` / `test-e2e` (larger projects)?
- **Prod runtime**: need a `run-api-prod` target against a remote DB (Render/Fly/etc.)?
- **OpenAPI spec export** (FastAPI): always include `api-export-spec` unless user declines — enables client SDK generation and spec-diff in CI.

Skip questions whose answer is already implied by an existing Makefile or strong project signal.

### Phase 3 — Scaffold

Emit (in this order):

1. `Makefile` + `makefiles/*.mk` (if modular).
2. `.template.env` at repo root (committed).
3. `.env` is **NOT** created — leave that to `make env-template`. Add `.env` to `.gitignore` if not already there.
4. `.env.prod` — if `run-api-prod` was requested, confirm `.env.prod` is in `.gitignore` (it MUST be — production credentials).
5. `scripts/export_openapi_spec.py` (if FastAPI + api-export-spec).

### Phase 4 — Verify

- `make help` — clean categorized output.
- `make help-unclassified` — should be empty or minimal.
- `make -n run-api-local db-migrate api-export-spec` — dry-run the critical paths.
- Grep for any `_check-env` / `_check-postgres` guards you added to confirm they fire when expected.

## Naming Conventions

Use **kebab-case** with consistent prefix-based grouping:

```makefile
# Good - consistent prefixes (hyphens, not underscores)
build-release, build-zip, build-clean    # Build tasks
dev-run, dev-clean                       # Development tasks
db-start, db-stop, db-migrate            # Database tasks
env-local, env-prod, env-show            # Environment tasks

# Internal targets - prefix with underscore to hide from help
_build-zip-internal, _prompt-version     # Not shown in make help

# Bad - inconsistent
run-dev, localEnv, test_net
build_release, dev_test                  # Underscores - don't use
```

**Exception — universal unprefixed names.** A handful of names are so de-facto standard across ecosystems (npm, cargo, go, make itself) that prefixing them with `dev-` adds noise without adding signal. Keep these unprefixed:

- `test` (not `dev-test`)
- `build` (not `dev-build`) — **only if** the project has no competing `build-*` group
- `run` (not `dev-run`) — same caveat
- `format` / `lint` — same caveat; if you have `dev-format` already, stay consistent within the project

Rule of thumb: if the unprefixed name would collide with a prefix group you already have (e.g., already have `build-release`, `build-zip`), keep the `dev-` prefix for consistency. Otherwise, drop it.

**Name targets after the action, not the tool:**
```makefile
# Good - describes what it does
remove-bg          # Removes background from image
format-code        # Formats code
lint-check         # Runs linting

# Bad - names the tool
rembg              # What does this do?
prettier           # Is this running prettier or configuring it?
eslint             # Unclear
```

## Key Patterns

### Binary Distribution

For projects distributed as pre-built binaries via GitHub Releases:

```makefile
GITHUB_REPO ?= owner/repo
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')

.PHONY: install-cli
install-cli: ## Download and install CLI from latest GitHub release
	@RELEASE=$$(curl -fsSL https://api.github.com/repos/$(GITHUB_REPO)/releases/latest | grep tag_name | cut -d'"' -f4); \
	echo "Installing $$RELEASE for $(OS)/$(ARCH)..."; \
	curl -fsSL -o ~/.local/bin/cli \
		"https://github.com/$(GITHUB_REPO)/releases/download/$$RELEASE/cli-$(OS)-$(ARCH)"; \
	chmod +x ~/.local/bin/cli
```

**Key considerations:**
- Detect OS and architecture automatically
- Download from GitHub Releases (no Python/uv required)
- Install to `~/.local/bin` (user-writable, in PATH)
- Preserve existing config files during updates

### Always Use `uv run` for Python

```makefile
# Good - uses uv run with ruff (modern tooling)
dev-check:
	uv run ruff check src/ tests/
	uv run ruff format --check src/ tests/
	uv run mypy src/

dev-format:
	uv run ruff check --fix src/ tests/
	uv run ruff format src/ tests/

# Bad - relies on manual venv activation
dev-format:
	ruff format .
```

### Use `uv sync` (not pip install)

For Python projects, treat `pyproject.toml` and `uv.lock` as the source of truth.
Do not add `pip install` or `requirements.txt` fallback guidance to uv-based templates.

```makefile
env-install:
	uv sync  # Uses pyproject.toml + lock file
```

### Categorized Help (for 5+ targets)

```makefile
help:
	@printf "$(BOLD)=== 🚀 API ===$(RESET)\n"
	@printf "$(CYAN)%-25s$(RESET) %s\n" "api-run" "Start server"
	@printf "%-25s $(GREEN)make api-run [--reload]$(RESET)\n" ""
```

**Makefile ordering rule - help targets go LAST, just before catch-all:**

1. Configuration (`?=` variables)
2. `HELP_PATTERNS` definition
3. Imports (`include ./makefiles/*.mk`)
4. Main targets (grouped by function)
5. `help:` and `help-unclassified:` targets
6. Catch-all `%:` rule (absolute last)

### Preflight Checks

```makefile
_check-docker:
	@docker info >/dev/null 2>&1 || { echo "Docker not running"; exit 1; }

db-start: _check-docker  # Runs check first
	docker compose up -d
```

### External Tool Dependencies

When a target requires an external tool (not a system service):

- **Don't create public install targets** (no `make install-foo`)
- **Use internal check as dependency** (prefix with `_`, no `##` comment)
- **Show install command on failure** - tell user what to run, don't do it for them

```makefile
# Internal check - hidden from help (no ##)
_check-rembg:
	@command -v rembg >/dev/null 2>&1 || { \
		printf "$(RED)$(CROSS) rembg not installed$(RESET)\n"; \
		printf "$(YELLOW)Run: uv tool install \"rembg[cli]\"$(RESET)\n"; \
		exit 1; \
	}

# Public target - uses check as dependency
.PHONY: remove-bg
remove-bg: _check-rembg ## Remove background from image
	rembg i "$(IN)" "$(OUT)"
```

**Key points:**
- Name target after the action (`remove-bg`), not the tool (`rembg`)
- Check runs automatically - user just runs `make remove-bg`
- If tool missing, user sees exactly what command to run

### Env File Loading

**Primary recommendation: inline-source per recipe.** This is the only pattern that *overrides* stale shell-exported vars, which is the pitfall you'll actually hit in practice.

```makefile
# Inline-source: recipe's DATABASE_URL comes from .env, not the user's shell
db-upgrade:
	@set -a && . ./.env && set +a && uv run python -m alembic upgrade head

run-api-local:
	@set -a && . ./.env && set +a && uv run uvicorn app.main:app --reload
```

Per-target override (e.g., test env, prod env):

```makefile
# Allow: E2E_ENV=.test.env make test-e2e
test-e2e:
	@set -a && . "$${E2E_ENV:-.env}" && set +a && uv run pytest tests/e2e/
```

**Secondary (simpler but weaker): top-of-Makefile load.** Fine for projects where no one exports the same vars in their shell. Does **not** override an already-exported shell var — so don't use this for DB URLs or anything that commonly lives in shell profiles.

```makefile
# At top of Makefile, after .DEFAULT_GOAL
-include .env
.EXPORT_ALL_VARIABLES:
```

> ⚠️ **Shell-override footgun.** If a user has `export DATABASE_URL=...` in their `.zshrc` (or manually in the current shell), the `-include` form silently loses: their shell env wins over `.env`. Alembic/uvicorn will hit the wrong DB with zero warning. Use the inline-source pattern for any recipe that depends on a specific `.env` value.

### `.env` / `.template.env` Bootstrap

**Always ship a `.template.env`. Never ship a `.env`.**

- `.template.env` is committed to git. It tracks the *schema* of env vars the project expects — every new env var in code gets a placeholder here in the same PR.
- `.env` is gitignored. Each developer fills in real values locally.
- Every recipe that sources `.env` should preflight-check its existence and print a friendly "run `make env-template`" if missing.
- Ship a `make env-template` target that copies `.template.env` → `.env` but **never overwrites** an existing `.env`.

```makefile
_check-env:
	@if [ ! -f .env ]; then \
		printf "$(RED)$(CROSS) .env not found$(RESET)\n"; \
		printf "$(YELLOW)$(INFO) Run 'make env-template' or 'cp .template.env .env'$(RESET)\n"; \
		exit 1; \
	fi

env-template: ## Create .env from .template.env (safe: never overwrites)
	@if [ -f .env ]; then \
		printf "$(YELLOW)$(INFO) .env already exists — leaving it alone$(RESET)\n"; \
	elif [ ! -f .template.env ]; then \
		printf "$(RED)$(CROSS) .template.env not found$(RESET)\n"; exit 1; \
	else \
		cp .template.env .env; \
		printf "$(GREEN)$(CHECK) Created .env from .template.env — fill in real values$(RESET)\n"; \
	fi

run-api-local: _check-env
	@set -a && . ./.env && set +a && uv run uvicorn app.main:app --reload
```

**Why not just `-include .env` at the top of the Makefile?** See §"Env File Loading" above — `-include` silently loses to already-exported shell vars. The `.template.env` + `_check-env` + inline-source pattern is robust against that footgun AND gives new contributors a one-command bootstrap.

### OpenAPI Spec Export (FastAPI)

Ship a standard `api-export-spec` target whenever you scaffold a FastAPI project. Benefits:

- Enables spec-diff in CI (catch accidental breaking API changes in PRs).
- Unblocks typed client generation (`openapi-typescript`, `datamodel-code-generator`, etc.).
- Gives external consumers a stable URL-less artifact to pin against.

Pair it with `templates/python-fastapi-scripts/export_openapi_spec.py`:

```makefile
api-export-spec: ## Export OpenAPI spec to openapi.json
	uv run python scripts/export_openapi_spec.py
```

```python
# scripts/export_openapi_spec.py
from app.main import app
import json
from pathlib import Path

(Path(__file__).parents[1] / "openapi.json").write_text(
    json.dumps(app.openapi(), indent=2) + "\n"
)
```

### Local vs Prod DB Runs

Apps often need to run the same server against two DBs: local Docker for development, remote prod for debugging/one-off migrations. Split into two explicit targets; never let one be the ambient default.

```makefile
.PHONY: run-api-local run-api-prod

run-api-local: ## Run API against local DB (loads .env, --reload)
	@set -a && . ./.env && set +a && uv run uvicorn app.main:app --reload

run-api-prod: ## Run API against REMOTE prod DB (loads .env.prod)
	@if [ ! -f .env.prod ]; then \
		printf "$(RED)$(CROSS) .env.prod not found$(RESET)\n"; \
		printf "$(YELLOW)Create it locally with the prod DATABASE_URL (gitignored)$(RESET)\n"; \
		exit 1; \
	fi
	@printf "$(RED)$(BOLD)$(WARN)  LOCAL APP -> REMOTE PRODUCTION DB$(RESET)\n"
	@printf "$(YELLOW)Writes hit prod. Ctrl-C within 3s to abort.$(RESET)\n"
	@sleep 3
	@set -a && . ./.env.prod && set +a && uv run uvicorn app.main:app
```

**Rules:**
- `.env.prod` **MUST be gitignored** (production credentials). Add it to `.gitignore` before creating the file.
- Prod target: **no `--reload`** (code changes auto-reloading against prod is a footgun), visible red warning, 3-second sleep so it isn't silent when fired by reflex.
- Preflight: fail fast if `.env.prod` is missing rather than silently falling back to `.env`.
- Same pattern works for `run-worker-local`/`run-worker-prod`, `db-shell-prod` (connect local psql to remote), etc.

### FIX Variable for Check/Format Targets

Use a `FIX` variable to toggle between check-only and auto-fix modes:

```makefile
FIX ?= false

dev-check: ## Run linting and type checks (FIX=false: check only)
	$(call print_section,Running checks)
ifeq ($(FIX),true)
	uv run ruff check --fix src/ tests/
	uv run ruff format src/ tests/
else
	uv run ruff check src/ tests/
	uv run ruff format --check src/ tests/
endif
	uv run mypy src/
	$(call print_success,All checks passed)
```

In help output, show usage:

```makefile
@printf "$(CYAN)%-25s$(RESET) %s\n" "dev-check" "Run linting (FIX=false: check only)"
@printf "%-25s $(GREEN)make dev-check FIX=true$(RESET)  <- auto-fix issues\n" ""
```

### Per-Module Test Targets

For projects with multiple modules or platform adapters, create per-module test targets using tool-specific filtering:

```makefile
# Unit tests - filter by test file
.PHONY: test-unit-auth
test-unit-auth: ## Run auth module unit tests
	$(call print_section,Running auth unit tests)
	$(Q)$(NPM) exec vitest -- run tests/auth.test.js

# E2E tests - filter by grep pattern
.PHONY: test-e2e-checkout
test-e2e-checkout: ## Run checkout E2E tests
	$(call print_section,Running checkout E2E tests)
	$(Q)$(NPM) exec playwright -- test --grep "checkout"
```

**Key points:**
- Use `$(NPM) exec` (not bare `npx`) for consistency with the `$(NPM)` variable
- Unit tests filter by file path, E2E tests filter by `--grep` pattern
- Keep the generic `test-unit` and `test-e2e` targets for running everything
- Put per-module targets in `test.mk`, not `dev.mk`

## When to Modularize

**Default to modular** for any new Makefile with 5+ targets.

**Use flat file only when:**
- Simple scripts or single-purpose tools
- User explicitly requests it
- < 5 targets with no expected growth

Standard modular structure:
```
Makefile              # Config, imports, help, catch-all
makefiles/
  colors.mk          # ANSI colors & print helpers
  common.mk          # Shell flags, VERBOSE, guards
  <domain>.mk        # Actual targets (build.mk, dev.mk, etc.)
```

## Legacy Compatibility

**Default: NO legacy aliases.** Only add when:
- User explicitly requests backwards compatibility
- Existing CI/scripts depend on old names (verify with `rg "make old-name"`)

When legacy IS needed, put them in a clearly marked section AFTER main targets but BEFORE help:

```makefile
############################
### Legacy Target Aliases ##
############################

.PHONY: old-name
old-name: new_name ## (Legacy) Description
```

## Key Rules

- **Always read existing Makefile before changes**
- **Search codebase before renaming targets** (`rg "make old-target"`)
- **Test with `make help` and `make -n target`**
- **Update docs after Makefile changes** - When adding new targets:
  1. Add to `make help` output (in the appropriate section)
  2. Update `CLAUDE.md` if the project has one (document new targets)
  3. Update any other relevant docs (README.md, Agents.md, etc.)
- **Never add targets without clear purpose**
- **No line-specific references** - Avoid patterns like "Makefile:44" in docs/comments; use target names instead
- **Single source of truth** - Config vars defined once in root Makefile, not duplicated in modules
- **Root Makefile = help + imports + catch-all only** - Recipe bodies live in `makefiles/*.mk`. When a recipe leaks into the root file, other contributors copy that pattern and the modular structure drifts back to flat. If `setup`/`status`/whatever lives in root, move it to the most relevant module (e.g., `env.mk`).
- **Help coverage audit** - All targets with `##` must appear in either `make help` or `make help-unclassified`

## Help System

**ASCII box title with a project-branded emoji on the right.** The box anchors the top of `make help`; the right-side emoji gives the project a glanceable identity (leaf/herb for Grove, rocket for an SDK, lock for a security tool, etc.). Keep the emoji on the right — left-side placement crowds the title text.

```makefile
help:
	@printf "\n"
	@printf "$(BOLD)$(CYAN)╔══════════════════════════════════════════════╗$(RESET)\n"
	@printf "$(BOLD)$(CYAN)║$(RESET)  $(BOLD)Grove App — Makefile Targets$(RESET)            🌿  $(BOLD)$(CYAN)║$(RESET)\n"
	@printf "$(BOLD)$(CYAN)╚══════════════════════════════════════════════╝$(RESET)\n\n"
```

> ⚠️ **Emoji width gotcha.** Most emojis render as 2 terminal columns but count as 1 char in the printf string — so counting `═` against visible spaces won't match. Eyeball the rendered output and add/remove spaces before the emoji until the right `║` lines up with the corner of the box. Budget an extra pass for this.

**Categorized help with sections:**
```makefile
	@printf "$(BOLD)$(BLUE)=== 🏗️  Build ===$(RESET)\n\n"
	@grep -h -E '^build-[a-zA-Z_-]+:.*?## .*$$' ... | awk ...
	@printf "$(BOLD)$(BLUE)=== 🔧 Development ===$(RESET)\n\n"
	@grep -h -E '^dev-[a-zA-Z_-]+:.*?## .*$$' ... | awk ...
```

**Section header rules:**
- **Every section header gets a leading emoji.** Makes blocks scannable at a glance (🚀 Run, 🛠️ Dev, 🧹 Cleanup) and eye-trains the reader so they can skip directly to the section they want without parsing words. Use the emoji vocabulary table below for consistency across projects.
- **Use a distinct color for section headers** — not the same color as the title or target names. **Default to `$(BOLD)$(BLUE)`** when the title uses `$(BOLD)$(CYAN)` and target names are `$(CYAN)`. Avoid `$(BOLD)$(MAGENTA)` — reads as purple and clashes with most terminal themes. Good alternatives if blue isn't available: `$(BOLD)$(GREEN)` (if green isn't already heavily used for success messages) or `$(BOLD)$(YELLOW)` (conflicts less with "warning" context when help has no warnings). Bold-only with no color renders as plain terminal-default and gets lost on dense help output.
- **Trailing `\n\n`** — always put a blank line between the section header and the first target. Makes each block visually scannable; no blank line produces a wall of text.
- **Blank line between sections** — follow each section's last target with `@printf "\n"` before the next header.

**Emoji vocabulary for help sections** (pick from this list; reuse the same emoji for the same concept across projects so the visual language transfers):

| Section concept                          | Emoji | Notes                                           |
| ---------------------------------------- | ----- | ----------------------------------------------- |
| Quick Start / Getting started            | 🚀    | Primary entry point for new contributors        |
| Run / dev server / start service         | 🏃    | Short-running ergonomic entry points            |
| Build / compile / package                | 🏗️    | `dev-build`, artifact creation                  |
| Development / lint / format / typecheck  | 🛠️    | Quality gate targets                            |
| Tests                                    | 🧪    | `test`, `test-e2e`, coverage                    |
| Database                                 | 🗄️    | `db-start`, `db-migrate`, `db-reset`            |
| Environment / config                     | 🌐    | `env-setup`, `env-status`, `env-show`           |
| Secrets / auth / keys                    | 🔑    | `env-pull-*`, credential management             |
| Deploy / release                         | 🛫    | `deploy`, `release`, `publish`                  |
| Cleanup / reset                          | 🧹    | `clean-*` family                                |
| Help / reference                         | ❓    | `help`, `help-unclassified`                     |

Leave padding/alignment intact when substituting emojis — some (🛠️, 🗄️, 🏗️) include a variation selector that consumes an extra column in some terminals; add an extra space after them if alignment drifts.

**Quick Start is a 2-step instruction list, not a target list.** If the real entry point is a short sequence (`make env-setup && make run-prod`), print numbered instructions — do NOT list the same targets under both Quick Start and their "real" section (Environment Utilities, Run, etc.). Duplication doubles the help height and dilutes signal.

```makefile
# Good - numbered instructions, targets appear only in their real section
@printf "$(BOLD)$(MAGENTA)=== Quick Start ===$(RESET)\n\n"
@printf "  1. $(CYAN)make env-setup$(RESET)\n"
@printf "  2. $(CYAN)make run-mainnet$(RESET)\n\n"

# Bad - same targets repeated under "Quick Start" and "Environment Utilities"
@printf "$(BOLD)=== Quick Start ===$(RESET)\n"
@printf "$(CYAN)%-25s$(RESET) %s\n" "setup" "First-time setup"
@printf "$(CYAN)%-25s$(RESET) %s\n" "status" "Show environment"
...
@printf "$(BOLD)=== Environment Utilities ===$(RESET)\n"
@printf "$(CYAN)%-25s$(RESET) %s\n" "env-setup" "First-time setup"     # duplicate
```

**Key help patterns:**
- `help` - Main categorized help
- `help-unclassified` - Show targets not in any category (useful for auditing)
- `help-all` - Show everything including internal targets
- Hidden targets: prefix with `_` (e.g., `_build-internal`)
- Legacy targets: label with `## (Legacy)` and filter from main help

**Always include a Help section in `make help` output:**

```makefile
	@printf "$(BOLD)=== ❓ Help ===$(RESET)\n"
	@printf "$(CYAN)%-25s$(RESET) %s\n" "help" "Show this help"
	@printf "$(CYAN)%-25s$(RESET) %s\n" "help-unclassified" "Show targets not in categorized help"
	@printf "\n"
```

**help-unclassified pattern** (note the `sed` to strip filename prefix):

```makefile
help-unclassified: ## Show targets not in categorized help
	@printf "$(BOLD)Targets not in main help:$(RESET)\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		sed 's/^[^:]*://' | \
		grep -v -E '^(env-|dev-|clean|help)' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-25s$(RESET) %s\n", $$1, $$2}' || \
		printf "  (none)\n"
```

> 💡 Prefer **prefix-based exclusions** (`^(env-|dev-|db-|help|_|\.)`) over enumerating every single target name. A prefix regex stays correct as you add/rename targets; an enumerated list silently falls out of sync and becomes a maintenance burden.

**Description format - one line with example:**
```makefile
# Good - concise description + example on next line
@printf "$(CYAN)%-14s$(RESET) %s\n" "scrape" "Fetch posts into SQLite, detect problems"
@printf "               $(GREEN)make scrape SUBREDDITS=python,django LIMIT=10$(RESET)\n"
@printf "$(CYAN)%-14s$(RESET) %s\n" "dev-check" "Run ruff linter and formatter"
@printf "               $(GREEN)make dev-check FIX=true$(RESET)\n"

# Bad - too verbose, multi-line explanation
@printf "  $(CYAN)$(BOLD)setup$(RESET)\n"
@printf "      Install Python dependencies using uv. Run this once after cloning.\n"
@printf "      Creates .venv/ and installs packages from pyproject.toml.\n"
@printf "      $(GREEN)make setup$(RESET)\n"
```

**Help description rules:**
- **One line max** - Description must fit on single line unless user explicitly asks for more
- **Include what it affects** - e.g., "creates .venv", "exports to CSV", "deletes database"
- **Color inline paths/commands** - Use `$(GREEN)` for paths and commands within descriptions. Put color codes in the format string, not inside `%s` (printf `%s` treats ANSI as literals)
- **Example on next line** - Show realistic usage with parameters in `$(GREEN)`
- **Skip examples for simple targets** - If no parameters, no example needed

**Coloring inline values in descriptions:**

Two categories of inline value deserve consistent color treatment across every help description:

| Value type | Color | Examples |
|------------|-------|----------|
| File paths | `$(YELLOW)` | `.env.local`, `.next`, `node_modules`, `package-lock.json`, `dist/`, `~/.grove` |
| URLs and host:port | `$(YELLOW)` | `localhost:3000`, `api.grove.city`, `https://…` |
| Commands and examples | `$(GREEN)` | `make foo BAR=baz`, `npm run dev` |

Pick one color scheme across the whole Makefile and stick to it — a description that says "removes `.next`" in yellow in one line and green in another reads as accidental.

```makefile
# Good - color codes in format string, paths/URLs in YELLOW, commands in GREEN
@printf "$(CYAN)%-25s$(RESET) Remove $(YELLOW).next$(RESET) build directory\n" "clean-build"
@printf "$(CYAN)%-25s$(RESET) Testnet API + testnet chains ($(YELLOW)api.testnet.grove.city$(RESET))\n" "run-testnet"
@printf "$(CYAN)%-25s$(RESET) Clean + build, install to $(YELLOW)~/.grove$(RESET)\n" "install-prod"
@printf "%-25s $(GREEN)make foo ARG=val$(RESET)\n" ""

# Bad - color codes inside %s are printed as literals
@printf "$(CYAN)%-25s$(RESET) %s\n" "install-prod" "Install to $(YELLOW)~/.grove$(RESET)"
```

**URL-in-parens formula for `run-*` targets.** When a run target has a canonical destination (localhost port, API URL), append it in yellow parens at the end of the description. This is denser than a separate info line and matches how contributors actually scan help output.

```makefile
@printf "$(CYAN)%-25s$(RESET) Local API + testnet chains ($(YELLOW)localhost:8000$(RESET))\n" "run-local"
@printf "$(CYAN)%-25s$(RESET) Testnet API + testnet chains ($(YELLOW)api.testnet.grove.city$(RESET))\n" "run-testnet"
@printf "$(CYAN)%-25s$(RESET) Production API + mainnet chains ($(YELLOW)api.grove.city$(RESET))\n" "run-mainnet"
```

**Catch-all redirects to help:**
```makefile
%:
	@printf "$(RED)Unknown target '$@'$(RESET)\n"
	@$(MAKE) help
```

## Runtime Output for Long-Running Targets

Help output is one concern; *runtime output* from `run-*` / `dev-*` / `db-*` targets that activate config and then hand off to a long-running subprocess (`next dev`, `uvicorn`, `docker compose up`) is a second concern. Without structure, the output from "env activation → warning → config summary → subprocess banner → subprocess logs" interleaves into one undifferentiated wall of ℹ️ / ✓ / ⚠️ lines, and the developer has to read everything to find what matters. The patterns below break that into visually distinct phases.

### Phase Banners

Bracket each logical phase with a horizontal rule + emoji + title + horizontal rule. Add two small reusable macros to `colors.mk`:

```makefile
# Horizontal rule separator
define print_hr
	@printf "$(DIM)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"
endef

# Phase banner: horizontal rule + emoji + title + horizontal rule
# Usage: $(call print_phase,🔑,ENV → LOCAL + MAINNET)
define print_phase
	@printf "\n$(DIM)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"
	@printf "$(BOLD)$(CYAN) $(1)  $(2)$(RESET)\n"
	@printf "$(DIM)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n\n"
endef
```

**Suggested phase-emoji vocabulary** (use consistently across a project so the reader learns the shorthand):

| Phase | Emoji | Use when |
|-------|-------|----------|
| Env / setup / secrets | 🔑 | Activating `.env`, loading secrets, switching config |
| Config / URLs / network | 🌐 | Showing resolved config, API endpoints, RPC URLs |
| App / server / service starting | 🚀 | Right before handing off to `next dev` / `uvicorn` / etc. |
| Database | 🗄️ | `db-start`, `db-migrate`, `db-reset` |
| Build | 📦 | `build`, `dev-build`, packaging |
| Tests | 🧪 | Before `pytest` / `vitest` / `playwright` output |
| Deploy | 🛫 | Before `render deploy` / `fly deploy` / `vercel` |

### Critical-Action Warnings (Triple-Emoji Pattern)

For irreversible actions — real-money mainnet runs, production DB writes, force pushes, anything with "you probably can't undo this" — use a standalone triple-emoji line that sits between phases, not inside one. The triple flanking is visually louder than any single-line warning and the isolation ensures it isn't scanned past as ambient info.

```makefile
# In colors.mk
define print_mainnet_warning
	@printf "\n$(RED)$(BOLD)⚠️⚠️⚠️  MAINNET — REAL MONEY. DOUBLE-CHECK BEFORE TX.  ⚠️⚠️⚠️$(RESET)\n"
endef

define print_prod_db_warning
	@printf "\n$(RED)$(BOLD)⚠️⚠️⚠️  WRITES HIT PRODUCTION DATABASE — CTRL-C IN 3s TO ABORT  ⚠️⚠️⚠️$(RESET)\n"
endef
```

**Rules:**
- Reserve the triple-⚠️ pattern for genuinely irreversible / costly actions. If you use it on every soft warning, it loses all signal.
- Single ⚠️ (or 🟡) for soft warnings ("secrets file missing, OAuth won't work"); triple ⚠️⚠️⚠️ for hard ones ("real money", "prod DB", "about to overwrite remote").
- Always render in `$(RED)$(BOLD)` and on its own line with blank lines around it — a boxed or inlined version loses punch.

### "Subprocess Logs Below" Divider

Right before handing off to a long-running subprocess (`npm run dev`, `uvicorn`, `docker compose up`), print a muted divider line that names whose logs are about to appear. Tells the user the Makefile's own output has ended, and anything below is coming from a child process with its own formatting conventions.

```makefile
.PHONY: dev-run
dev-run:
	$(call print_phase,🚀,APP)
	# ... URLs, Ctrl+C hint, etc ...
	@printf "\n$(DIM)─────────── Next.js logs below ───────────$(RESET)\n\n"
	$(Q)npm run dev
```

Name the subprocess explicitly (`Next.js logs`, `uvicorn logs`, `Postgres logs`) — a generic "logs below" is less useful because the reader still has to guess whose formatting conventions to expect.

### Actionable-Control Hint Before Hand-Off

Print one line right before the subprocess divider that tells the user what their keyboard controls are and what to expect. Compact, one line, bold the key combo:

```makefile
@printf "\n$(CYAN)$(INFO) Auto-reload enabled · Press $(BOLD)Ctrl+C$(RESET)$(CYAN) to stop$(RESET)\n"
```

Bad alternative: a multi-line "Server running. Press Ctrl+C to stop. Changes auto-reload." block — same information, 3× the vertical space, no denser.

### Parsed Key-Value Grid Over Raw `grep` Dumps

For `env-show` / `status` / `db-info` / any target whose job is to show "the current state of things," parse the underlying file and print a compact key-value grid rather than dumping raw `KEY=value` lines from `grep`. The parsed version is scannable; the raw dump is a wall of `NEXT_PUBLIC_FOO=bar` prefixes that the eye has to filter.

```makefile
# Bad - raw grep dump, 3 subsections, 8 lines
env-show:
	@printf "\n$(BOLD)Configuration:$(RESET)\n"
	@grep "^NEXT_PUBLIC_ENV=" .env.local | sed 's/^/  /'
	@grep "^NEXT_PUBLIC_CHAIN_ENV=" .env.local | sed 's/^/  /'
	@printf "\n$(BOLD)API Endpoints:$(RESET)\n"
	@grep "NEXT_PUBLIC_.*_URL=" .env.local | sed 's/^/  /'
	@printf "\n$(BOLD)Services:$(RESET)\n"
	@grep "^NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=" .env.local | sed 's/^/  /'

# Good - parsed grid under a phase banner, 4 lines, aligned columns
env-show:
	$(call print_phase,🌐,CONFIG)
	@ENV=$$(grep "^NEXT_PUBLIC_ENV=" .env.local | cut -d= -f2); \
	 GROVE=$$(grep "^NEXT_PUBLIC_GROVE_API_BASE_URL=" .env.local | cut -d= -f2); \
	 BASE=$$(grep "^NEXT_PUBLIC_BASE_RPC_URL=" .env.local | cut -d= -f2 | sed 's|https://||'); \
	 SOL=$$(grep "^NEXT_PUBLIC_SOLANA_RPC_URL=" .env.local | cut -d= -f2 | sed 's|https://||'); \
	 printf "  $(BOLD)%-8s$(RESET) $(YELLOW)%s$(RESET)\n" "Env" "$$ENV"; \
	 printf "  $(BOLD)%-8s$(RESET) $(YELLOW)%s$(RESET)\n" "API" "$$GROVE"; \
	 printf "  $(BOLD)%-8s$(RESET) $(YELLOW)%s$(RESET) · $(YELLOW)%s$(RESET)\n" "RPC" "$$BASE" "$$SOL"
```

**Rules:**
- Fixed-width label column (`%-8s` / `%-10s`) so values align vertically.
- Values colored `$(YELLOW)` (same convention as help-description paths/URLs).
- Strip noise (e.g. `https://` prefixes on RPC URLs) when the protocol doesn't add information.
- Mask secrets (`WALLETCONNECT_SECRET=***hidden***`).
- If a value is missing or placeholder, print `$(RED)✗ not configured$(RESET)` — don't silently omit the row.

### Full-Flow Example

Applying all five patterns to a `run-mainnet` target produces:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 🔑  ENV → MAINNET
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✓  envs/mainnet.env + envs/.mainnet.secrets → .env.local

⚠️⚠️⚠️  MAINNET — REAL MONEY. DOUBLE-CHECK BEFORE TX.  ⚠️⚠️⚠️

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 🌐  CONFIG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Env      MAINNET (Base Mainnet · Solana Mainnet)
  API      https://api.grove.city
  RPC      mainnet.base.org · api.mainnet-beta.solana.com
  Wallet   WalletConnect a06ebd2a…

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 🚀  APP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 URLs:
   http://localhost:3000         (local)
   http://192.168.1.15:3000      (LAN / mobile — cross-network? make run-ngrok)

ℹ️ Auto-reload enabled · Press Ctrl+C to stop

─────────── Next.js logs below ───────────

▲ Next.js 16.2.1 (Turbopack) · Ready in 400ms
```

## Common Pitfalls

| Issue | Fix |
|-------|-----|
| `$var` in shell loops | Use `$$var` to escape for make |
| Catch-all `%:` shows error | Redirect to `@$(MAKE) help` instead |
| Config vars scattered | Put all `?=` overridable defaults at TOP of root Makefile |
| `HELP_PATTERNS` mismatch | Must match grep patterns in help target exactly |
| Duplicate defs in modules | Define once in root, reference in modules |
| Trailing whitespace in vars | Causes path splitting bugs - trim all variable definitions |
| `.PHONY` on file targets | Only use `.PHONY` for non-file targets |
| Too many public targets | Don't expose `install-X` or `check-X` - use internal `_check-X` dependencies |
| `$(DIM)` for usage text | Appears grey/unreadable - use `$(GREEN)` instead |
| Color codes inside `%s` | ANSI codes in `%s` args print as literals - put colors in format string |
| Section header same color as title/targets | Use a distinct color (default `$(BOLD)$(BLUE)` — avoid `$(MAGENTA)`/purple, clashes with most terminal themes) + `\n\n` after the header. `$(BOLD)` alone renders as terminal-default and gets lost. |
| Section headers have no emoji | Every section gets a leading emoji (🚀 Quick Start, 🏃 Run, 🛠️ Development, 🌐 Environment, 🧹 Cleanup, 🧪 Tests). Emojis give the reader a glanceable landmark so they can skip to the section they want without parsing words. See "Emoji vocabulary" table in the Help System section. |
| Title box has no project emoji | The `make help` title box should carry a project-branded emoji on the right (🌿 for Grove, 🚀 for SDKs, 🔒 for security tools, etc.). Right-side placement; left-side crowds the title. |
| Runtime output is a wall of ℹ️/⚠️/✓ with no structure | Wrap each logical phase (env activation, config summary, subprocess hand-off) in a `print_phase` banner — see §"Runtime Output for Long-Running Targets". |
| `env-show` / `status` dumps raw `KEY=value` grep output | Parse the values in shell and print a compact aligned key-value grid (`Env` / `API` / `RPC` / `Wallet`) — scannable instead of a wall of `NEXT_PUBLIC_FOO=bar`. |
| ⚠️ used on every warning, so no warning stands out | Reserve triple-`⚠️⚠️⚠️` `$(RED)$(BOLD)` for irreversible / costly actions (prod writes, real money, force push). Single `⚠️` for soft warnings. |
| Target named after tool | Name after the action: `remove-bg` not `rembg` |
| Too many granular `dev-*` quality targets | Collapse `dev-lint` + `dev-typecheck` + `dev-format` + `dev-check` into one `dev-format` (runs all three — prettier+eslint+tsc usually <5s for Node projects). Split only if CI parallelizes them. Same for `dev-test` + `dev-test-e2e` → one `test`. |
| `run-*-all` / "Full Stack" Cartesian section | Projects with a `docs/` sibling grow `run-testnet-all` / `run-mainnet-all` / `run-local-all` / `run-local-mainnet-all` that just background the docs site. These are almost never used — users open a second terminal. Keep one `run-docs` target in the "Run" section and drop the Cartesian matrix. |
| Quick Start repeats targets | If Quick Start lists `setup` and `status`, and Environment Utilities lists `setup` and `status` again, you're doubling help height. Make Quick Start a numbered instruction list (`1. make env-setup`, `2. make run-prod`) and let targets live once in their real section. |
| `help-unclassified` shows filename | Use `sed 's/^[^:]*://'` to strip `Makefile:` prefix |
| No `.env` export | Inline-source in the recipe: `@set -a && . ./.env && set +a && $(CMD)` (or `-include .env` for weaker cases — see Env File Loading) |
| Stale shell `DATABASE_URL` silently overrides `.env` | Use inline `set -a && . ./.env && set +a` in any recipe that depends on a specific `.env` value. `-include` alone loses to already-exported shell vars. |
| Secret committed to git | Add gitignored file (e.g. `.env.prod`), verify with `git check-ignore`, grep staged diff for a secret fragment before `git add`: `git diff --cached \| grep -c "$FRAGMENT"` |
| Single-service `docker-compose.yml` | For one Postgres container, a plain `docker run` in `db-start` is lighter than a compose file. Compose pays off only when you have 2+ services. |
| Dockerized Postgres on port 5432 clashes with host Homebrew Postgres | Default dev container to `PG_PORT ?= 5433` (and update `DATABASE_URL` accordingly). 5432 is nearly always claimed on macOS dev machines. |
| `pgcli` rejects `postgresql+psycopg://...` URL | pgcli doesn't understand SQLAlchemy dialect markers. Strip before use: `PGCLI_URL=$$(echo "$$DATABASE_URL" \| sed 's/+psycopg//') && pgcli "$$PGCLI_URL"`. |
| FastAPI `api-export-spec` hardcodes model import | The export script imports `app.main:app`. Parameterize via the `APP_MODULE` make variable if your entrypoint differs. |

## Cleanup Makefile Workflow

When user says "cleanup my makefiles":

**IMPORTANT: Build a plan first and explain it to the user before implementing anything.**

### Phase 1: Audit (no changes yet)

```bash
make help                    # See categorized targets
make help-unclassified       # Find orphaned targets
cat Makefile                 # Read structure
ls makefiles/*.mk 2>/dev/null # Check if modular
rg "make " --type md         # Find external dependencies
grep -E '\s+$' Makefile makefiles/*.mk  # Trailing whitespace
```

### Phase 2: Build & Present Plan

Create a checklist of proposed changes:

- [ ] **Structure** - Convert flat → modular (if 5+ targets) or vice versa
- [ ] **Legacy removal** - List specific targets to delete (with dependency check)
- [ ] **Duplicates** - List targets to consolidate
- [ ] **Renames** - List `old_name` → `new-name` changes
- [ ] **Description rewrites** - List vague descriptions to improve
- [ ] **Missing targets** - Suggest targets that should exist (e.g., `help-unclassified`)
- [ ] **Ordering fixes** - Config → imports → targets → help → catch-all

**Ask user to approve the plan before proceeding.**

### Phase 3: Implement (after approval)

1. **Restructure** (if needed) - Create `makefiles/` directory, split into modules
2. **Remove legacy** - Delete approved targets
3. **Consolidate duplicates** - Merge into single targets
4. **Rename targets** - Apply hyphen convention, add `_` prefix for internal
5. **Rewrite descriptions** - Make each `##` explain the purpose
6. **Fix formatting**
   - Usage examples in yellow: `$(YELLOW)make foo$(RESET)`
   - Remove trailing whitespace
   - `.PHONY` only on non-file targets
7. **Add missing pieces** - `help-unclassified`, catch-all `%:`, etc.

### Phase 4: Verify

```bash
make help          # Clean output?
make help-unclassified  # Should be empty or minimal
make -n <target>   # Dry-run key targets
```

### What NOT to do without asking:

- Rename targets that CI/scripts depend on
- Remove targets that look unused
- Change structure (flat ↔ modular) without approval

## Files in This Skill

- `reference.md` - Detailed patterns, categorized help, error handling
- `templates/` - Full copy-paste Makefiles for each stack
- `modules/` - Reusable pieces for complex projects

## Example: Adding a Target

User: "Add a target to run my tests"

```makefile
.PHONY: test
test: ## Run tests
	$(call print_section,Running tests)
	uv run pytest tests/ -v
	$(call print_success,Tests passed)
```

User: "Add database targets"

```makefile
.PHONY: db-start db-stop db-migrate

db-start: _check-docker ## Start database
	docker compose up -d postgres

db-stop: ## Stop database
	docker compose down

db-migrate: _check-postgres ## Run migrations
	uv run alembic upgrade head
```
