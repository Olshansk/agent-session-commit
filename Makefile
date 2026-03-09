########################
### Makefile Helpers ###
########################

BOLD := \033[1m
CYAN := \033[36m
RESET := \033[0m

REPO_SKILLS := $(CURDIR)/skills
REPO_AGENTS := $(CURDIR)/agents
SHARE_TARGETS := $(HOME)/.gemini/antigravity/skills $(HOME)/.codex/skills

.PHONY: help
.DEFAULT_GOAL := help
help: ## Prints all the targets in the Makefile
	@echo ""
	@echo "$(BOLD)$(CYAN)Agent Skills Repository$(RESET)"
	@echo ""
	@echo "$(BOLD)=== Skills ===$(RESET)"
	@grep -h -E '^(link|list|publish).*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-40s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)=== Backup ===$(RESET)"
	@grep -h -E '^sync.*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-40s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)=== Testing ===$(RESET)"
	@grep -h -E '^stress.*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-40s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)=== Info ===$(RESET)"
	@grep -h -E '^(help|status|test).*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-40s$(RESET) %s\n", $$1, $$2}'
	@echo ""

########################
### Skills           ###
########################

ALL_TARGETS := $(HOME)/.claude/skills $(SHARE_TARGETS)

.PHONY: link-skills
link-skills: ## Symlink repo skills into Claude, Gemini, and Codex
	@for target_dir in $(ALL_TARGETS); do \
		mkdir -p "$$target_dir"; \
		echo "=== $$target_dir ==="; \
		for skill in $(REPO_SKILLS)/*/; do \
			name=$$(basename "$$skill"); \
			link="$$target_dir/$$name"; \
			if [ -L "$$link" ]; then \
				current=$$(readlink "$$link"); \
				if [ "$$current" != "$$skill" ]; then \
					rm "$$link"; \
					ln -s "$$skill" "$$link"; \
					echo "  ~ $$name (repointed)"; \
				fi; \
			elif [ -d "$$link" ]; then \
				rm -rf "$$link"; \
				ln -s "$$skill" "$$link"; \
				echo "  ~ $$name (replaced real dir)"; \
			else \
				ln -s "$$skill" "$$link"; \
				echo "  + $$name"; \
			fi; \
		done; \
		for link in "$$target_dir"/*; do \
			[ -L "$$link" ] || continue; \
			readlink "$$link" | grep -q "$(REPO_SKILLS)" || continue; \
			[ -e "$$link" ] || { echo "  - $$(basename $$link) (stale)"; rm -f "$$link"; }; \
		done; \
	done
	@echo ""
	@echo "=== Agent instructions ==="
	@for pair in "$(HOME)/.claude/CLAUDE.md:$(REPO_AGENTS)/AGENTS.md" \
	             "$(HOME)/.codex/AGENTS.md:$(REPO_AGENTS)/AGENTS.md" \
	             "$(HOME)/.gemini/GEMINI.md:$(REPO_AGENTS)/MEMORIES.md"; do \
		link="$${pair%%:*}"; \
		target="$${pair##*:}"; \
		dir=$$(dirname "$$link"); \
		mkdir -p "$$dir"; \
		if [ -L "$$link" ]; then \
			current=$$(readlink "$$link"); \
			if [ "$$current" != "$$target" ]; then \
				rm "$$link"; \
				ln -s "$$target" "$$link"; \
				echo "  ~ $$(basename $$link) → $$target (repointed)"; \
			else \
				echo "  ✓ $$(basename $$link) (ok)"; \
			fi; \
		else \
			[ -f "$$link" ] && rm "$$link"; \
			ln -s "$$target" "$$link"; \
			echo "  + $$(basename $$link) → $$target"; \
		fi; \
	done
	@echo "Done"

.PHONY: list-skills
list-skills: ## List all skills with descriptions
	@echo ""
	@echo "$(BOLD)$(CYAN)Published Skills$(RESET)"
	@echo ""
	@for skill in $(REPO_SKILLS)/*/SKILL.md; do \
		name=$$(grep "^name:" "$$skill" | sed 's/name: *//'); \
		desc=$$(grep "^description:" "$$skill" | sed 's/description: *//; s/^"//; s/"$$//'); \
		printf "  $(CYAN)%-35s$(RESET) %s\n" "$$name" "$$desc"; \
	done
	@echo ""

#############################
### Sync Configs           ###
#############################

SYNC_DIR := $(HOME)/workspace/configs

.PHONY: sync
sync: ## Backup tool configs into ~/workspace/configs/ (one-way snapshot)
	@echo "=== ~/.claude → $(SYNC_DIR)/claude/ ==="
	@mkdir -p $(SYNC_DIR)/claude
	@if [ -d ~/.claude/agents ]; then rsync -a --delete --exclude '.git' ~/.claude/agents $(SYNC_DIR)/claude/; else rm -rf $(SYNC_DIR)/claude/agents; fi
	@[ -f ~/.claude/CLAUDE.md ] && cp ~/.claude/CLAUDE.md $(SYNC_DIR)/claude/ || true
	@[ -f ~/.claude/Makefile ] && cp ~/.claude/Makefile $(SYNC_DIR)/claude/ || true
	@[ -f ~/.claude/ideas.md ] && cp ~/.claude/ideas.md $(SYNC_DIR)/claude/ || true
	@[ -f ~/.claude/.markdownlint.json ] && cp ~/.claude/.markdownlint.json $(SYNC_DIR)/claude/ || true
	@echo "=== ~/.gemini → $(SYNC_DIR)/gemini/ ==="
	@mkdir -p $(SYNC_DIR)/gemini
	@if [ -d ~/.gemini/commands ]; then rsync -a --delete --exclude '.git' ~/.gemini/commands $(SYNC_DIR)/gemini/; else rm -rf $(SYNC_DIR)/gemini/commands; fi
	@[ -f ~/.gemini/GEMINI.md ] && cp ~/.gemini/GEMINI.md $(SYNC_DIR)/gemini/ || true
	@[ -f ~/.gemini/settings.json ] && cp ~/.gemini/settings.json $(SYNC_DIR)/gemini/ || true
	@echo "=== ~/.codex → $(SYNC_DIR)/codex/ ==="
	@mkdir -p $(SYNC_DIR)/codex
	@if [ -d ~/.codex/prompts ]; then rsync -a --delete --exclude '.git' ~/.codex/prompts $(SYNC_DIR)/codex/; else rm -rf $(SYNC_DIR)/codex/prompts; fi
	@if [ -d ~/.codex/rules ]; then rsync -a --delete --exclude '.git' ~/.codex/rules $(SYNC_DIR)/codex/; else rm -rf $(SYNC_DIR)/codex/rules; fi
	@[ -f ~/.codex/config.toml ] && cp ~/.codex/config.toml $(SYNC_DIR)/codex/ || true
	@echo "Done"

.PHONY: publish
publish: ## Install all skills globally via npx (for skills.sh telemetry), then restore local symlinks
	@echo "Installing all skills globally via npx..."
	@cd ~ && npx skills add olshansk/agent-skills --all -g -y
	@echo ""
	@echo "Restoring local symlinks..."
	@$(MAKE) link-skills

########################
### Testing          ###
########################

STRESS_SKILL ?= cmd-pr-conflict-resolver
STRESS_COUNT ?= 50

.PHONY: stress-install
stress-install: ## Reinstall a single skill N times (testing only)
	@echo "Stress-testing: installing '$(STRESS_SKILL)' $(STRESS_COUNT) times..."
	@for i in $$(seq 1 $(STRESS_COUNT)); do \
		echo "=== Run $$i/$(STRESS_COUNT) ==="; \
		cd ~ && npx skills add olshansk/agent-skills --skill $(STRESS_SKILL) -g -a '*' -y; \
	done
	@echo ""
	@echo "Restoring local symlinks..."
	@$(MAKE) link-skills
	@echo "Done — $(STRESS_COUNT) installs completed"

########################
### Info             ###
########################

.PHONY: status
status: ## Show repository status
	@echo "Repository Status:"
	@echo "  Skills:  $$(find skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') skills"
	@echo "  Claude:  $$(find personal/configs/claude -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ') config files"
	@echo "  Gemini:  $$(find personal/configs/gemini -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ') config files"
	@echo "  Codex:   $$(find personal/configs/codex -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ') config files"

.PHONY: test
test: ## Validate skill frontmatter and repo consistency
	@echo "Running checks..."
	@errors=0; \
	for skill in $(REPO_SKILLS)/*/SKILL.md; do \
		name=$$(grep "^name:" "$$skill" | sed 's/name: *//'); \
		desc=$$(grep "^description:" "$$skill" | sed 's/description: *//'); \
		dir_name=$$(basename $$(dirname "$$skill")); \
		if [ -z "$$name" ]; then \
			echo "  FAIL $$dir_name: missing 'name' in frontmatter"; errors=$$((errors+1)); \
		elif [ "$$name" != "$$dir_name" ]; then \
			echo "  FAIL $$dir_name: name '$$name' doesn't match directory"; errors=$$((errors+1)); \
		fi; \
		if [ -z "$$desc" ]; then \
			echo "  FAIL $$dir_name: missing 'description' in frontmatter"; errors=$$((errors+1)); \
		fi; \
	done; \
	skill_count=$$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' '); \
	skillmd_count=$$(find skills -name SKILL.md | wc -l | tr -d ' '); \
	if [ "$$skill_count" != "$$skillmd_count" ]; then \
		echo "  FAIL skill dir count ($$skill_count) != SKILL.md count ($$skillmd_count)"; errors=$$((errors+1)); \
	fi; \
	echo "  $$skill_count skills checked"; \
	if [ $$errors -gt 0 ]; then \
		echo "FAILED: $$errors error(s)"; exit 1; \
	else \
		echo "All checks passed"; \
	fi
