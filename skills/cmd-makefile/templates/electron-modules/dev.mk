################################
### Electron Development     ###
################################

#########################
### Internal Checks   ###
#########################

.PHONY: _check-node
_check-node:
	@command -v node >/dev/null 2>&1 || { \
		printf "$(RED)$(CROSS) Node.js not installed$(RESET)\n"; \
		printf "$(YELLOW)Install from: https://nodejs.org$(RESET)\n"; \
		exit 1; \
	}
	@command -v $(PKG_MANAGER) >/dev/null 2>&1 || { \
		printf "$(RED)$(CROSS) $(PKG_MANAGER) not installed$(RESET)\n"; \
		exit 1; \
	}

.PHONY: _check-deps
_check-deps:
	@[ -d node_modules ] || { \
		printf "$(RED)$(CROSS) Dependencies not installed$(RESET)\n"; \
		printf "$(YELLOW)Run: make electron-setup$(RESET)\n"; \
		exit 1; \
	}

#########################
### Public Targets    ###
#########################

.PHONY: electron-setup
electron-setup: _check-node ## Install dependencies
	$(call print_section,Setting up Electron project)
	$(Q)$(PKG_MANAGER) install
	$(call print_success,Electron setup complete)

.PHONY: electron-dev
electron-dev: _check-deps ## Start app in development mode with hot-reload
	$(call print_section,Starting Electron in dev mode)
	$(Q)$(PKG_MANAGER) run dev

.PHONY: electron-start
electron-start: _check-deps ## Start app without dev tooling
	$(call print_section,Starting Electron app)
	$(Q)$(PKG_MANAGER) run start

.PHONY: electron-debug
electron-debug: _check-deps ## Launch app with DevTools open
	$(call print_section,Launching with DevTools)
	$(Q)ELECTRON_OPEN_DEVTOOLS=1 $(ELECTRON_BIN) .

.PHONY: electron-clean
electron-clean: ## Clean everything (build artifacts, node_modules, lock file)
	$(call print_warning,Cleaning build artifacts and dependencies)
	$(Q)rm -rf dist out node_modules package-lock.json
	$(call print_success,All cleaned)
