##########################
### Environment Setup  ###
##########################

.PHONY: env-install
env-install: ## Install npm dependencies
	$(call print_section,Installing npm dependencies)
	$(Q)$(NPM) install
	$(call print_success,Dependencies installed)

.PHONY: env-check
env-check: ## Check if npm is available
	$(call check_command,$(NPM))
	$(call print_success,npm is available)
