########################################
### Electron & Distribution          ###
########################################

# Builds use electron-builder by default.
# Adjust the npm script names or use npx directly to match your setup.
#
# If using electron-forge instead, change the scripts accordingly:
#   "make":        "electron-forge make"
#   "package":     "electron-forge package"

#########################
### Public Targets    ###
#########################

.PHONY: electron-pack-check
electron-pack-check: _check-deps ## Verify Electron app loads without errors
	$(call print_section,Checking Electron app health)
	@$(ELECTRON_BIN) --no-sandbox --disable-gpu . --smoke-test 2>&1 | head -20 || true
	$(call print_success,Check complete — review output above)

.PHONY: electron-dist-mac
electron-dist-mac: _check-deps ## Build macOS .dmg installer
	$(call print_section,Building macOS .dmg)
	$(Q)npx electron-builder --mac
	$(call print_success,macOS .dmg created in dist/)
	@DMG_FILE=$$(ls dist/*.dmg 2>/dev/null | head -1); \
	if [ -n "$$DMG_FILE" ]; then \
		DMG_SIZE=$$(du -h "$$DMG_FILE" | cut -f1); \
		printf "  $(DIM)DMG:$(RESET)  $$DMG_FILE ($$DMG_SIZE)\n\n"; \
	fi

.PHONY: electron-dist-win
electron-dist-win: _check-deps ## Build Windows .exe installer
	$(call print_section,Building Windows .exe installer)
	$(Q)npx electron-builder --win
	$(call print_success,Windows installer created in dist/)
	@EXE_FILE=$$(ls dist/*.exe 2>/dev/null | head -1); \
	if [ -n "$$EXE_FILE" ]; then \
		EXE_SIZE=$$(du -h "$$EXE_FILE" | cut -f1); \
		printf "  $(DIM)Installer:$(RESET) $$EXE_FILE ($$EXE_SIZE)\n\n"; \
	fi

.PHONY: electron-dist-linux
electron-dist-linux: _check-deps ## Build Linux AppImage + deb
	$(call print_section,Building Linux packages)
	$(Q)npx electron-builder --linux
	$(call print_success,Linux packages created in dist/)
	@APPIMAGE=$$(ls dist/*.AppImage 2>/dev/null | head -1); \
	if [ -n "$$APPIMAGE" ]; then \
		AI_SIZE=$$(du -h "$$APPIMAGE" | cut -f1); \
		printf "  $(DIM)AppImage:$(RESET) $$APPIMAGE ($$AI_SIZE)\n\n"; \
	fi

.PHONY: electron-dist-all
electron-dist-all: _check-deps ## Build for all platforms (macOS, Windows, Linux)
	$(call print_section,Building macOS .dmg)
	$(Q)npx electron-builder --mac
	$(call print_success,macOS .dmg created in dist/)
	$(call print_section,Building Windows .exe installer)
	$(Q)npx electron-builder --win
	$(call print_success,Windows installer created in dist/)
	$(call print_section,Building Linux packages)
	$(Q)npx electron-builder --linux
	$(call print_success,Linux packages created in dist/)
	$(call print_success,All distributables created in dist/)

.PHONY: electron-publish
electron-publish: _check-deps ## Build and publish release (requires GH_TOKEN)
	$(call print_section,Publishing Electron app)
	@if [ -z "$${GH_TOKEN:-}" ]; then \
		printf "$(YELLOW)$(WARN) GH_TOKEN not set — publish may fail$(RESET)\n"; \
		printf "$(CYAN)$(INFO) Set GH_TOKEN for GitHub Releases auto-publish$(RESET)\n"; \
	fi
	$(Q)$(PKG_MANAGER) run publish
	$(call print_success,Publish complete)
