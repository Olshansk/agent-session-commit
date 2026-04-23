##########################
### Extension Build    ###
##########################

# Extension metadata - UPDATE THESE
EXTENSION_NAME := my-extension
CHROME_STORE_CONSOLE := https://chrome.google.com/webstore/devconsole

# Optional: GitHub releases repo (must be public for shareable URLs)
# RELEASES_REPO := your-org/your-releases

# Files to include in extension
INCLUDE_FILES := \
	manifest.json \
	background.js \
	popup.html \
	popup.css \
	popup.js \
	icons \
	src

# Files to exclude from zip
EXCLUDE_PATTERNS := \
	.git \
	.DS_Store \
	*.log \
	node_modules \
	makefiles \
	package*.json \
	Makefile \
	$(BUILD_DIR)

##########################
### Internal Targets   ###
##########################

# Internal target - prefixed with underscore to hide from help
.PHONY: _build-zip-internal
_build-zip-internal: dev-clean $(BUILD_DIR)
	@VERSION=$$(grep '"version"' manifest.json | sed 's/.*: "\([^"]*\)".*/\1/'); \
	GIT_SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo "local"); \
	VERSION_FULL="$$VERSION-$$GIT_SHA"; \
	ZIP_FILE="$(BUILD_DIR)/$(EXTENSION_NAME)-v$$VERSION_FULL.zip"; \
	printf "\n"; \
	printf "$(GREEN)╔════════════════════════════════════════════════════════╗$(RESET)\n"; \
	printf "$(GREEN)║  📦 Building $(EXTENSION_NAME) v$$VERSION_FULL$(RESET)\n"; \
	printf "$(GREEN)╚════════════════════════════════════════════════════════╝$(RESET)\n"; \
	printf "\n"; \
	$(call print_info,Preparing files...); \
	mkdir -p $(BUILD_DIR)/staging; \
	cp -r $(INCLUDE_FILES) $(BUILD_DIR)/staging/; \
	$(call print_info,Creating zip: $$ZIP_FILE); \
	cd $(BUILD_DIR)/staging && zip -rq ../$(EXTENSION_NAME)-v$$VERSION_FULL.zip .; \
	rm -rf $(BUILD_DIR)/staging; \
	$(call print_success,Extension packaged!); \
	printf "\n$(GREEN)$(BOLD)📦 Output:$(RESET) $(CYAN)$$ZIP_FILE$(RESET)\n\n"

# Internal target for version bump prompt
.PHONY: _build-version-prompt
_build-version-prompt:
	@CURRENT=$$(grep '"version"' manifest.json | sed 's/.*: "\([^"]*\)".*/\1/'); \
	MAJOR=$$(echo $$CURRENT | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT | cut -d. -f3); \
	BUILD=$$(echo $$CURRENT | cut -d. -f4); \
	V_MAJOR="$$((MAJOR + 1)).0.0"; \
	V_MINOR="$$MAJOR.$$((MINOR + 1)).0"; \
	V_PATCH="$$MAJOR.$$MINOR.$$((PATCH + 1))"; \
	if [ -n "$$BUILD" ]; then \
		V_BUILD="$$MAJOR.$$MINOR.$$PATCH.$$((BUILD + 1))"; \
	else \
		V_BUILD="$$MAJOR.$$MINOR.$$PATCH.1"; \
	fi; \
	printf "\n$(BOLD)Current version:$(RESET) $$CURRENT\n\n"; \
	printf "$(YELLOW)Version bump:$(RESET)\n"; \
	printf "  $(CYAN)[1]$(RESET) Major: $$CURRENT → $$V_MAJOR\n"; \
	printf "  $(CYAN)[2]$(RESET) Minor: $$CURRENT → $$V_MINOR\n"; \
	printf "  $(CYAN)[3]$(RESET) Patch: $$CURRENT → $$V_PATCH\n"; \
	printf "  $(CYAN)[4]$(RESET) Build: $$CURRENT → $$V_BUILD\n"; \
	printf "  $(CYAN)[s]$(RESET) Skip\n\n"; \
	printf "$(YELLOW)Choose [1/2/3/4/s]: $(RESET)"; \
	read choice; \
	case "$$choice" in \
		1) NEW=$$V_MAJOR ;; \
		2) NEW=$$V_MINOR ;; \
		3) NEW=$$V_PATCH ;; \
		4) NEW=$$V_BUILD ;; \
		s|S) printf "$(YELLOW)Skipping$(RESET)\n"; exit 0 ;; \
		*) printf "$(RED)Invalid$(RESET)\n"; exit 1 ;; \
	esac; \
	sed "s/\"version\": \"$$CURRENT\"/\"version\": \"$$NEW\"/" manifest.json > manifest.json.tmp && mv manifest.json.tmp manifest.json; \
	$(call print_success,Version bumped to $$NEW); \
	printf "\n$(YELLOW)Commit? [Y/n] $(RESET)"; \
	read ans; \
	if [ "$${ans:-Y}" != "n" ] && [ "$${ans:-Y}" != "N" ]; then \
		git add manifest.json && \
		git commit -m "chore: bump version to $$NEW" && \
		git push && \
		$(call print_success,Pushed!); \
	fi

##########################
### Public Targets     ###
##########################

