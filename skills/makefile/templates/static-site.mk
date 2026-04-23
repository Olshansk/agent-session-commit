# Static Site Makefile Template
# Copy this file to your project root as 'Makefile'
#
# Use case: plain HTML/CSS/JS landing pages, marketing sites, documentation
# sites, or anything served as static files (no bundler / SSR required).
#
# Assumptions:
#   - Site root is the repo root (override via SITE_DIR)
#   - index.html is the entrypoint
#   - No build step required by default; `dev-build` opts into minify

.DEFAULT_GOAL := help

# ============================================================================
# Configuration (override on the command line: `make site-serve PORT=9000`)
# ============================================================================
SITE_DIR    ?= .
PORT        ?= 8000
HOST        ?= 127.0.0.1
ENTRY       ?= index.html
BUILD_DIR   ?= dist

# Deploy target: rsync | gh-pages | netlify | vercel | none
DEPLOY_MODE ?= none
RSYNC_DEST  ?=

# ============================================================================
# Colors & Symbols
# ============================================================================
GREEN   := \033[0;32m
YELLOW  := \033[1;33m
RED     := \033[0;31m
CYAN    := \033[0;36m
BLUE    := \033[0;34m
BOLD    := \033[1m
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

define print_section
	@printf "\n$(CYAN)$(BOLD)%s$(RESET)\n" "$(1)"
endef

define check_command
	@command -v $(1) >/dev/null 2>&1 || { \
		printf "$(RED)$(CROSS) Missing tool: $(1)$(RESET)\n"; \
		[ -n "$(2)" ] && printf "$(YELLOW)Install: $(2)$(RESET)\n"; \
		exit 1; \
	}
endef

# ============================================================================
# Help
# ============================================================================
.PHONY: help help-unclassified

help: ## Show available commands
	@printf "\n"
	@printf "$(BOLD)$(CYAN)╔═══════════════════════════╗$(RESET)\n"
	@printf "$(BOLD)$(CYAN)║      Static Site        🌐 ║$(RESET)\n"
	@printf "$(BOLD)$(CYAN)╚═══════════════════════════╝$(RESET)\n\n"
	@printf "$(BOLD)$(BLUE)=== 🚀 Quick Start ===$(RESET)\n\n"
	@printf "$(CYAN)%-30s$(RESET) Serve site at $(YELLOW)http://$(HOST):$(PORT)$(RESET)\n" "site-serve"
	@printf "$(CYAN)%-30s$(RESET) Open $(YELLOW)$(ENTRY)$(RESET) in default browser\n" "site-open"
	@printf "$(CYAN)%-30s$(RESET) Show site info\n" "site-status"
	@printf "\n"
	@printf "$(BOLD)$(BLUE)=== 🛠️  Development ===$(RESET)\n\n"
	@printf "$(CYAN)%-30s$(RESET) All the formatting\n" "dev-format"
	@printf "$(CYAN)%-30s$(RESET) Show largest files in site\n" "dev-asset-report"
	@printf "$(CYAN)%-30s$(RESET) Copy + minify site into $(YELLOW)$(BUILD_DIR)/$(RESET)\n" "dev-build"
	@printf "$(CYAN)%-30s$(RESET) Deploy to configured target ($(YELLOW)DEPLOY_MODE=$(DEPLOY_MODE)$(RESET))\n" "dev-deploy"
	@printf "\n"
	@printf "$(BOLD)$(BLUE)=== 🧹 Maintenance ===$(RESET)\n\n"
	@printf "$(CYAN)%-30s$(RESET) Remove $(YELLOW)$(BUILD_DIR)/$(RESET)\n" "dev-clean"
	@printf "\n"
	@printf "$(BOLD)$(BLUE)=== ❓ Help ===$(RESET)\n\n"
	@printf "$(CYAN)%-30s$(RESET) Show this help\n" "help"
	@printf "$(CYAN)%-30s$(RESET) Show targets not in categorized help\n" "help-unclassified"
	@printf "\n"

help-unclassified: ## Show targets not in categorized help
	@printf "$(BOLD)Targets not in main help:$(RESET)\n"
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		grep -v -E '^(site-|dev-|help)' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-30s$(RESET) %s\n", $$1, $$2}' || \
		printf "  (none)\n"

# ============================================================================
# Site
# ============================================================================
.PHONY: site-serve site-open site-status

site-serve: ## Serve site at http://127.0.0.1:8000
	$(call print_section,Serving $(SITE_DIR) at http://$(HOST):$(PORT))
	@if command -v python3 >/dev/null 2>&1; then \
		cd "$(SITE_DIR)" && python3 -m http.server $(PORT) --bind $(HOST); \
	elif command -v npx >/dev/null 2>&1; then \
		npx --yes serve -l tcp://$(HOST):$(PORT) "$(SITE_DIR)"; \
	else \
		printf "$(RED)$(CROSS) Need python3 or npx to serve$(RESET)\n"; \
		exit 1; \
	fi

site-open: ## Open index.html in default browser
	@if command -v open >/dev/null 2>&1; then \
		open "$(SITE_DIR)/$(ENTRY)"; \
	elif command -v xdg-open >/dev/null 2>&1; then \
		xdg-open "$(SITE_DIR)/$(ENTRY)"; \
	else \
		printf "$(YELLOW)$(WARN) No 'open' or 'xdg-open' found$(RESET)\n"; \
		printf "Point your browser at: $(CYAN)file://$$(pwd)/$(SITE_DIR)/$(ENTRY)$(RESET)\n"; \
	fi

site-status: ## Show site info
	@printf "\n$(BOLD)$(CYAN)Site Status$(RESET)\n"
	@printf "$(BOLD)Directory:$(RESET)    $(SITE_DIR)\n"
	@printf "$(BOLD)Entry:$(RESET)        $(SITE_DIR)/$(ENTRY)\n"
	@printf "$(BOLD)Build dir:$(RESET)    $(BUILD_DIR)/\n"
	@printf "$(BOLD)Deploy mode:$(RESET)  $(DEPLOY_MODE)\n"
	@printf "\n$(BOLD)HTML pages:$(RESET)\n"
	@find "$(SITE_DIR)" -maxdepth 2 -name '*.html' -not -path '*/$(BUILD_DIR)/*' 2>/dev/null | sed 's/^/  /' || true
	@printf "\n$(BOLD)Tooling:$(RESET)\n"
	@command -v python3 >/dev/null 2>&1 && printf "  $(GREEN)$(CHECK) python3$(RESET)\n" || printf "  $(YELLOW)$(WARN) python3 (needed for site-serve)$(RESET)\n"
	@command -v npx >/dev/null 2>&1 && printf "  $(GREEN)$(CHECK) npx$(RESET)\n" || printf "  $(YELLOW)$(WARN) npx (needed for dev-format)$(RESET)\n"
	@printf "\n"

# ============================================================================
# Dev
# ============================================================================
.PHONY: dev-format dev-asset-report dev-build dev-deploy dev-clean

dev-format: ## All the formatting
	$(call print_section,Formatting code)
	$(call check_command,npx,install Node.js)
	@npx --yes prettier --write "$(SITE_DIR)/**/*.{html,css,js}" \
		--ignore-path .gitignore 2>/dev/null || \
	npx --yes prettier --write "$(SITE_DIR)/**/*.{html,css,js}"
	$(call print_success,Formatted)

dev-asset-report: ## Show largest files in site
	$(call print_section,Largest files in $(SITE_DIR))
	@find "$(SITE_DIR)" \
		-type f \
		-not -path '*/$(BUILD_DIR)/*' \
		-not -path '*/.git/*' \
		-not -path '*/node_modules/*' \
		-exec du -h {} + 2>/dev/null | sort -rh | head -20

dev-build: ## Copy + minify site into dist/
	$(call print_section,Building to $(BUILD_DIR)/)
	@rm -rf "$(BUILD_DIR)"
	@mkdir -p "$(BUILD_DIR)"
	@rsync -a \
		--exclude='$(BUILD_DIR)' \
		--exclude='.git' \
		--exclude='.github' \
		--exclude='node_modules' \
		--exclude='Makefile' \
		--exclude='.env*' \
		"$(SITE_DIR)/" "$(BUILD_DIR)/"
	@if command -v npx >/dev/null 2>&1; then \
		printf "$(CYAN)$(INFO) Minifying HTML...$(RESET)\n"; \
		find "$(BUILD_DIR)" -name '*.html' -print0 | xargs -0 -I{} \
			npx --yes html-minifier-terser \
				--collapse-whitespace \
				--remove-comments \
				--minify-css true \
				--minify-js true \
				-o {} {} 2>/dev/null || \
			printf "$(YELLOW)$(WARN) Minification skipped (install html-minifier-terser)$(RESET)\n"; \
	fi
	$(call print_success,Built $(BUILD_DIR)/)

dev-deploy: dev-build ## Deploy to configured target (DEPLOY_MODE=none)
	$(call print_section,Deploying via $(DEPLOY_MODE))
	@case "$(DEPLOY_MODE)" in \
		rsync) \
			if [ -z "$(RSYNC_DEST)" ]; then \
				printf "$(RED)$(CROSS) Set RSYNC_DEST=user@host:/path$(RESET)\n"; exit 1; \
			fi; \
			rsync -avz --delete "$(BUILD_DIR)/" "$(RSYNC_DEST)/"; \
			;; \
		gh-pages) \
			command -v npx >/dev/null 2>&1 || { printf "$(RED)$(CROSS) npx required$(RESET)\n"; exit 1; }; \
			npx --yes gh-pages -d "$(BUILD_DIR)"; \
			;; \
		netlify) \
			command -v netlify >/dev/null 2>&1 || { printf "$(RED)$(CROSS) install: npm i -g netlify-cli$(RESET)\n"; exit 1; }; \
			netlify deploy --prod --dir "$(BUILD_DIR)"; \
			;; \
		vercel) \
			command -v vercel >/dev/null 2>&1 || { printf "$(RED)$(CROSS) install: npm i -g vercel$(RESET)\n"; exit 1; }; \
			vercel --prod "$(BUILD_DIR)"; \
			;; \
		none|*) \
			printf "$(YELLOW)$(WARN) DEPLOY_MODE not set$(RESET)\n"; \
			printf "Use: $(CYAN)make dev-deploy DEPLOY_MODE=rsync RSYNC_DEST=user@host:/srv/www$(RESET)\n"; \
			exit 1; \
			;; \
	esac
	$(call print_success,Deployed)

dev-clean: ## Remove dist/
	$(call print_warning,Removing $(BUILD_DIR)/)
	@rm -rf "$(BUILD_DIR)"
	$(call print_success,Cleaned)

# ============================================================================
# Error Handling (keep at end)
# ============================================================================
%:
	@printf "$(RED)$(CROSS) Unknown target '$@'$(RESET)\n"
	@$(MAKE) help
