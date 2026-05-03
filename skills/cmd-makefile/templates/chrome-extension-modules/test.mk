####################
###   Testing    ###
####################

# --- Unit tests (Vitest) ---

.PHONY: test-unit
test-unit: ## Run all Vitest unit tests
	$(call print_section,Running unit tests)
	$(Q)$(NPM) run test

.PHONY: test-watch
test-watch: ## Run tests in watch mode
	$(call print_section,Running tests in watch mode)
	$(Q)$(NPM) run test:watch

.PHONY: test-coverage
test-coverage: ## Run tests with coverage
	$(call print_section,Running tests with coverage)
	$(Q)$(NPM) run test:coverage

# --- E2E tests (Playwright) ---

.PHONY: test-e2e
test-e2e: ## Run all Playwright E2E tests
	$(call print_section,Running E2E tests)
	$(Q)$(NPM) run test:e2e

# --- Per-module test targets ---
# Add platform/module-specific targets as needed:
#
# .PHONY: test-unit-mymodule
# test-unit-mymodule: ## Run MyModule unit tests
# 	$(call print_section,Running MyModule unit tests)
# 	$(Q)$(NPM) exec vitest -- run tests/mymodule.test.js
#
# .PHONY: test-e2e-mymodule
# test-e2e-mymodule: ## Run MyModule E2E tests
# 	$(call print_section,Running MyModule E2E tests)
# 	$(Q)$(NPM) exec playwright -- test --grep "mymodule"
