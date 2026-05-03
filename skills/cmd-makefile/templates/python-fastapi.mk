# FastAPI Makefile Template (using uv)
# Copy this file to your project root as 'Makefile'
#
# For database targets (PostgreSQL + Alembic), also copy templates/postgres.mk
# or include it: include postgres.mk
#
# For modular projects (5+ files), extract colors/helpers into:
#   makefiles/colors.mk and makefiles/common.mk
#
# Companion files (from templates/):
#   - python-fastapi-env/.template.env -> .template.env (committed)
#   - python-fastapi-scripts/export_openapi_spec.py -> scripts/export_openapi_spec.py
#
# Prerequisites:
#   - uv installed (https://github.com/astral-sh/uv)
#   - pyproject.toml with FastAPI, uvicorn
#   - `.template.env` at repo root; `.env` gitignored

.DEFAULT_GOAL := help

# ============================================================================
# Configuration (adjust these for your project)
# ============================================================================
APP_MODULE  ?= app.main:app
HOST        ?= 0.0.0.0
PORT        ?= 8000
# Health path — versioned APIs often live under /v1/health etc.
HEALTH_PATH ?= /health

# ============================================================================
# Test granularity
# ============================================================================
# This template ships BOTH patterns. Delete the one you don't want when
# scaffolding:
#
#   - Single target `dev-test`: best for small/medium projects. Runs all tests.
#   - Split `test-unit` / `test-integration` / `test-e2e`: best for larger
#     projects where unit tests are cheap and e2e hits real infra.
#
# If you keep the split pattern, ensure tests/ is laid out as:
#   tests/unit/  tests/integration/  tests/e2e/

