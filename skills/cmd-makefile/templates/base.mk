# Base Makefile Template
# Copy this file to your project root as 'Makefile'
# Customize the targets section for your project needs

.DEFAULT_GOAL := help

# ============================================================================
# Configuration
# ============================================================================
# Env loading: `-include .env` is convenient but LOSES to already-exported
# shell vars (e.g. `export DATABASE_URL=...` in ~/.zshrc wins silently).
# For any recipe that depends on a specific .env value, inline-source instead:
#   recipe:
#       @set -a && . ./.env && set +a && <command>
# Also ship a committed `.template.env` and a `make env-template` bootstrap
# that copies it to `.env` (see SKILL.md "`.env` / `.template.env` Bootstrap").
-include .env
.EXPORT_ALL_VARIABLES:

# ============================================================================
# Colors & Symbols
# ============================================================================
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
CYAN   := \033[0;36m
BLUE   := \033[0;34m
BOLD   := \033[1m
RESET  := \033[0m

CHECK := ✓
CROSS := ✗

# ============================================================================
# Your Targets Here
# ============================================================================
# Add your project-specific targets below
# Use the pattern: target: ## Description

.PHONY: setup run test clean

setup: ## First-time project setup
	@printf "$(CYAN)Setting up project...$(RESET)\n"
	# Add your setup commands here
	@printf "$(GREEN)$(CHECK) Setup complete$(RESET)\n"

run: ## Run the application
	@printf "$(CYAN)Starting application...$(RESET)\n"
	# Add your run command here

test: ## Run tests
	@printf "$(CYAN)Running tests...$(RESET)\n"
	# Add your test command here (e.g., pytest, npm test, go test)

clean: ## Clean generated files
	@printf "$(YELLOW)Cleaning...$(RESET)\n"
	# Add your clean commands here
	@printf "$(GREEN)$(CHECK) Cleaned$(RESET)\n"

# ============================================================================
# Help (keep near end, before catch-all)
# ============================================================================
.PHONY: help help-unclassified

help: ## Show available commands
	@printf "\n"
	@printf "$(BOLD)$(CYAN)╔══════════════════════════════════════════════╗$(RESET)\n"
	@printf "$(BOLD)$(CYAN)║$(RESET)  $(BOLD)Project Name — Makefile Targets$(RESET)        ✨  $(BOLD)$(CYAN)║$(RESET)\n"
	@printf "$(BOLD)$(CYAN)╚══════════════════════════════════════════════╝$(RESET)\n\n"
	@printf "$(BOLD)$(BLUE)=== 🚀 Quick Start ===$(RESET)\n\n"
	@printf "$(CYAN)%-25s$(RESET) %s\n" "setup" "First-time project setup"
	@printf "$(CYAN)%-25s$(RESET) %s\n" "run" "Run the application"
	@printf "\n"
	@printf "$(BOLD)$(BLUE)=== 🧪 Testing ===$(RESET)\n\n"
	@printf "$(CYAN)%-25s$(RESET) %s\n" "test" "Run tests"
	@printf "\n"
	@printf "$(BOLD)$(BLUE)=== 🧹 Maintenance ===$(RESET)\n\n"
	@printf "$(CYAN)%-25s$(RESET) %s\n" "clean" "Clean generated files"
	@printf "\n"
	@printf "$(BOLD)$(BLUE)=== ❓ Help ===$(RESET)\n\n"
	@printf "$(CYAN)%-25s$(RESET) %s\n" "help" "Show this help"
	@printf "$(CYAN)%-25s$(RESET) %s\n" "help-unclassified" "Show targets not in categorized help"
	@printf "\n"

help-unclassified: ## Show targets not in categorized help
	@printf "$(BOLD)Targets not in main help:$(RESET)\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		sed 's/^[^:]*://' | \
		grep -v -E '^(setup|run|test|clean|help)' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-25s$(RESET) %s\n", $$1, $$2}' || \
		printf "  (none)\n"

# ============================================================================
# Error Handling (keep at end)
# ============================================================================
%:
	@printf "$(RED)$(CROSS) Unknown target '$@'$(RESET)\n"
	@printf "   Run $(CYAN)make help$(RESET) to see available targets\n"
	@exit 1
