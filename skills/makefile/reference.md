# Makefile Reference

Detailed patterns and conventions for creating maintainable Makefiles.

## Table of Contents

- [Python/uv Patterns](#pythonuv-patterns)
- [Preflight Checks](#preflight-checks)
- [External Tool Dependencies](#external-tool-dependencies)
- [Env File Loading](#env-file-loading)
- [Quickstart Targets](#quickstart-targets)
- [Argument Passing](#argument-passing)
- [Categorized Help Pattern](#categorized-help-pattern)
- [Naming Convention Details](#naming-convention-details)
- [Legacy Compatibility](#legacy-compatibility)
- [Global Error Handling](#global-error-handling)
- [Improving Existing Makefiles](#improving-existing-makefiles)
- [Common Refactoring Patterns](#common-refactoring-patterns)
- [PostgreSQL / Alembic Patterns](#postgresql--alembic-patterns)
- [Flutter Patterns](#flutter-patterns)

## Python/uv Patterns

### Always Use `uv run`

Run all Python commands through `uv run` to ensure the virtual environment is used:

```makefile
# Good - uses uv run
dev-format:
	uv run black .
	uv run isort .
	uv run flake8 .

dev-test:
	uv run pytest tests/ -v

# Bad - requires manual venv activation
dev-format:
	black .
	isort .
```

### Use `uv sync` for Dependencies

```makefile
env-install: ## Install dependencies
	uv sync  # Uses pyproject.toml + uv.lock

env-install-prod: ## Install production only
	uv sync --no-dev
```

### Check for uv

```makefile
env-install:
	@command -v uv >/dev/null 2>&1 || { printf "$(RED)Missing: uv$(RESET)\n"; exit 1; }
	uv sync
```

## Preflight Checks

Use `_check-*` targets as prerequisites:

```makefile
.PHONY: _check-docker _check-postgres

_check-docker:
	@if ! docker info >/dev/null 2>&1; then \
		printf "$(RED)❌ Docker is not running$(RESET)\n"; \
		printf "$(YELLOW)💡 Please start Docker Desktop$(RESET)\n"; \
		exit 1; \
	fi

_check-postgres:
	@if ! docker ps --filter "name=$(POSTGRES_CONTAINER)" --filter "status=running" \
		--format "{{.Names}}" | grep -q "$(POSTGRES_CONTAINER)"; then \
		printf "$(RED)❌ PostgreSQL not running$(RESET)\n"; \
		printf "$(YELLOW)💡 Start with: make db-start$(RESET)\n"; \
		exit 1; \
	fi

# Usage - check runs before target
db-start: _check-docker
	docker compose up -d postgres

db-migrate: _check-postgres
	uv run alembic upgrade head
```

## External Tool Dependencies

When a target requires an external CLI tool:

**Key principles:**
- Don't create public `install-X` or `check-X` targets
- Use internal `_check-X` as a dependency (no `##` = hidden from help)
- Show the install command on failure - don't auto-install
- Name target after the action, not the tool

```makefile
# Internal check - hidden from help (no ## comment)
_check-rembg:
	@command -v rembg >/dev/null 2>&1 || { \
		printf "$(RED)$(CROSS) rembg not installed$(RESET)\n"; \
		printf "$(YELLOW)Run: uv tool install \"rembg[cli]\"$(RESET)\n"; \
		exit 1; \
	}

# Public target - named after action, not tool
.PHONY: remove-bg
remove-bg: _check-rembg ## Remove background from image
	rembg i "$(IN)" "$(OUT)"
```

**What NOT to do:**

```makefile
# Bad - too many public targets
rembg:          ## Remove background      # Named after tool
rembg-install:  ## Install rembg          # Don't expose install
rembg-check:    ## Check if installed     # Don't expose check

# Good - minimal public surface
remove-bg: _check-rembg ## Remove background from image
```

## Env File Loading

Support multiple environment files:

```makefile
# Simple: Load from E2E_ENV or default to .env
test-e2e:
	@set -a && . "$${E2E_ENV:-.env}" && set +a && uv run pytest tests/e2e/

# Usage:
# make test-e2e                    # Uses .env
# E2E_ENV=.test.env make test-e2e  # Uses .test.env
```

### Reusable Macro

```makefile
define run_with_env
	@if [ -n "$$E2E_ENV" ]; then \
		printf "$(CYAN)$(INFO) Loading: $$E2E_ENV$(RESET)\n"; \
		if [ ! -f "$$E2E_ENV" ]; then \
			printf "$(RED)❌ File not found: $$E2E_ENV$(RESET)\n"; \
			exit 1; \
		fi; \
		set -a && . "$$E2E_ENV" && set +a; \
		$(1); \
	else \
		$(1); \
	fi
endef

# Usage
api-call:
	$(call run_with_env,uv run python scripts/call_api.py)
```

## Quickstart Targets

Interactive setup guides for onboarding:

```makefile
.PHONY: quickstart-dev
quickstart-dev: ## Interactive developer setup
	@printf "\n$(BOLD)$(GREEN)🚀 Developer Setup$(RESET)\n\n"
	@printf "$(BOLD)Step 1:$(RESET) Install dependencies\n"
	@printf "   $(CYAN)make env-install$(RESET)\n\n"
	@read -p "   Press Enter when ready..." dummy
	@$(MAKE) env-install
	@printf "\n$(GREEN)✓ Done$(RESET)\n\n"
	@printf "$(BOLD)Step 2:$(RESET) Start database\n"
	@printf "   $(CYAN)make db-start$(RESET)\n\n"
	@read -p "   Press Enter when ready..." dummy
	@$(MAKE) db-start
	@printf "\n$(GREEN)✓ Setup complete!$(RESET)\n"
```

## Argument Passing

Pass arguments to make targets:

```makefile
# Method 1: filter-out MAKECMDGOALS
api-fund: ## Fund account (usage: make api-fund 0.1)
	uv run python scripts/fund.py $(filter-out $@,$(MAKECMDGOALS))

# Method 2: Named variable
db-revision: ## Create migration (usage: make db-revision MSG="description")
	uv run alembic revision --autogenerate -m "$(MSG)"

# Catchall to ignore arguments (add at END of Makefile)
%:
	@TARGET="$@"; \
	if echo "$$TARGET" | grep -qE '^([0-9]+\.?[0-9]*|0x[a-fA-F0-9]+)$$'; then \
		: ; \
	else \
		printf "$(RED)❌ Unknown target '$$TARGET'$(RESET)\n"; \
		exit 1; \
	fi
```

## Categorized Help Pattern

For 10+ targets, organize help output by category:

```makefile
.PHONY: help
help: ## Show all available targets
	@printf "\n$(BOLD)$(CYAN)📋 Project - Makefile Targets$(RESET)\n\n"

	@printf "$(BOLD)=== 🚀 Quick Start ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "setup" "First-time setup"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "run" "Run the app"
	@printf "\n"

	@printf "$(BOLD)=== 💻 Development ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "dev-run" "Run dev server"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "dev-test" "Run tests"
	@printf "\n"

	@printf "$(BOLD)=== 🌍 Environment ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "env-local" "Setup local env"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "env-prod" "Setup prod env"
	@printf "\n"
```

### Usage Examples in Help

For targets with parameters, show usage on a second line in green:

```makefile
@printf "$(CYAN)%-40s$(RESET) %s\n" "remove-bg" "Remove background from image"
@printf "%-40s $(GREEN)make remove-bg IN=logo.png [OUT=logo_nobg.png]$(RESET)\n" ""
```

**Format rules:**
- Description on first line (cyan target name, white description)
- Usage on second line in `$(GREEN)` (avoid `$(DIM)` - appears grey/unreadable)
- Include full command with realistic example values
- Show optional params in brackets with sensible defaults

**Ordering principle:** Most-used commands first

1. Quick Start (setup, run)
2. Development (dev-*)
3. Testing (test-*)
4. Environment (env-*)
5. Database (db-*)
6. CI/CD (ci-*)
7. Cleaning (clean-*)

## Naming Convention Details

### Prefix Groups

| Prefix | Purpose | Examples |
|--------|---------|----------|
| `env-` | Environment management | `env-local`, `env-prod`, `env-show` |
| `dev-` | Development tasks | `dev-run`, `dev-build`, `dev-clean` |
| `db-` | Database operations | `db-start`, `db-stop`, `db-migrate` |
| `test-` | Testing | `test-unit`, `test-integration`, `test-e2e` |
| `ci-` | CI/CD operations | `ci-test`, `ci-deploy`, `ci-trigger` |
| `clean-` | Cleanup tasks | `clean-cache`, `clean-build`, `clean-all` |
| `docker-` | Container operations | `docker-build`, `docker-push`, `docker-run` |

### Why Prefixes Matter

- **Tab completion**: Type `make dev-<TAB>` to see all dev targets
- **Visual grouping**: Related targets appear together in help
- **Clear purpose**: Name alone explains what it does
- **No conflicts**: `dev-build` vs `docker-build` are distinct

### Bad Patterns to Avoid

```makefile
# Inconsistent prefixes
run-dev          # Should be dev-run
build            # Ambiguous - dev-build? docker-build?
clean-reinstall-dev  # Too long - just dev-clean

# Mixed naming styles
localEnv         # camelCase
test_net         # snake_case
prod-env         # kebab-case
# Pick ONE style (kebab-case recommended)

# Ambiguous names
start            # Start what?
stop             # Stop what?
run              # Run what?
# Better: db-start, server-stop, app-run

# Named after tool instead of action
rembg            # What does this do? (tool name)
prettier         # Is this running or configuring?
eslint           # Unclear purpose
# Better: remove-bg, format-code, lint-check
```

## Legacy Compatibility

When refactoring, maintain backward compatibility:

```makefile
############################
### Legacy Target Aliases ##
############################

# Old name -> new name (add deprecation notice)
.PHONY: old_target_name
old_target_name: new-target-name ## (Legacy) Use new-target-name instead

# Examples from real refactoring
.PHONY: uvx_install
uvx_install: env-install ## (Legacy) Use env-install

.PHONY: py_format
py_format: dev-format ## (Legacy) Use dev-format
```

**Process for renaming:**

1. Search all references: `rg "make old-name"` in docs, CI, scripts
2. Add alias pointing old -> new
3. Update documentation
4. Keep alias for at least one release cycle

## Global Error Handling

Add at the END of root Makefile (after all includes):

```makefile
###############################
###  Global Error Handling  ###
###############################

# Catch-all for undefined targets
%:
	@echo ""
	@echo "$(RED)❌ Error: Unknown target '$(BOLD)$@$(RESET)$(RED)'$(RESET)"
	@echo ""
	@echo "$(YELLOW)💡 Available targets:$(RESET)"
	@echo "   Run $(CYAN)make help$(RESET) to see all available targets"
	@echo ""
	@exit 1
```

**With context-specific hints:**

```makefile
%:
	@echo ""
	@echo "$(RED)❌ Error: Unknown target '$(BOLD)$@$(RESET)$(RED)'$(RESET)"
	@echo ""
	@if echo "$@" | grep -q "^db"; then \
		echo "$(YELLOW)💡 Database targets require Docker running$(RESET)"; \
		echo "   Run: $(CYAN)docker ps$(RESET) to verify"; \
	elif echo "$@" | grep -q "^python\|^py"; then \
		echo "$(YELLOW)💡 Python targets require virtual environment$(RESET)"; \
		echo "   Run: $(CYAN)source .venv/bin/activate$(RESET) first"; \
	else \
		echo "$(YELLOW)💡 Run $(CYAN)make help$(RESET) to see available targets"; \
	fi
	@echo ""
	@exit 1
```

## Improving Existing Makefiles

### Workflow

1. **Read first**: `cat Makefile` - understand current state
2. **Check modules**: `ls makefiles/*.mk 2>/dev/null`
3. **Analyze patterns**: What conventions exist?
4. **Search before renaming**: `rg "make target-name"`
5. **Propose targeted changes**: Don't rewrite everything
6. **Test**: `make help`, `make -n target`
7. **Update docs**: README, CI configs, developer docs

### Questions to Ask

- What's the pain point with the current Makefile?
- Are there targets that are rarely used?
- Are there missing targets people need?
- Is the help output helpful or overwhelming?

## Common Refactoring Patterns

### Consolidating Verbose Names

```makefile
# Before
dev-clean-reinstall-deps-and-cache:

# After
dev-clean:  ## Clean and reinstall (does all cleanup)
```

### Splitting Overloaded Targets

```makefile
# Before - does too much
deploy: test build push restart-servers update-dns notify-team

# After - split into stages
deploy: test build push
	@printf "$(GREEN)Ready. Run 'make deploy-live' to continue$(RESET)\n"

deploy-live: restart-servers update-dns notify-team
	@printf "$(GREEN)✓ Deployment complete$(RESET)\n"
```

### Adding Missing Help Descriptions

```makefile
# Before - no help
clean:
	rm -rf build/

# After - documented
clean: ## Remove build artifacts
	rm -rf build/
```

### Standardizing Output

```makefile
# Before - inconsistent
test:
	echo "Running tests..."
	pytest

# After - consistent colors
test: ## Run tests
	@printf "$(CYAN)Running tests...$(RESET)\n"
	pytest
	@printf "$(GREEN)✓ Tests passed$(RESET)\n"
```

## PostgreSQL / Alembic Patterns

### Kill Connections Before DROP

Always terminate active connections before dropping a database in `db-reset`. Without this, `DROP DATABASE` fails with "database is being accessed by other users":

```makefile
db-reset: db-start
	# Kill active connections first — prevents "database is being accessed" errors
	@docker exec -i $(POSTGRES_CONTAINER) psql -U $(DB_USER) -d postgres \
		-c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$(DB_NAME)' AND pid <> pg_backend_pid();" || true
	@docker exec -i $(POSTGRES_CONTAINER) psql -U $(DB_USER) -d postgres \
		-c "DROP DATABASE IF EXISTS $(DB_NAME);" || true
	@docker exec -i $(POSTGRES_CONTAINER) psql -U $(DB_USER) -d postgres \
		-c "CREATE DATABASE $(DB_NAME);"
	@$(MAKE) db-migrate
```

### Docker Health Status vs pg_isready

Prefer Docker's built-in health status over `pg_isready` for readiness checks. When your `docker-compose.yml` defines a healthcheck, `{{.State.Health.Status}}` reflects the full check (not just TCP connectivity):

```makefile
# Good — uses Docker health status (works with compose healthchecks)
@STATUS=$$(docker inspect --format='{{.State.Health.Status}}' $(POSTGRES_CONTAINER) 2>/dev/null); \
if [ "$$STATUS" = "healthy" ]; then ...

# Acceptable fallback — when no healthcheck is defined in compose
@docker exec $(POSTGRES_CONTAINER) pg_isready -U $(DB_USER) >/dev/null 2>&1
```

### Module Invocation for Alembic

Use `uv run python -m alembic` instead of `uv run alembic`. The module form avoids PATH resolution issues where `uv run` may not find the `alembic` entry point:

```makefile
# Good — module invocation, always works
uv run python -m alembic upgrade head
uv run python -m alembic revision --autogenerate -m "$(MSG)"

# Fragile — depends on entry point being on PATH
uv run alembic upgrade head
```

### Optional DB Shell Tools

Offer `db-pgcli` and `db-pgweb` as optional alternatives to `db-shell`. Show install hints on failure rather than auto-installing:

```makefile
db-pgcli: ## Open pgcli shell (modern psql with autocomplete)
	@if ! command -v pgcli >/dev/null 2>&1; then \
		printf "$(RED)$(CROSS) pgcli is not installed$(RESET)\n"; \
		printf "$(YELLOW)Install: brew install pgcli$(RESET)\n"; \
		exit 1; \
	fi
	@pgcli "$(DB_URL)"
```

## Flutter Patterns

### FLUTTER_DIR for Monorepo vs Standalone

Standalone Flutter projects default to `.` (the current directory). Monorepos override to point at the Flutter subdirectory:

```makefile
# Standalone project (default)
FLUTTER_DIR ?= .

# Monorepo — override in root Makefile
FLUTTER_DIR ?= flutter_app
```

All Flutter targets `cd` into `FLUTTER_DIR` before running commands, so this works transparently.

### Device Auto-Detection

**iOS Simulator — auto-boot + wait loop:**

The `flutter-run-ios` target opens Simulator.app, then polls `xcrun simctl list devices booted` until a booted simulator appears. This avoids hardcoding simulator names.

```makefile
@open -a Simulator
@SIMULATOR_NAME=$$(xcrun simctl list devices booted -j 2>/dev/null | python3 -c "..."); \
if [ -z "$$SIMULATOR_NAME" ]; then \
    # wait loop until booted ...
fi; \
cd $(FLUTTER_DIR) && flutter run -d "$$SIMULATOR_NAME"
```

**Android Emulator — auto-launch + wait loop:**

The `flutter-run-android` target finds the first available Android emulator, launches it, then polls `flutter devices --machine` until it appears.

**Physical Device — explicit or auto-detect:**

```makefile
# Explicit device ID
make flutter-run-device FLUTTER_IOS_DEVICE=00008150-001A29DC2200401C

# Auto-detect first connected physical device
make flutter-run-device
```

The auto-detect uses `flutter devices --machine` and filters out emulators.

### ExportOptions.plist for IPA Builds

The `flutter-build-ipa` target requires an `ExportOptions.plist` for App Store distribution. Default location:

```makefile
EXPORT_OPTIONS_PLIST ?= ios/ExportOptions.plist
```

This file configures signing, provisioning profile, and export method. Generate it by archiving once in Xcode, or create manually:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
```

### App Store Connect Credential Validation

The `_check-asc-credentials` internal target validates both `ASC_API_KEY` and `ASC_API_ISSUER` before attempting upload. Set them in your environment or pass inline:

```bash
# Environment variables
export ASC_API_KEY=YOUR_KEY_ID
export ASC_API_ISSUER=YOUR_ISSUER_ID
make flutter-deploy-testflight

# Or inline
ASC_API_KEY=YOUR_KEY_ID ASC_API_ISSUER=YOUR_ISSUER_ID make flutter-deploy-testflight
```

The API key `.p8` file must be at `~/.private_keys/AuthKey_<ASC_API_KEY>.p8`.

### Android Build Variants (APK vs AAB)

| Target | Format | Use Case |
|--------|--------|----------|
| `flutter-build-apk` | `.apk` | Debug/testing, direct device install |
| `flutter-build-aab` | `.aab` | Google Play Store upload (required for new apps) |

Both targets show file path and size after build completes.