# ============================================================================
# Colors & Symbols
# ============================================================================
GREEN   := \033[0;32m
YELLOW  := \033[1;33m
RED     := \033[0;31m
CYAN    := \033[0;36m
MAGENTA := \033[0;35m
BOLD    := \033[1m
DIM     := \033[2m
RESET   := \033[0m

CHECK := ✓
CROSS := ✗
WARN  := ⚠️
INFO  := ℹ️

# ============================================================================
# Print Helpers
# ============================================================================
define print_success
	@printf "$(GREEN)$(BOLD) $(CHECK) %s$(RESET)\n" "$(1)"
endef

define print_warning
	@printf "$(YELLOW)$(WARN) %s$(RESET)\n" "$(1)"
endef

define print_info
	@printf "$(CYAN)$(INFO) %s$(RESET)\n" "$(1)"
endef

define print_section
	@printf "\n$(CYAN)$(BOLD)%s$(RESET)\n" "$(1)"
endef

# ============================================================================
# Preflight
# ============================================================================
.PHONY: _check-env _check-env-prod

_check-env:
	@if [ ! -f .env ]; then \
		printf "$(RED)$(CROSS) .env not found$(RESET)\n"; \
		printf "$(YELLOW)$(INFO) Run 'make env-template' or 'cp .template.env .env'$(RESET)\n"; \
		exit 1; \
	fi

_check-env-prod:
	@if [ ! -f .env.prod ]; then \
		printf "$(RED)$(CROSS) .env.prod not found$(RESET)\n"; \
		printf "$(YELLOW)Create it locally with the prod DATABASE_URL (MUST be gitignored)$(RESET)\n"; \
		exit 1; \
	fi

# ============================================================================
# Help (manually organized for better UX)
# ============================================================================
.PHONY: help
help: ## Show all available targets
	@printf "\n$(BOLD)$(CYAN)📋 FastAPI Project$(RESET)\n\n"
	@printf "$(BOLD)=== 🚀 Quick Start ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "quickstart-dev" "Developer setup guide"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "env-template" "Create .env from .template.env"
	@printf "\n"
	@printf "$(BOLD)=== 🚀 API Operations ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "run-api-local" "Run API against local DB (.env, --reload)"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "run-api-prod" "Run API against REMOTE prod DB (.env.prod)"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "api-health" "Check API health endpoint ($(HEALTH_PATH))"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "api-export-spec" "Export OpenAPI spec to openapi.json"
	@printf "\n"
	@printf "$(BOLD)=== 🧪 Testing ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "dev-test" "Run all tests"
	@printf "$(DIM)%-30s$(RESET) (or use the split targets below)\n" ""
	@printf "$(CYAN)%-30s$(RESET) %s\n" "test-unit" "Run unit tests"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "test-integration" "Run integration tests (requires db)"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "test-e2e" "Run E2E tests (uses .env)"
	@printf "\n"
	@printf "$(BOLD)=== 🛠️  Development ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "dev-format" "Auto-fix and format code (ruff)"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "dev-check" "Run lint + tests"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "validate" "Alias for dev-check"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "dev-todo" "Find TODO/FIXME/HACK/NOTE comments"
	@printf "\n"
	@printf "$(BOLD)=== 🐍 Environment ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "env-install" "Install development dependencies"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "env-install-prod" "Install production dependencies (no dev)"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "env-sync" "Sync with lock file"
	@printf "\n"
	@printf "$(BOLD)=== 🧹 Cleaning ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "clean" "Clean cache files"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "clean-all" "Clean everything (cache + venv)"
	@printf "\n"

# ============================================================================
# Quick Start
# ============================================================================
.PHONY: quickstart-dev
quickstart-dev: ## Interactive developer setup guide
	@printf "\n$(BOLD)$(GREEN)🚀 Developer Quick Start$(RESET)\n\n"
	@printf "$(BOLD)Step 1:$(RESET) Install dependencies\n"
	@$(MAKE) env-install
	@printf "\n$(BOLD)Step 2:$(RESET) Create .env\n"
	@$(MAKE) env-template
	@printf "\n$(BOLD)Step 3:$(RESET) Start the API\n"
	@printf "   $(CYAN)make run-api-local$(RESET)\n\n"
	@printf "$(BOLD)$(GREEN)$(CHECK) Setup complete$(RESET)\n"
	@printf "   API docs: $(CYAN)http://localhost:$(PORT)/docs$(RESET)\n\n"

# ============================================================================
# Env bootstrap
# ============================================================================
.PHONY: env-template

env-template: ## Create .env from .template.env (safe: never overwrites)
	@if [ -f .env ]; then \
		printf "$(YELLOW)$(INFO) .env already exists — leaving it alone$(RESET)\n"; \
	elif [ ! -f .template.env ]; then \
		printf "$(RED)$(CROSS) .template.env not found$(RESET)\n"; \
		exit 1; \
	else \
		cp .template.env .env; \
		printf "$(GREEN)$(CHECK) Created .env from .template.env — fill in real values$(RESET)\n"; \
	fi

# ============================================================================
# Environment
# ============================================================================
.PHONY: env-install env-install-prod env-sync clean-env

env-install: ## Install development dependencies
	$(call print_section,Installing dependencies)
	@command -v uv >/dev/null 2>&1 || { printf "$(RED)Missing: uv$(RESET)\n"; exit 1; }
	uv sync
	$(call print_success,Dependencies installed)

env-install-prod: ## Install production dependencies (no dev)
	$(call print_section,Installing production dependencies)
	@command -v uv >/dev/null 2>&1 || { printf "$(RED)Missing: uv$(RESET)\n"; exit 1; }
	uv sync --no-dev
	$(call print_success,Production dependencies installed)

env-sync: ## Sync dependencies with lock file
	$(call print_section,Syncing dependencies)
	uv sync
	$(call print_success,Dependencies synced)

clean-env: ## Remove virtual environment
	$(call print_warning,Removing virtual environment)
	rm -rf .venv venv
	$(call print_success,Virtual environment removed)

# ============================================================================
# API Server
# ============================================================================
.PHONY: run-api-local run-api-prod api-health api-export-spec

run-api-local: _check-env ## Run API against local DB (.env, --reload)
	$(call print_section,Starting API (local))
	@printf "$(BOLD)Endpoints:$(RESET) $(CYAN)http://localhost:$(PORT)$(RESET)\n"
	@printf "$(BOLD)Docs:$(RESET)      $(CYAN)http://localhost:$(PORT)/docs$(RESET)\n"
	@set -a && . ./.env && set +a && uv run uvicorn $(APP_MODULE) --host $(HOST) --port $(PORT) --reload

run-api-prod: _check-env-prod ## Run API against REMOTE prod DB (.env.prod, no reload)
	@printf "$(RED)$(BOLD)$(WARN)  LOCAL UVICORN -> REMOTE PRODUCTION DB$(RESET)\n"
	@printf "$(YELLOW)Writes hit PRODUCTION. Ctrl-C within 3s to abort.$(RESET)\n"
	@sleep 3
	$(call print_section,Starting API (prod DB))
	@printf "$(BOLD)Endpoints:$(RESET) $(CYAN)http://localhost:$(PORT)$(RESET)\n"
	@set -a && . ./.env.prod && set +a && uv run uvicorn $(APP_MODULE) --host $(HOST) --port $(PORT)

api-health: ## Check API health endpoint (override with HEALTH_PATH=/v1/health)
	$(call print_info,Checking API health at $(HEALTH_PATH))
	@curl -s http://localhost:$(PORT)$(HEALTH_PATH)
	@printf "\n"

api-export-spec: ## Export OpenAPI spec to openapi.json
	$(call print_section,Exporting OpenAPI spec)
	uv run python scripts/export_openapi_spec.py
	$(call print_success,OpenAPI spec written to openapi.json)

# ============================================================================
# Testing
# ============================================================================
.PHONY: dev-test test-unit test-integration test-e2e

# --- Single-target pattern (small/medium projects) --------------------------
dev-test: ## Run all tests
	$(call print_section,Running tests)
	uv run pytest
	$(call print_success,Tests passed)

# --- Split pattern (larger projects) ---------------------------------------
test-unit: ## Run unit tests
	$(call print_section,Running unit tests)
	uv run pytest tests/unit/ -v
	$(call print_success,Unit tests passed)

test-integration: ## Run integration tests (requires db)
	$(call print_section,Running integration tests)
	@printf "$(YELLOW)$(WARN) Requires Postgres (make db-start)$(RESET)\n"
	uv run pytest tests/integration/ -v
	$(call print_success,Integration tests passed)

test-e2e: _check-env ## Run E2E tests (sources .env)
	$(call print_section,Running E2E tests)
	@printf "$(YELLOW)$(WARN) This may use real resources$(RESET)\n"
	@set -a && . ./.env && set +a && uv run pytest tests/e2e/ -v
	$(call print_success,E2E tests passed)

# ============================================================================
# Development
# ============================================================================
.PHONY: dev-format dev-check validate dev-todo

dev-format: ## Auto-fix and format code (ruff)
	$(call print_section,Formatting code)
	uv run ruff check --fix .
	uv run ruff format .
	$(call print_success,Formatting complete)

dev-check: ## Run ruff check + pytest
	$(call print_section,Running checks)
	uv run ruff check .
	uv run ruff format --check .
	uv run pytest
	$(call print_success,All checks passed)

validate: dev-check ## Alias for dev-check
	@:

dev-todo: ## Find TODO/FIXME/HACK/NOTE comments
	$(call print_section,Searching for TODOs)
	@grep -rn --color=always \
		--exclude-dir={.venv,__pycache__,.pytest_cache,.mypy_cache,.git} \
		--exclude={"*.pyc","uv.lock"} \
		-E "(TODO|FIXME|XXX|HACK|NOTE):" . || printf "$(GREEN)No TODOs found!$(RESET)\n"

# ============================================================================
# Cleaning
# ============================================================================
.PHONY: clean clean-all

clean: ## Clean cache files
	$(call print_warning,Cleaning cache)
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	$(call print_success,Cleaned)

clean-all: clean clean-env ## Clean everything (cache + venv)
	$(call print_success,All cleanup complete)

# ============================================================================
# Error Handling (keep at end)
# ============================================================================
%:
	@TARGET="$@"; \
	if echo "$$TARGET" | grep -qE '^(https?://\S+|0x[a-fA-F0-9]{40}|[0-9]+\.?[0-9]*|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?|[A-Z]{2,10}|[a-z]+([-][a-z]+)*)$$'; then \
		: ; \
	else \
		printf "\n$(RED)$(CROSS) Unknown target '$$TARGET'$(RESET)\n"; \
		printf "   Run $(CYAN)make help$(RESET) to see available targets\n\n"; \
		exit 1; \
	fi
