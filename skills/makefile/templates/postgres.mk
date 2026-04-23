# PostgreSQL + Alembic Makefile Template (using uv)
# Copy this file to your project root or include it from your main Makefile.
#
# Default layout: single local Postgres container via plain `docker run`.
# For multi-service setups, see the "Docker Compose alternative" block at
# the bottom of this file.
#
# Prerequisites:
#   - uv installed (https://github.com/astral-sh/uv)
#   - Docker (for PostgreSQL)
#   - pyproject.toml with alembic and psycopg[binary]>=3 (psycopg3, not psycopg2)
#   - `.template.env` committed + `.env` gitignored (see SKILL.md
#     "`.env` / `.template.env` bootstrap")
#
# SQLAlchemy dialect note:
#   SQLAlchemy needs the "postgresql+psycopg://" marker to pick psycopg3.
#   Render's fromDatabase.connectionString returns "postgresql://..." without
#   the marker — normalize it in a pydantic-settings validator (see
#   reference.md -> "Render Postgres URL Normalization").
#
# pgcli note:
#   pgcli does NOT understand the SQLAlchemy `+psycopg` dialect marker.
#   The `db-pgcli` recipe strips it before handing the URL off.

# ============================================================================
# Configuration (adjust these for your project)
# ============================================================================
PG_IMAGE        ?= postgres:16-alpine
PG_CONTAINER    ?= app_postgres_dev
PG_VOLUME       ?= app_postgres_data
PG_USER         ?= app
PG_PASSWORD     ?= $(PG_USER)
PG_DB           ?= app_dev
# 5433 avoids clashing with a host Homebrew Postgres on 5432. Override with
# `make db-start PG_PORT=5432` if your machine has no host Postgres.
PG_PORT         ?= 5433

# Raw Postgres URL for psql / pgcli / pgweb (no dialect marker).
DB_URL          ?= postgresql://$(PG_USER):$(PG_PASSWORD)@localhost:$(PG_PORT)/$(PG_DB)

# SQLAlchemy URL (psycopg3 dialect). Informational — your app reads `.env`.
SQLALCHEMY_URL  ?= postgresql+psycopg://$(PG_USER):$(PG_PASSWORD)@localhost:$(PG_PORT)/$(PG_DB)

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
.PHONY: _check-docker _check-postgres _check-env

_check-docker:
	@if ! docker info >/dev/null 2>&1; then \
		printf "$(RED)$(CROSS) Docker is not running$(RESET)\n"; \
		printf "$(YELLOW)$(INFO) Start Docker Desktop and retry$(RESET)\n"; \
		exit 1; \
	fi

_check-postgres:
	@if ! docker ps --filter "name=^$(PG_CONTAINER)$$" --filter "status=running" \
		--format "{{.Names}}" | grep -q "^$(PG_CONTAINER)$$"; then \
		printf "$(RED)$(CROSS) Postgres container '$(PG_CONTAINER)' is not running$(RESET)\n"; \
		printf "$(YELLOW)$(INFO) Run 'make db-start' first$(RESET)\n"; \
		exit 1; \
	fi

_check-env:
	@if [ ! -f .env ]; then \
		printf "$(RED)$(CROSS) .env not found$(RESET)\n"; \
		printf "$(YELLOW)$(INFO) Run 'make env-template' or 'cp .template.env .env'$(RESET)\n"; \
		exit 1; \
	fi

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
# Core Database Operations
# ============================================================================
.PHONY: db-start db-stop db-clean db-init db-reset

db-start: _check-docker ## Start Postgres container (creates or resumes)
	$(call print_section,Starting Postgres)
	@if docker ps --filter "name=^$(PG_CONTAINER)$$" --filter "status=running" --format "{{.Names}}" | grep -q "^$(PG_CONTAINER)$$"; then \
		printf "$(YELLOW)$(INFO) Postgres container already running$(RESET)\n"; \
	elif docker ps -a --filter "name=^$(PG_CONTAINER)$$" --format "{{.Names}}" | grep -q "^$(PG_CONTAINER)$$"; then \
		printf "$(YELLOW)$(INFO) Resuming existing Postgres container$(RESET)\n"; \
		docker start $(PG_CONTAINER) >/dev/null; \
	else \
		docker run -d \
			--name $(PG_CONTAINER) \
			-e POSTGRES_USER=$(PG_USER) \
			-e POSTGRES_PASSWORD=$(PG_PASSWORD) \
			-e POSTGRES_DB=$(PG_DB) \
			-e PGDATA=/var/lib/postgresql/data/pgdata \
			-p $(PG_PORT):5432 \
			-v $(PG_VOLUME):/var/lib/postgresql/data \
			--health-cmd "pg_isready -U $(PG_USER) -d $(PG_DB)" \
			--health-interval 10s \
			--health-timeout 5s \
			--health-retries 5 \
			--restart unless-stopped \
			$(PG_IMAGE) >/dev/null; \
	fi
	@echo "Waiting for Postgres to be ready..."
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		STATUS=$$(docker inspect --format='{{.State.Health.Status}}' $(PG_CONTAINER) 2>/dev/null || echo "not_found"); \
		if [ "$$STATUS" = "healthy" ]; then \
			printf "$(GREEN)$(BOLD)$(CHECK) Postgres ready on :$(PG_PORT)$(RESET)\n"; \
			exit 0; \
		fi; \
		echo "  status: $$STATUS (attempt $$i/10)"; \
		sleep 2; \
	done; \
	printf "$(RED)$(CROSS) Postgres did not become healthy$(RESET)\n"; \
	exit 1