.PHONY: build-release
build-release: _build-version-prompt _build-zip-internal ## Bump version and create zip for Chrome Web Store
	@printf "$(YELLOW)$(BOLD)Next steps:$(RESET)\n"
	@printf "  1. Go to $(CYAN)$(CHROME_STORE_CONSOLE)$(RESET)\n"
	@NEW_ZIP=$$(ls -t $(BUILD_DIR)/$(EXTENSION_NAME)-v*.zip 2>/dev/null | head -1); \
	printf "  2. Upload $(CYAN)$$NEW_ZIP$(RESET)\n"
	@printf "\n"

.PHONY: build-zip
build-zip: _build-zip-internal ## Create extension zip without version bump
	@printf "$(DIM)Tip: Use build-release for version bump + zip$(RESET)\n"

.PHONY: build-release-prepare
build-release-prepare: $(BUILD_DIR) ## Generate Chrome Web Store submission markdown (store listing + privacy + test instructions)
	@VERSION=$$(grep '"version"' manifest.json | sed 's/.*: "\([^"]*\)".*/\1/'); \
	NAME=$$(grep -m1 '"name"' manifest.json | sed 's/.*: "\([^"]*\)".*/\1/'); \
	DESCRIPTION=$$(grep -m1 '"description"' manifest.json | sed 's/.*: "\([^"]*\)".*/\1/'); \
	OUT="$(BUILD_DIR)/chrome-store-submission-v$$VERSION.md"; \
	if [ -f "$$OUT" ]; then \
		printf "$(YELLOW)$$OUT already exists. Overwrite? [y/N] $(RESET)"; \
		read ans; \
		if [ "$$ans" != "y" ] && [ "$$ans" != "Y" ]; then \
			printf "$(DIM)Aborted.$(RESET)\n"; exit 0; \
		fi; \
	fi; \
	PERMS=$$(node -e "const m=require('./manifest.json');(m.permissions||[]).forEach(p=>console.log('   - **'+p+'**: TODO justify (≤1000 chars)'))"); \
	HOSTS=$$(node -e "const m=require('./manifest.json');(m.host_permissions||[]).concat(m.optional_host_permissions||[]).forEach(h=>console.log('   - \`'+h+'\`'))"); \
	{ \
		printf '# %s — Chrome Web Store Submission v%s\n\n' "$$NAME" "$$VERSION"; \
		printf '> Fill in every `TODO` before submitting. Char limits: description ≤16000, single purpose ≤1000, each permission justification ≤1000.\n\n'; \
		printf '## Build\n\n'; \
		printf '### Store Listing\n\n'; \
		printf '1. **Description** (≤16000 chars)\n\n'; \
		printf '   Current manifest description: `%s`\n\n' "$$DESCRIPTION"; \
		printf '   TODO: expand with what the extension does, why users should install it, and key features.\n\n'; \
		printf '2. **Category**\n\n'; \
		printf '   TODO: pick one (e.g., Developer Tools, Productivity, Communication).\n\n'; \
		printf '3. **URLs**\n\n'; \
		printf '   - Homepage URL: TODO\n'; \
		printf '   - Support URL: TODO\n'; \
		printf '   - Privacy policy URL: TODO (required if any user data is collected)\n\n'; \
		printf '### Privacy\n\n'; \
		printf '1. **Single Purpose** (≤1000 chars)\n\n'; \
		printf '   TODO: describe the one narrow, easy-to-understand purpose of this extension.\n\n'; \
		printf '2. **Permission justification** (≤1000 chars each)\n\n'; \
		printf '%s\n\n' "$$PERMS"; \
		printf '   **Host permissions**:\n\n'; \
		printf '%s\n\n' "$$HOSTS"; \
		printf '   TODO justify host permissions (≤1000 chars).\n\n'; \
		printf '   **Remote code**: No, I am not using remote code.\n\n'; \
		printf '   **Data usage disclosures**: TODO tick applicable categories (PII, auth info, user activity, website content, etc.) and certify the 3 required disclosures.\n\n'; \
		printf '## Access\n\n'; \
		printf 'TODO: visibility (Public / Unlisted / Private), distribution regions, trusted tester emails or Google Group.\n\n'; \
		printf '## Test Instructions\n\n'; \
		printf 'TODO: step-by-step instructions for Chrome Web Store reviewers (test account, URL to visit, expected behavior, how to reach gated features).\n'; \
	} > "$$OUT"; \
	$(call print_success,Wrote $$OUT); \
	printf "\n$(YELLOW)$(BOLD)Next steps:$(RESET)\n"; \
	printf "  1. Fill in every TODO in $(CYAN)$$OUT$(RESET)\n"; \
	printf "  2. Paste sections into $(CYAN)$(CHROME_STORE_CONSOLE)$(RESET)\n\n"

# Uncomment if using GitHub releases
# .PHONY: build-beta
# build-beta: _build-version-prompt _build-zip-internal ## Upload beta release to GitHub
# 	@if ! command -v gh &> /dev/null; then \
# 		$(call print_error,Missing: gh CLI. Run: brew install gh); \
# 		exit 1; \
# 	fi
# 	@VERSION=$$(grep '"version"' manifest.json | sed 's/.*: "\([^"]*\)".*/\1/'); \
# 	TAG="$(EXTENSION_NAME)-v$$VERSION"; \
# 	ZIP=$$(ls -t $(BUILD_DIR)/$(EXTENSION_NAME)-v*.zip | head -1); \
# 	gh release create $$TAG $$ZIP --repo $(RELEASES_REPO) --title "v$$VERSION" --latest; \
# 	$(call print_success,Release created!)
