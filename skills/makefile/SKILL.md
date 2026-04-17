---
name: makefile
description: "Create or improve Makefiles with minimal complexity. Templates available: base, python-uv, python-fastapi, postgres, nodejs, go, chrome-extension, flutter, electron."
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

| Project Type | Template | Complexity |
|-------------|----------|------------|
| Any project | `templates/base.mk` | Minimal |
| Python with uv | `templates/python-uv.mk` | Standard |
| Python FastAPI | `templates/python-fastapi.mk` | Full-featured |
| PostgreSQL + Alembic | `templates/postgres.mk` | Standard |
| Node.js | `templates/nodejs.mk` | Standard |
| Go | `templates/go.mk` | Standard |
| Chrome Extension | `templates/chrome-extension.mk` | Modular |
| Flutter App | `templates/flutter.mk` | Modular |
| Electron App | `templates/electron.mk` | Modular |

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

### PostgreSQL + Alembic

Standalone template for database operations. Use alongside `python-fastapi.mk` for a full stack, or independently for any Python project with PostgreSQL.

Copy `templates/postgres.mk` to your project root (or `include` it from your main Makefile).

**Key features:**
- `db-start` / `db-stop` / `db-clean` Docker Compose lifecycle with health checks (swap to plain `docker run` for single-service setups — see reference.md)
- `db-init` composite target (start + migrate)
- `db-reset` safely kills active connections before DROP + recreate
- `db-migrate` / `db-revision` Alembic migrations via `uv run python -m alembic`; **all Alembic recipes inline-source `.env`** so a stale shell `DATABASE_URL` can't override the configured value
- `db-migration-current` / `db-migration-history` / `db-migration-check` introspection
- `db-shell` / `db-pgcli` / `db-pgweb` multiple shell access options
- `db-logs` / `db-seed` utilities
- All config via `?=` variables (POSTGRES_CONTAINER, DB_NAME, DB_USER, COMPOSE_FILE)
- **Driver**: template targets `psycopg[binary]>=3` (psycopg3). SQLAlchemy needs the `postgresql+psycopg://` dialect marker; add a pydantic-settings validator that normalizes `postgres://` / `postgresql://` → `postgresql+psycopg://` so Render's managed DB URL works verbatim.

## Interaction Pattern

1. **Understand** - What specific problem are we solving?
2. **Check existing** - Is there already a Makefile? Read it first!
3. **Default to modular** - For Chrome extensions and for 5+ targets, use modular structure unless user requests flat
4. **Match preferences** - Use python-fastapi.mk template style as default for rich help
5. **Explain structure** - If you choose flat/minimal, explain the reasoning
6. **Iterate** - Add complexity or simplify based on feedback

## Naming Conventions

Use **kebab-case** with consistent prefix-based grouping:

```makefile
# Good - consistent prefixes (hyphens, not underscores)
build-release, build-zip, build-clean    # Build tasks
dev-run, dev-test, dev-lint              # Development tasks
db-start, db-stop, db-migrate            # Database tasks
env-local, env-prod, env-show            # Environment tasks

# Internal targets - prefix with underscore to hide from help
_build-zip-internal, _prompt-version     # Not shown in make help

# Bad - inconsistent
run-dev, build, localEnv, test_net
build_release, dev_test                  # Underscores - don't use
```

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
- **Help coverage audit** - All targets with `##` must appear in either `make help` or `make help-unclassified`

## Help System

**ASCII box title for visibility:**
```makefile
help:
	@printf "\n"
	@printf "$(BOLD)$(CYAN)╔═══════════════════════════╗$(RESET)\n"
	@printf "$(BOLD)$(CYAN)║     Project Name          ║$(RESET)\n"
	@printf "$(BOLD)$(CYAN)╚═══════════════════════════╝$(RESET)\n\n"
```

**Categorized help with sections:**
```makefile
	@printf "$(BOLD)=== 🏗️  Build ===$(RESET)\n"
	@grep -h -E '^build-[a-zA-Z_-]+:.*?## .*$$' ... | awk ...
	@printf "$(BOLD)=== 🔧 Development ===$(RESET)\n"
	@grep -h -E '^dev-[a-zA-Z_-]+:.*?## .*$$' ... | awk ...
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

```makefile
# Good - color codes in format string, paths/commands highlighted
@printf "$(CYAN)%-25s$(RESET) Clean + build, install to $(GREEN)~/.grove$(RESET)\n" "install-prod"
@printf "$(CYAN)%-25s$(RESET) Build binary to $(GREEN)dist/$(RESET)\n" "dev-build"

# Bad - color codes inside %s are printed as literals
@printf "$(CYAN)%-25s$(RESET) %s\n" "install-prod" "Install to $(GREEN)~/.grove$(RESET)"
```

**Catch-all redirects to help:**
```makefile
%:
	@printf "$(RED)Unknown target '$@'$(RESET)\n"
	@$(MAKE) help
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
| Target named after tool | Name after the action: `remove-bg` not `rembg` |
| `help-unclassified` shows filename | Use `sed 's/^[^:]*://'` to strip `Makefile:` prefix |
| No `.env` export | Inline-source in the recipe: `@set -a && . ./.env && set +a && $(CMD)` (or `-include .env` for weaker cases — see Env File Loading) |
| Stale shell `DATABASE_URL` silently overrides `.env` | Use inline `set -a && . ./.env && set +a` in any recipe that depends on a specific `.env` value. `-include` alone loses to already-exported shell vars. |
| Secret committed to git | Add gitignored file (e.g. `.env.prod`), verify with `git check-ignore`, grep staged diff for a secret fragment before `git add`: `git diff --cached \| grep -c "$FRAGMENT"` |
| Single-service `docker-compose.yml` | For one Postgres container, a plain `docker run` in `db-start` is lighter than a compose file. Compose pays off only when you have 2+ services. |

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