db-stop: ## Stop Postgres container (preserves data volume)
	$(call print_info,Stopping Postgres)
	-docker stop $(PG_CONTAINER) >/dev/null

db-clean: ## Remove Postgres container AND data volume (destroys data)
	$(call print_warning,Removing Postgres container and volume)
	-docker rm -f $(PG_CONTAINER) >/dev/null
	-docker volume rm -f $(PG_VOLUME) >/dev/null
	$(call print_success,Postgres container and volume removed)

db-init: db-start db-migrate ## Start Postgres and apply migrations
	$(call print_success,Database initialized)

# HARD=false (default): kill connections -> DROP -> CREATE -> migrate. Fast,
#                        preserves container + volume. Enough for most schema
#                        drift.
# HARD=true:  `db-clean` then `db-init`. Use when the container/volume itself
#             is in a broken state (corrupt data, mismatched PG_IMAGE, etc.).
HARD ?= false

db-reset: _check-docker ## Reset database (HARD=true to nuke container+volume)
ifeq ($(HARD),true)
	$(MAKE) db-clean
	$(MAKE) db-init
	$(call print_success,Database HARD reset complete)
else
	$(MAKE) db-start
	$(call print_warning,Resetting database (soft: drop + recreate))
	-docker exec -i $(PG_CONTAINER) psql -U $(PG_USER) -d postgres \
		-c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$(PG_DB)' AND pid <> pg_backend_pid();" || true
	-docker exec -i $(PG_CONTAINER) psql -U $(PG_USER) -d postgres \
		-c "DROP DATABASE IF EXISTS $(PG_DB);" || true
	docker exec -i $(PG_CONTAINER) psql -U $(PG_USER) -d postgres \
		-c "CREATE DATABASE $(PG_DB);"
	$(MAKE) db-migrate
	$(call print_success,Database soft reset complete)
endif

# ============================================================================
# Migrations (Alembic)
# ============================================================================
.PHONY: db-migrate db-revision db-migration-current db-migration-history db-migration-check

# All Alembic recipes inline-source .env so a stale shell DATABASE_URL
# cannot override the local value (see SKILL.md -> "Env File Loading").
ENV_LOAD := set -a && . ./.env && set +a

db-migrate: _check-env _check-postgres ## Apply Alembic migrations
	$(call print_info,Running migrations)
	@$(ENV_LOAD) && uv run alembic upgrade head
	$(call print_success,Migrations complete)

db-revision: _check-env ## Create new migration (usage: make db-revision MSG="description")
	@$(ENV_LOAD) && uv run alembic revision --autogenerate -m "$(MSG)"

db-migration-current: _check-env ## Show current migration version
	$(call print_info,Current migration)
	@$(ENV_LOAD) && uv run alembic current --verbose

db-migration-history: _check-env ## Show migration history
	$(call print_info,Migration history)
	@$(ENV_LOAD) && uv run alembic history --verbose

db-migration-check: _check-env ## Check if database is in sync with models (detects schema drift)
	$(call print_info,Checking for schema drift)
	@$(ENV_LOAD) && uv run alembic check 2>&1 | grep -q "Target database is not up to date" && \
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
		docker exec -it $(PG_CONTAINER) psql -U $(PG_USER) -d $(PG_DB); \
	else \
		docker exec -i $(PG_CONTAINER) psql -U $(PG_USER) -d $(PG_DB); \
	fi

db-pgcli: _check-env _check-postgres ## Open pgcli shell (strips +psycopg dialect marker)
	@if ! command -v pgcli >/dev/null 2>&1; then \
		printf "$(RED)$(CROSS) pgcli is not installed$(RESET)\n"; \
		printf "$(YELLOW)Install: brew install pgcli$(RESET)\n"; \
		printf "$(YELLOW)Repo: https://github.com/dbcli/pgcli$(RESET)\n"; \
		exit 1; \
	fi
	@$(ENV_LOAD) && PGCLI_URL=$$(echo "$$DATABASE_URL" | sed 's/+psycopg//') && pgcli "$$PGCLI_URL"

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

db-logs: ## Show Postgres container logs
	@if ! docker ps -a --filter "name=^$(PG_CONTAINER)$$" --format "{{.Names}}" | grep -q "^$(PG_CONTAINER)$$"; then \
		printf "$(RED)$(CROSS) Postgres container does not exist$(RESET)\n"; \
		printf "$(YELLOW)Run 'make db-start' first$(RESET)\n"; \
		exit 1; \
	fi
	@docker logs -f $(PG_CONTAINER)

db-seed: _check-env _check-postgres ## Seed database with test data
	$(call print_info,Seeding database with test data)
	@$(ENV_LOAD) && uv run python scripts/seed_db.py
	$(call print_success,Database seeded)

# ============================================================================
# Docker Compose alternative
# ============================================================================
# If your project already has a multi-service docker-compose.yml, replace
# the `db-start` / `db-stop` / `db-clean` recipes above with:
#
#   DOCKER_COMPOSE ?= $(shell command -v docker-compose 2>/dev/null || echo "docker compose")
#   COMPOSE_FILE   ?= docker-compose.yml
#
#   db-start: _check-docker
#       @$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d postgres
#       # ... same health-check loop as above ...
#
#   db-stop:
#       @$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down
#
#   db-clean:
#       @$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down -v
#
# Compose only pays off with 2+ services. For a single Postgres container,
# the plain `docker run` block above is lighter.
