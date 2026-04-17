# PostgreSQL + Alembic Makefile Template (using uv)
# Copy this file to your project root or include it from your main Makefile.
#
# Standalone template for PostgreSQL database operations with Alembic migrations.
# Pair with python-fastapi.mk for a full FastAPI + Postgres setup.
#
# Prerequisites:
#   - uv installed (https://github.com/astral-sh/uv)
#   - Docker (for PostgreSQL)
#   - pyproject.toml with alembic and psycopg[binary]>=3 (psycopg3, not psycopg2)
#
# SQLAlchemy dialect note:
#   SQLAlchemy needs the "postgresql+psycopg://" marker to pick psycopg3.
#   Render's fromDatabase.connectionString returns "postgresql://..." without
#   the marker — normalize it in a pydantic-settings validator (see
#   reference.md -> "Render Postgres URL Normalization").

# ============================================================================
# Configuration (adjust these for your project)
# ============================================================================
POSTGRES_CONTAINER ?= postgres_dev
DB_NAME ?= app_dev
DB_USER ?= postgres
# Raw Postgres URL for psql / pgcli / pgweb (no dialect marker).
DB_URL ?= postgresql://$(DB_USER):$(DB_USER)@localhost:5432/$(DB_NAME)

# SQLAlchemy URL for Alembic and the app runtime (psycopg3 dialect).
# If your app normalizes the URL (recommended), the raw DB_URL in .env is fine
# and this variable is informational only.
SQLALCHEMY_URL ?= postgresql+psycopg://$(DB_USER):$(DB_USER)@localhost:5432/$(DB_NAME)

# Docker Compose (supports both old and new syntax)
DOCKER_COMPOSE ?= $(shell command -v docker-compose 2>/dev/null || echo "docker compose")
COMPOSE_FILE ?= docker-compose.yml

