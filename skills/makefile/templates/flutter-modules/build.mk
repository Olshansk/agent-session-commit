############################
### Flutter Build        ###
############################

# Load .env file and convert to --dart-define flags
DART_DEFINES = $(shell [ -f .env ] && grep -v '^\#' .env | grep -v '^$$' | sed 's/^/--dart-define=/' | tr '\n' ' ')

#########################
### Internal Checks   ###
#########################

.PHONY: _check-asc-app
_check-asc-app:
	@if [ -n "$(ASC_API_KEY)" ] && [ -n "$(ASC_API_ISSUER)" ]; then \
		printf "$(CYAN)Verifying App Store Connect access...$(RESET)\n"; \
		ASC_OUTPUT=$$(xcrun altool --list-apps --apiKey "$(ASC_API_KEY)" --apiIssuer "$(ASC_API_ISSUER)" 2>&1); \
		if [ $$? -ne 0 ]; then \
			printf "\n"; \
			printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
			printf "$(RED)$(BOLD)  App Store Connect Check Failed$(RESET)\n"; \
			printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
			printf "\n"; \
			printf "  $(YELLOW)Could not connect to App Store Connect.$(RESET)\n"; \
			printf "  $(DIM)Verify your API key is at:$(RESET) ~/.private_keys/AuthKey_$(ASC_API_KEY).p8\n"; \
			printf "\n"; \
			printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
			printf "\n"; \
			exit 1; \
		fi; \
		printf "$(GREEN)$(CHECK) App Store Connect OK$(RESET)\n"; \
	else \
		printf "$(YELLOW)$(WARN) Tip: Set ASC_API_KEY and ASC_API_ISSUER to enable pre-flight ASC checks$(RESET)\n"; \
	fi

.PHONY: _check-export-options
_check-export-options:
	@if [ ! -f "$(EXPORT_OPTIONS_PLIST)" ]; then \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(RED)$(BOLD)  Missing ExportOptions.plist$(RESET)\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(DIM)Expected:$(RESET) $(EXPORT_OPTIONS_PLIST)\n"; \
		printf "\n"; \
		printf "  $(YELLOW)This file is required to export an IPA for distribution.$(RESET)\n"; \
		printf "  $(DIM)See: https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution$(RESET)\n"; \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		exit 1; \
	fi

#########################
### Public Targets    ###
#########################

.PHONY: flutter-build-ios
flutter-build-ios: _check-flutter ## Build for iOS simulator
	$(call print_section,Building Flutter for iOS simulator)
	$(Q)cd $(FLUTTER_DIR) && flutter build ios --simulator $(DART_DEFINES)
	$(call print_success,iOS simulator build complete)

