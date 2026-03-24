################################
### Electron Linting         ###
################################

#########################
### Public Targets    ###
#########################

.PHONY: electron-lint
electron-lint: _check-node ## Run ESLint and Prettier (FIX=true to auto-fix)
	$(call print_section,Running linters)
ifeq ($(FIX),true)
	$(Q)npx eslint . --fix
	$(Q)npx prettier --write .
else
	$(Q)npx eslint .
	$(Q)npx prettier --check .
endif
	$(call print_success,Linting complete)

.PHONY: electron-typecheck
electron-typecheck: _check-node ## Run TypeScript type checking
	$(call print_section,Type checking)
	$(Q)npx tsc --noEmit
	$(call print_success,Type checking complete)

.PHONY: electron-test
electron-test: _check-node ## Run tests
	$(call print_section,Running tests)
	$(Q)$(PKG_MANAGER) test
	$(call print_success,Tests complete)

.PHONY: electron-test-e2e
electron-test-e2e: _check-node ## Run end-to-end tests (Playwright/Spectron)
	$(call print_section,Running e2e tests)
	$(Q)$(PKG_MANAGER) run test:e2e
	$(call print_success,E2E tests complete)