# ============================================================================
# Colors & Symbols (skip if already defined via colors.mk include)
# ============================================================================
GREEN   ?= \033[0;32m
YELLOW  ?= \033[1;33m
RED     ?= \033[0;31m
CYAN    ?= \033[0;36m
MAGENTA ?= \033[0;35m
BOLD    ?= \033[1m
DIM     ?= \033[2m
RESET   ?= \033[0m

CHECK ?= ✓
CROSS ?= ✗
WARN  ?= ⚠️
INFO  ?= ℹ️

# ============================================================================
# Print Helpers (skip if already defined via colors.mk include)
# ============================================================================
ifndef print_success
define print_success
	@printf "$(GREEN)$(BOLD) $(CHECK) %s$(RESET)\n" "$(1)"
endef
endif

ifndef print_warning
define print_warning
	@printf "$(YELLOW)$(WARN) %s$(RESET)\n" "$(1)"
endef
endif

ifndef print_info
define print_info
	@printf "$(CYAN)$(INFO) %s$(RESET)\n" "$(1)"
endef
endif

ifndef print_section
define print_section
	@printf "\n$(CYAN)$(BOLD)%s$(RESET)\n" "$(1)"
endef
endif

# ============================================================================
# Preflight Checks
# ============================================================================
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
		printf "$(RED)❌ PostgreSQL container '$(POSTGRES_CONTAINER)' is not running$(RESET)\n"; \
		printf "$(YELLOW)💡 Start with: make db-start$(RESET)\n"; \
		exit 1; \
	fi

# ============================================================================
# Core Database Operations
# ============================================================================
.PHONY: db-start db-stop db-clean db-init db-reset

db-start: _check-docker ## Start PostgreSQL via Docker Compose
	$(call print_section,Starting PostgreSQL)
	@if docker ps -a --filter "name=$(POSTGRES_CONTAINER)" --format "{{.Names}}" | grep -q "$(POSTGRES_CONTAINER)"; then \
		if docker ps --filter "name=$(POSTGRES_CONTAINER)" --filter "status=running" --format "{{.Names}}" | grep -q "$(POSTGRES_CONTAINER)"; then \
			printf "$(YELLOW)$(INFO) PostgreSQL container already running$(RESET)\n"; \
		else \
			printf "$(YELLOW)$(INFO) Starting existing PostgreSQL container$(RESET)\n"; \
			$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d postgres; \
		fi; \
	else \
		$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d postgres; \
	fi
	@echo "Waiting for PostgreSQL to be ready..."
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		STATUS=$$(docker inspect --format='{{.State.Health.Status}}' $(POSTGRES_CONTAINER) 2>/dev/null || echo "not_found"); \
		if [ "$$STATUS" = "healthy" ]; then \
			printf "$(GREEN)$(BOLD) $(CHECK) PostgreSQL started and ready$(RESET)\n"; \
			exit 0; \
		fi; \
		if [ $$i -lt 10 ]; then \
			echo "PostgreSQL not ready yet (status: $$STATUS), waiting... (attempt $$i/10)"; \
			sleep 2; \
		fi; \
	done; \
	printf "$(RED)$(BOLD) $(CROSS) PostgreSQL failed to become healthy after 10 attempts$(RESET)\n"; \
	printf "$(YELLOW)Container status: $$(docker inspect --format='{{.State.Health.Status}}' $(POSTGRES_CONTAINER) 2>/dev/null)$(RESET)\n"; \
	exit 1

db-stop: ## Stop PostgreSQL container
	$(call print_info,Stopping PostgreSQL)
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down

db-clean: ## Stop PostgreSQL and remove volumes
	$(call print_warning,Cleaning PostgreSQL container and volumes)
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down -v
	$(call print_success,PostgreSQL container and volumes removed)

db-init: db-start db-migrate ## Initialize database (start + migrate)
	$(call print_success,Database initialized)

db-reset: db-start ## Reset database (kill connections + drop + recreate + migrate)
	$(call print_warning,Resetting database)
	@docker exec -i $(POSTGRES_CONTAINER) psql -U $(DB_USER) -d postgres \
		-c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$(DB_NAME)' AND pid <> pg_backend_pid();" || true
	@docker exec -i $(POSTGRES_CONTAINER) psql -U $(DB_USER) -d postgres \
		-c "DROP DATABASE IF EXISTS $(DB_NAME);" || true
	@docker exec -i $(POSTGRES_CONTAINER) psql -U $(DB_USER) -d postgres \
		-c "CREATE DATABASE $(DB_NAME);"
	@$(MAKE) db-migrate
	$(call print_success,Database reset complete)

# ============================================================================
# Migrations (Alembic)
# ============================================================================
.PHONY: db-migrate db-revision db-migration-current db-migration-history db-migration-check

# All Alembic targets inline-source .env so a stale shell DATABASE_URL
# cannot override the local value (see SKILL.md -> "Env File Loading").
ENV_LOAD := if [ -f .env ]; then set -a && . ./.env && set +a; fi

db-migrate: _check-postgres ## Run database migrations
	$(call print_info,Running migrations)
	@$(ENV_LOAD); uv run python -m alembic upgrade head
	$(call print_success,Migrations complete)

db-revision: ## Create new migration (usage: make db-revision MSG="description")
	@$(ENV_LOAD); uv run python -m alembic revision --autogenerate -m "$(MSG)"

db-migration-current: ## Show current migration version
	$(call print_info,Current migration)
	@$(ENV_LOAD); uv run python -m alembic current --verbose

db-migration-history: ## Show migration history
	$(call print_info,Migration history)
	@$(ENV_LOAD); uv run python -m alembic history --verbose

db-migration-check: ## Check if database is in sync with models (detects schema drift)
	$(call print_info,Checking for schema drift)
	@$(ENV_LOAD); uv run python -m alembic check 2>&1 | grep -q "Target database is not up to date" && \
		(echo "❌ Database has pending migrations"; \
		 echo "   Run 'make db-migrate' to apply them"; \
		 exit 1) || \
		echo "✅ Database schema is in sync with models"

# ============================================================================
# Shell Access
# ============================================================================
.PHONY: db-shell db-pgcli db-pgweb

db-shell: _check-postgres ## Open psql shell
	@if [ -t 0 ]; then \
		docker exec -it $(POSTGRES_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME); \
	else \
		docker exec -i $(POSTGRES_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME); \
	fi

db-pgcli: ## Open pgcli shell (modern psql with autocomplete)
	@if ! command -v pgcli >/dev/null 2>&1; then \
		printf "$(RED)$(CROSS) pgcli is not installed$(RESET)\n"; \
		printf "$(YELLOW)Install: brew install pgcli$(RESET)\n"; \
		printf "$(YELLOW)Repo: https://github.com/dbcli/pgcli$(RESET)\n"; \
		exit 1; \
	fi
	@if ! docker ps --filter "name=$(POSTGRES_CONTAINER)" --filter "status=running" \
		--format "{{.Names}}" | grep -q "$(POSTGRES_CONTAINER)"; then \
		printf "$(RED)$(CROSS) PostgreSQL container is not running$(RESET)\n"; \
		printf "$(YELLOW)Run 'make db-start' first$(RESET)\n"; \
		exit 1; \
	fi
	@pgcli "$(DB_URL)"

db-pgweb: _check-postgres ## Start pgweb browser UI on :8081
	@if ! command -v pgweb >/dev/null 2>&1; then \
		printf "$(RED)$(CROSS) pgweb is not installed$(RESET)\n"; \
		printf "$(YELLOW)Install: brew install pgweb$(RESET)\n"; \
		printf "$(YELLOW)Repo: https://github.com/sosedoff/pgweb$(RESET)\n"; \
		exit 1; \
	fi
	@printf "$(GREEN)$(CHECK) Starting pgweb at http://localhost:8081$(RESET)\n"
	@pgweb --url "$(DB_URL)?sslmode=disable"

# ============================================================================
# Utilities
# ============================================================================
.PHONY: db-logs db-seed

db-logs: ## Show PostgreSQL container logs
	@if ! docker ps -a --filter "name=$(POSTGRES_CONTAINER)" --format "{{.Names}}" | grep -q "$(POSTGRES_CONTAINER)"; then \
		printf "$(RED)$(CROSS) PostgreSQL container does not exist$(RESET)\n"; \
		printf "$(YELLOW)Run 'make db-start' first$(RESET)\n"; \
		exit 1; \
	fi
	@docker logs -f $(POSTGRES_CONTAINER)

db-seed: ## Seed database with test data
	$(call print_info,Seeding database with test data)
	@uv run python scripts/seed_db.py
	$(call print_success,Database seeded)
