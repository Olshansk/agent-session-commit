# Electron App Makefile Template
#
# Features:
#   - Modular structure (colors, common, dev, build, lint)
#   - Single `clean` target that removes everything
#   - Cross-platform builds (macOS DMG, Windows NSIS, Linux AppImage)
#   - Smoke-test with pack-check before distributing
#   - Dev mode with hot-reload and DevTools support
#   - ESLint + Prettier + TypeScript checking with FIX=true pattern
#   - Publish to GitHub Releases via electron-builder
#
# Structure:
#   Makefile                    # This file - config + help + includes
#   makefiles/
#     colors.mk                 # ANSI colors & print helpers
#     common.mk                 # Shell flags, VERBOSE mode, guards
#     dev.mk                    # Setup, dev server, debug, clean
#     build.mk                  # Pack-check, dist (mac/win/linux), publish
#     lint.mk                   # ESLint, Prettier, TypeScript, tests

.DEFAULT_GOAL := help

#########################
### Configuration     ###
#########################

# Package manager (npm, pnpm, or yarn)
PKG_MANAGER ?= npm

# Path to local electron binary
ELECTRON_BIN ?= ./node_modules/.bin/electron

# Linting
FIX ?= false

# Load .env if present
-include .env

# Export env vars to sub-processes
.EXPORT_ALL_VARIABLES:

# Help pattern matching (must match grep patterns in help target)
HELP_PATTERNS := \
	'^help' \
	'^electron-' \
	'^quickstart'

###############
### Imports ###
###############

include ./makefiles/colors.mk
include ./makefiles/common.mk
include ./makefiles/dev.mk
include ./makefiles/build.mk
include ./makefiles/lint.mk

##################
### Utilities  ###
##################

.PHONY: quickstart
quickstart: ## Show instructions to get started
	@printf "\n$(YELLOW)$(BOLD)Electron App Quickstart:$(RESET)\n"
	@printf "  $(MAGENTA)1.$(RESET) Run: $(GREEN)make electron-setup$(RESET)\n"
	@printf "  $(MAGENTA)2.$(RESET) Run: $(GREEN)make electron-dev$(RESET)\n"
	@printf "  $(MAGENTA)3.$(RESET) Run: $(GREEN)make electron-dist-mac$(RESET) (or dist-win, dist-linux)\n\n"

##############
### Help   ###
##############

.PHONY: help
help: ## Show all available targets
	@printf "\n"
	@printf "$(BOLD)$(CYAN)╔════════════════════════════════╗$(RESET)\n"
	@printf "$(BOLD)$(CYAN)║       Electron App             ║$(RESET)\n"
	@printf "$(BOLD)$(CYAN)╚════════════════════════════════╝$(RESET)\n\n"
	@printf "$(BOLD)=== 💻 Development ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-setup" "Install dependencies"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-dev" "Start app in dev mode with hot-reload"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-start" "Start app without dev tooling"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-debug" "Launch app with DevTools open"
	@printf "%-30s $(GREEN)ELECTRON_OPEN_DEVTOOLS=1$(RESET)\n" ""
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-clean" "Clean everything (artifacts, deps, lock file)"
	@printf "\n"
	@printf "$(BOLD)=== ⚡ Electron & Distribution ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-pack-check" "Verify Electron app loads without errors"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-dist-mac" "Build macOS .dmg installer"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-dist-win" "Build Windows .exe installer"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-dist-linux" "Build Linux AppImage + deb"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-dist-all" "Build for all platforms"
	@printf "\n"
	@printf "$(BOLD)=== 🚀 Publish ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-publish" "Build and publish release to GitHub"
	@printf "%-30s $(GREEN)GH_TOKEN=<token> make electron-publish$(RESET)\n" ""
	@printf "\n"
	@printf "$(BOLD)=== 🔍 Quality ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-lint" "Run ESLint and Prettier"
	@printf "%-30s $(GREEN)make electron-lint FIX=true$(RESET)\n" ""
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-typecheck" "Run TypeScript type checking"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-test" "Run tests"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "electron-test-e2e" "Run end-to-end tests"
	@printf "\n"
	@printf "$(BOLD)=== ❓ Help ===$(RESET)\n"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "help" "Show this help"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "help-unclassified" "Show targets not in categorized help"
	@printf "$(CYAN)%-30s$(RESET) %s\n" "quickstart" "Show instructions to get started"
	@printf "\n"

.PHONY: help-unclassified
help-unclassified: ## Show targets not in categorized help
	@printf "$(BOLD)Targets not in main help:$(RESET)\n"
	@result=$$(grep -h -E '^[a-zA-Z][a-zA-Z0-9-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		grep -v -E '^(electron-|help|quickstart)'); \
	if [ -z "$$result" ]; then \
		printf "  (none)\n"; \
	else \
		echo "$$result" | sed 's/^[^:]*://' | awk 'BEGIN {FS = ":.*?## "} {printf "$(CYAN)%-30s$(RESET) %s\n", $$1, $$2}'; \
	fi

################
### Catch-all ##
################

%:
	@if [ "$@" != "Makefile" ] && ! echo "$@" | grep -qE '^\.|^makefiles/'; then \
		printf "$(RED)Unknown target '$@'$(RESET)\n"; \
		$(MAKE) --no-print-directory help; \
	fi