.PHONY: flutter-build-ipa
flutter-build-ipa: _check-flutter _check-export-options _check-asc-app ## Build IPA for App Store distribution
	$(call print_section,Flutter IPA Build)
	@# --- Version bump prompt ---
	@CURRENT_VERSION=$$(grep '^version:' $(FLUTTER_DIR)/pubspec.yaml | sed 's/version: *//'); \
	APP_VERSION=$$(echo "$$CURRENT_VERSION" | cut -d'+' -f1); \
	BUILD_NUM=$$(echo "$$CURRENT_VERSION" | cut -d'+' -f2); \
	NEW_BUILD=$$(( BUILD_NUM + 1 )); \
	printf "\n"; \
	printf "  $(BOLD)Current version:$(RESET) $(CYAN)$$APP_VERSION$(RESET) $(DIM)(build $$BUILD_NUM)$(RESET)\n"; \
	printf "\n"; \
	printf "  $(DIM)1)$(RESET) Bump patch   $(ARROW) $$(echo $$APP_VERSION | awk -F. -v OFS=. '{$$NF=$$NF+1; print}')\n"; \
	printf "  $(DIM)2)$(RESET) Bump minor   $(ARROW) $$(echo $$APP_VERSION | awk -F. -v OFS=. '{$$(NF-1)=$$(NF-1)+1; $$NF=0; print}')\n"; \
	printf "  $(DIM)3)$(RESET) Keep $$APP_VERSION\n"; \
	printf "\n"; \
	printf "  $(BOLD)Choose [1-3]:$(RESET) "; \
	read CHOICE; \
	case "$$CHOICE" in \
		1) \
			NEW_APP=$$(echo $$APP_VERSION | awk -F. -v OFS=. '{$$NF=$$NF+1; print}'); \
			NEW_VERSION="$$NEW_APP+$$NEW_BUILD"; \
			;; \
		2) \
			NEW_APP=$$(echo $$APP_VERSION | awk -F. -v OFS=. '{$$(NF-1)=$$(NF-1)+1; $$NF=0; print}'); \
			NEW_VERSION="$$NEW_APP+$$NEW_BUILD"; \
			;; \
		3) \
			NEW_APP="$$APP_VERSION"; \
			NEW_VERSION="$$NEW_APP+$$NEW_BUILD"; \
			;; \
		*) \
			printf "  $(RED)Invalid choice. Aborting.$(RESET)\n"; \
			exit 1; \
			;; \
	esac; \
	sed -i '' "s/^version: .*/version: $$NEW_VERSION/" $(FLUTTER_DIR)/pubspec.yaml; \
	printf "  $(GREEN)Updated:$(RESET) $$APP_VERSION $(DIM)(build $$BUILD_NUM)$(RESET) $(ARROW) $(BOLD)$$NEW_APP$(RESET) $(DIM)(build $$NEW_BUILD)$(RESET)\n"; \
	printf "\n"
	@# Clean stale IPAs to avoid false positives
	@rm -rf $(FLUTTER_DIR)/build/ios/ipa
	@BUILD_LOG=$$(mktemp); \
	printf "$(CYAN)Building...$(RESET)\n"; \
	cd $(FLUTTER_DIR) && flutter build ipa --release $(DART_DEFINES) --export-options-plist=$(EXPORT_OPTIONS_PLIST) 2>&1 | tee "$$BUILD_LOG" | sed '/flutter has exited unexpectedly/,$$d'; \
	FLUTTER_EXIT=$$?; \
	IPA_FILE=$$(ls $(FLUTTER_DIR)/build/ios/ipa/*.ipa 2>/dev/null | head -1); \
	if [ -n "$$IPA_FILE" ]; then \
		IPA_SIZE=$$(du -h "$$IPA_FILE" | cut -f1); \
		printf "\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(GREEN)$(BOLD)  IPA Ready!$(RESET)\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(DIM)File:$(RESET) $$IPA_FILE\n"; \
		printf "  $(DIM)Size:$(RESET) $$IPA_SIZE\n"; \
		printf "\n"; \
		printf "$(YELLOW)$(BOLD)  Next step:$(RESET)\n"; \
		printf "\n"; \
		printf "     $(CYAN)make flutter-deploy-testflight$(RESET)\n"; \
		printf "\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		rm -f "$$BUILD_LOG"; \
	elif grep -q "Error Downloading App Information" "$$BUILD_LOG" 2>/dev/null; then \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(RED)$(BOLD)  App Not Registered in App Store Connect$(RESET)\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(YELLOW)The archive built successfully, but IPA export failed because$(RESET)\n"; \
		printf "  $(YELLOW)the app is not registered in App Store Connect.$(RESET)\n"; \
		printf "\n"; \
		printf "  $(BOLD)To fix:$(RESET)\n"; \
		printf "  $(DIM)1.$(RESET) Go to $(CYAN)https://appstoreconnect.apple.com/apps$(RESET)\n"; \
		printf "  $(DIM)2.$(RESET) Click $(BOLD)+$(RESET) $(ARROW) $(BOLD)New App$(RESET)\n"; \
		printf "  $(DIM)3.$(RESET) Fill in app name, bundle ID, and SKU\n"; \
		printf "  $(DIM)4.$(RESET) Re-export without rebuilding:\n"; \
		printf "\n"; \
		printf "     $(CYAN)make flutter-export-ipa$(RESET)\n"; \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		rm -f "$$BUILD_LOG"; \
		exit 1; \
	elif grep -q "Redundant Binary Upload" "$$BUILD_LOG" 2>/dev/null; then \
		APP_VER=$$(grep '^version:' $(FLUTTER_DIR)/pubspec.yaml | sed 's/version: *//' | cut -d'+' -f1); \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(RED)$(BOLD)  Duplicate Build Number$(RESET)\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(YELLOW)Version $$APP_VER was already uploaded.$(RESET)\n"; \
		printf "  $(DIM)Bump the build number and re-run:$(RESET)\n"; \
		printf "\n"; \
		printf "     $(CYAN)make flutter-build-ipa$(RESET)\n"; \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		rm -f "$$BUILD_LOG"; \
		exit 1; \
	elif grep -q "Directory listing failed.*build/ios/ipa" "$$BUILD_LOG" 2>/dev/null && \
	     grep -q "destination.*upload\|app-store-connect" $(EXPORT_OPTIONS_PLIST) 2>/dev/null; then \
		APP_VER=$$(grep '^version:' $(FLUTTER_DIR)/pubspec.yaml | sed 's/version: *//' | cut -d'+' -f1); \
		printf "\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(GREEN)$(BOLD)  Uploaded to App Store Connect!$(RESET)\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(DIM)Version:$(RESET) $$APP_VER\n"; \
		printf "\n"; \
		printf "  $(YELLOW)Check TestFlight in a few minutes:$(RESET)\n"; \
		printf "     $(CYAN)https://appstoreconnect.apple.com/apps$(RESET)\n"; \
		printf "\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		rm -f "$$BUILD_LOG"; \
	elif [ -d "$(FLUTTER_DIR)/build/ios/archive/Runner.xcarchive" ]; then \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(RED)$(BOLD)  IPA Export Failed$(RESET)\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(YELLOW)The archive was created but IPA export failed.$(RESET)\n"; \
		printf "  $(DIM)Build log saved to:$(RESET) $$BUILD_LOG\n"; \
		printf "\n"; \
		printf "  $(DIM)Fix the issue, then re-export without rebuilding:$(RESET)\n"; \
		printf "     $(CYAN)make flutter-export-ipa$(RESET)\n"; \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		exit 1; \
	else \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(RED)$(BOLD)  Build Failed$(RESET)\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(YELLOW)No archive was produced. The build itself failed.$(RESET)\n"; \
		printf "\n"; \
		printf "  $(DIM)Re-run with verbose output:$(RESET)\n"; \
		printf "     $(CYAN)make flutter-build-ipa VERBOSE=1$(RESET)\n"; \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		rm -f "$$BUILD_LOG"; \
		exit 1; \
	fi

.PHONY: flutter-export-ipa
flutter-export-ipa: _check-export-options ## Re-export IPA from existing archive (no rebuild)
	$(call print_section,Re-exporting IPA from archive)
	@if [ ! -d "$(FLUTTER_DIR)/build/ios/archive/Runner.xcarchive" ]; then \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(RED)$(BOLD)  No Archive Found$(RESET)\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(YELLOW)No .xcarchive exists. Build first:$(RESET)\n"; \
		printf "\n"; \
		printf "     $(CYAN)make flutter-build-ipa$(RESET)\n"; \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		exit 1; \
	fi
	@rm -rf $(FLUTTER_DIR)/build/ios/ipa
	@BUILD_LOG=$$(mktemp); \
	printf "$(CYAN)Exporting...$(RESET)\n"; \
	xcodebuild -exportArchive \
		-archivePath $(FLUTTER_DIR)/build/ios/archive/Runner.xcarchive \
		-exportOptionsPlist $(EXPORT_OPTIONS_PLIST) \
		-exportPath $(FLUTTER_DIR)/build/ios/ipa \
		-allowProvisioningUpdates 2>&1 | tee "$$BUILD_LOG"; \
	EXPORT_EXIT=$$?; \
	IPA_FILE=$$(ls $(FLUTTER_DIR)/build/ios/ipa/*.ipa 2>/dev/null | head -1); \
	if [ -n "$$IPA_FILE" ]; then \
		IPA_SIZE=$$(du -h "$$IPA_FILE" | cut -f1); \
		printf "\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(GREEN)$(BOLD)  IPA Ready!$(RESET)\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(DIM)File:$(RESET) $$IPA_FILE\n"; \
		printf "  $(DIM)Size:$(RESET) $$IPA_SIZE\n"; \
		printf "\n"; \
		printf "$(YELLOW)$(BOLD)  Next step:$(RESET)\n"; \
		printf "\n"; \
		printf "     $(CYAN)make flutter-deploy-testflight$(RESET)\n"; \
		printf "\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		rm -f "$$BUILD_LOG"; \
	elif grep -q "Error Downloading App Information" "$$BUILD_LOG" 2>/dev/null; then \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(RED)$(BOLD)  App Not Registered in App Store Connect$(RESET)\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(BOLD)To fix:$(RESET)\n"; \
		printf "  $(DIM)1.$(RESET) Go to $(CYAN)https://appstoreconnect.apple.com/apps$(RESET)\n"; \
		printf "  $(DIM)2.$(RESET) Click $(BOLD)+$(RESET) $(ARROW) $(BOLD)New App$(RESET)\n"; \
		printf "  $(DIM)3.$(RESET) Fill in app name, bundle ID, and SKU\n"; \
		printf "  $(DIM)4.$(RESET) Re-run: $(CYAN)make flutter-export-ipa$(RESET)\n"; \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		rm -f "$$BUILD_LOG"; \
		exit 1; \
	elif grep -q "Redundant Binary Upload" "$$BUILD_LOG" 2>/dev/null; then \
		APP_VER=$$(grep '^version:' $(FLUTTER_DIR)/pubspec.yaml | sed 's/version: *//' | cut -d'+' -f1); \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(RED)$(BOLD)  Duplicate Build Number$(RESET)\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(YELLOW)Version $$APP_VER was already uploaded.$(RESET)\n"; \
		printf "  $(DIM)Bump the build number and rebuild:$(RESET)\n"; \
		printf "\n"; \
		printf "     $(CYAN)make flutter-build-ipa$(RESET)\n"; \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		rm -f "$$BUILD_LOG"; \
		exit 1; \
	elif grep -q "EXPORT FAILED" "$$BUILD_LOG" 2>/dev/null; then \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(RED)$(BOLD)  Export Failed$(RESET)\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(DIM)Build log saved to:$(RESET) $$BUILD_LOG\n"; \
		printf "\n"; \
		exit 1; \
	elif grep -q "upload" $(EXPORT_OPTIONS_PLIST) 2>/dev/null; then \
		APP_VER=$$(grep '^version:' $(FLUTTER_DIR)/pubspec.yaml | sed 's/version: *//' | cut -d'+' -f1); \
		printf "\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(GREEN)$(BOLD)  Uploaded to App Store Connect!$(RESET)\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(DIM)Version:$(RESET) $$APP_VER\n"; \
		printf "\n"; \
		printf "  $(YELLOW)Check TestFlight in a few minutes:$(RESET)\n"; \
		printf "     $(CYAN)https://appstoreconnect.apple.com/apps$(RESET)\n"; \
		printf "\n"; \
		printf "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		rm -f "$$BUILD_LOG"; \
	else \
		printf "\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "$(RED)$(BOLD)  Export Failed$(RESET)\n"; \
		printf "$(RED)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"; \
		printf "\n"; \
		printf "  $(DIM)Build log saved to:$(RESET) $$BUILD_LOG\n"; \
		printf "\n"; \
		exit 1; \
	fi

.PHONY: flutter-build-apk
flutter-build-apk: _check-flutter ## Build debug APK for Android
	$(call print_section,Building Flutter APK)
	$(Q)cd $(FLUTTER_DIR) && flutter build apk $(DART_DEFINES)
	$(call print_success,APK build complete)
	@APK_FILE="$(FLUTTER_DIR)/build/app/outputs/flutter-apk/app-release.apk"; \
	if [ -f "$$APK_FILE" ]; then \
		APK_SIZE=$$(du -h "$$APK_FILE" | cut -f1); \
		printf "  $(DIM)File:$(RESET) $$APK_FILE\n"; \
		printf "  $(DIM)Size:$(RESET) $$APK_SIZE\n\n"; \
	fi

.PHONY: flutter-build-aab
flutter-build-aab: _check-flutter ## Build AAB for Google Play Store
	$(call print_section,Building Flutter App Bundle)
	$(Q)cd $(FLUTTER_DIR) && flutter build appbundle $(DART_DEFINES)
	$(call print_success,AAB build complete)
	@AAB_FILE="$(FLUTTER_DIR)/build/app/outputs/bundle/release/app-release.aab"; \
	if [ -f "$$AAB_FILE" ]; then \
		AAB_SIZE=$$(du -h "$$AAB_FILE" | cut -f1); \
		printf "  $(DIM)File:$(RESET) $$AAB_FILE\n"; \
		printf "  $(DIM)Size:$(RESET) $$ABB_SIZE\n\n"; \
	fi
