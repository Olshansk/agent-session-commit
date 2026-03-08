########################
### Makefile Helpers ###
########################

BOLD := \033[1m
CYAN := \033[36m
RESET := \033[0m

REPO_SKILLS := $(CURDIR)/skills
SHARE_TARGETS := $(HOME)/.gemini/antigravity/skills $(HOME)/.codex/skills

.PHONY: help
.DEFAULT_GOAL := help
help: ## Prints all the targets in the Makefile
	@echo ""
	@echo "$(BOLD)$(CYAN)Agent Skills Repository$(RESET)"
	@echo ""
	@echo "$(BOLD)=== Skills ===$(RESET)"
	@grep -h -E '^(link|list).*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-40s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)=== Backup ===$(RESET)"
	@grep -h -E '^sync.*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-40s$(RESET) %s\n", $$1, $$2}'
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

.PHONY: sync
sync: ## Backup tool configs into personal/configs/ (one-way snapshot)
	@echo "=== ~/.claude → personal/configs/claude/ ==="
	@mkdir -p personal/configs/claude
	@if [ -d ~/.claude/agents ]; then rsync -a --delete --exclude '.git' ~/.claude/agents personal/configs/claude/; else rm -rf personal/configs/claude/agents; fi
	@[ -f ~/.claude/CLAUDE.md ] && cp ~/.claude/CLAUDE.md personal/configs/claude/ || true
	@[ -f ~/.claude/Makefile ] && cp ~/.claude/Makefile personal/configs/claude/ || true
	@[ -f ~/.claude/ideas.md ] && cp ~/.claude/ideas.md personal/configs/claude/ || true
	@[ -f ~/.claude/.markdownlint.json ] && cp ~/.claude/.markdownlint.json personal/configs/claude/ || true
	@echo "=== ~/.gemini → personal/configs/gemini/ ==="
	@mkdir -p personal/configs/gemini
	@if [ -d ~/.gemini/commands ]; then rsync -a --delete --exclude '.git' ~/.gemini/commands personal/configs/gemini/; else rm -rf personal/configs/gemini/commands; fi
	@[ -f ~/.gemini/GEMINI.md ] && cp ~/.gemini/GEMINI.md personal/configs/gemini/ || true
	@[ -f ~/.gemini/settings.json ] && cp ~/.gemini/settings.json personal/configs/gemini/ || true
	@echo "=== ~/.codex → personal/configs/codex/ ==="
	@mkdir -p personal/configs/codex
	@if [ -d ~/.codex/prompts ]; then rsync -a --delete --exclude '.git' ~/.codex/prompts personal/configs/codex/; else rm -rf personal/configs/codex/prompts; fi
	@if [ -d ~/.codex/rules ]; then rsync -a --delete --exclude '.git' ~/.codex/rules personal/configs/codex/; else rm -rf personal/configs/codex/rules; fi
	@[ -f ~/.codex/config.toml ] && cp ~/.codex/config.toml personal/configs/codex/ || true
	@echo "Done"

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
