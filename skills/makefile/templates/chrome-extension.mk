# Chrome Extension Makefile Template
#
# Features:
#   - Modular structure (colors, common, build, dev, test, env)
#   - Version bumping with manifest.json sync
#   - GitHub releases workflow
#   - Vitest + Playwright testing
#
# Structure:
#   Makefile              # This file - help + includes
#   makefiles/
#     colors.mk           # ANSI colors & print helpers
#     common.mk           # Shell flags, guards, directories
#     build.mk            # Build & release targets
#     dev.mk              # Development targets
#     test.mk             # Unit tests, E2E tests, coverage
#     env.mk              # Environment setup, dependency checks

.DEFAULT_GOAL := help

# Patterns for categorized help (must match grep patterns exactly)
HELP_PATTERNS := \
	'^help' \
	'^build-' \
	'^dev-' \
	'^test-' \
	'^env-'

################
### Imports  ###
################

include ./makefiles/colors.mk
include ./makefiles/common.mk
include ./makefiles/build.mk
include ./makefiles/dev.mk
include ./makefiles/test.mk
include ./makefiles/env.mk

################
### Help     ###
################

.PHONY: help
help: ## Show all available targets with descriptions
	@printf "\n"
	@printf "$(BOLD)$(CYAN)📦 Extension Name - Makefile Targets$(RESET)\n"
	@printf "$(YELLOW)Usage:$(RESET) make <target>\n"
	@printf "\n"
	@printf "$(BOLD)=== 🏗️  Build & Package ===$(RESET)\n"
	@grep -h -E '^build-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) ./makefiles/*.mk 2>/dev/null | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-35s$(RESET) %s\n", $$1, $$2}' | sort -u
	@printf "\n"
	@printf "$(BOLD)=== 🔧 Development ===$(RESET)\n"
	@grep -h -E '^dev-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) ./makefiles/*.mk 2>/dev/null | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-35s$(RESET) %s\n", $$1, $$2}' | sort -u
	@printf "\n"
	@printf "$(BOLD)=== 🧪 Testing ===$(RESET)\n"
	@grep -h -E '^test-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) ./makefiles/*.mk 2>/dev/null | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-35s$(RESET) %s\n", $$1, $$2}' | sort -u
	@printf "\n"
	@printf "$(BOLD)=== 🌍 Environment ===$(RESET)\n"
	@grep -h -E '^env-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) ./makefiles/*.mk 2>/dev/null | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-35s$(RESET) %s\n", $$1, $$2}' | sort -u
	@printf "\n"
	@printf "$(BOLD)=== 📋 Help ===$(RESET)\n"
	@printf "$(CYAN)%-35s$(RESET) %s\n" "help" "Show this help message"
	@printf "$(CYAN)%-35s$(RESET) %s\n" "help-all" "Show all targets including internal"
	@printf "$(CYAN)%-35s$(RESET) %s\n" "help-unclassified" "Show targets not in categorized help"
	@printf "\n"

.PHONY: help-all
help-all: ## Show all targets including internal ones
	@printf "\n$(BOLD)$(CYAN)📦 All Targets$(RESET)\n\n"
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) ./makefiles/*.mk 2>/dev/null | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-35s$(RESET) %s\n", $$1, $$2}' | sort -u
	@printf "\n"

.PHONY: help-unclassified
help-unclassified: ## Show targets not in categorized help
	@printf "\n$(BOLD)$(CYAN)📦 Unclassified Targets$(RESET)\n\n"
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) ./makefiles/*.mk 2>/dev/null | sed 's/:.*//g' | sort -u > /tmp/all_targets.txt
	@( \
		for pattern in $(HELP_PATTERNS); do \
			grep -h -E "$${pattern}.*?## .*\$$" $(MAKEFILE_LIST) ./makefiles/*.mk 2>/dev/null || true; \
		done \
	) | sed 's/:.*//g' | sort -u > /tmp/classified_targets.txt
	@comm -23 /tmp/all_targets.txt /tmp/classified_targets.txt | while read target; do \
		grep -h -E "^$$target:.*?## .*\$$" $(MAKEFILE_LIST) ./makefiles/*.mk 2>/dev/null | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-30s$(RESET) %s\n", $$1, $$2}'; \
	done
	@rm -f /tmp/all_targets.txt /tmp/classified_targets.txt
	@printf "\n"

############################
### Legacy Target Aliases ##
############################

# Uncomment to maintain backwards compatibility when renaming targets:
# .PHONY: old-name
# old-name: new-name ## (Legacy) Old target name

###############################
###  Global Error Handling  ###
###############################

# Catch-all for undefined targets - MUST be at END after all includes
%:
	@printf "\n"
	@printf "$(RED)❌ Error: Unknown target '$(BOLD)$@$(RESET)$(RED)'$(RESET)\n"
	@printf "\n"
	@printf "$(YELLOW)💡 Run $(CYAN)make help$(RESET) $(YELLOW)to see available targets$(RESET)\n"
	@printf "\n"
	@exit 1
