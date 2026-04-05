SHELL:=bash
GREEN  := $(shell tput setaf 2 2>/dev/null || echo "")
YELLOW := $(shell tput setaf 3 2>/dev/null || echo "")
RED    := $(shell tput setaf 1 2>/dev/null || echo "")
RESET  := $(shell tput sgr0  2>/dev/null || echo "")

APP_NAME    := GitConfigs
BUNDLE      := $(APP_NAME).app
INSTALL_DIR := /Applications
SVG_SRC     := Assets/icon.svg
LOGO_PNG    := Assets/logo-source.png
LOGO_IMPORT := logo.png
ICONSET     := Assets/AppIcon.iconset
ICNS        := Assets/AppIcon.icns
APP_LOGO_PNG := Sources/GitConfigsLib/Resources/AppLogo.png
XCODE_APPICON := Sources/GitConfigs/Assets.xcassets/AppIcon.appiconset
XCODE_APPLOGO := Sources/GitConfigs/Assets.xcassets/AppLogo.imageset

XCODEPROJ   := GitConfigsUI.xcodeproj
XCODE_SCHEME := GitConfigsApp

.DEFAULT_GOAL := help



help: ## Available commands
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[0;33m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""




##@ Targets

.PHONY: build build-release run open import-logo icon bundle install uninstall clean test test-ui test-all help

build: ## Build debug binary
	swift build

build-release: ## Build release binary (optimized)
	swift build -c release

run: ## Run app (terminal-attached, may lose keyboard focus)
	swift run

open: build ## Build and open as .app (correct keyboard focus)
	open .build/debug/$(APP_NAME)

import-logo: ## Center-crop $(LOGO_IMPORT) to 1024×1024 → $(LOGO_PNG); needs: brew install imagemagick
	@test -f $(LOGO_IMPORT) || { echo "$(RED)Missing $(LOGO_IMPORT)$(RESET)"; exit 1; }
	@which magick > /dev/null 2>&1 || { echo "$(RED)Missing magick. Run: brew install imagemagick$(RESET)"; exit 1; }
	@magick $(LOGO_IMPORT) -gravity center -extent 1024x1024 $(LOGO_PNG)
	@echo "$(GREEN)Updated $(LOGO_PNG) from $(LOGO_IMPORT) (square crop)$(RESET)"

icon: ## AppIcon.icns from LOGO_PNG (sips) or else SVG_SRC (rsvg-convert); updates AppLogo + Xcode AppIcon
	@mkdir -p $(ICONSET)
	@echo "$(GREEN)Rendering icon sizes...$(RESET)"
	@if [ -f $(LOGO_PNG) ]; then \
		for size in 16 32 64 128 256 512 1024; do \
			sips -z $$size $$size $(LOGO_PNG) --out $(ICONSET)/icon_$${size}x$${size}.png >/dev/null || exit 1; \
		done; \
	else \
		which rsvg-convert > /dev/null 2>&1 || { echo "$(RED)No $(LOGO_PNG) and no rsvg-convert. Add a PNG or: brew install librsvg$(RESET)"; exit 1; }; \
		for size in 16 32 64 128 256 512 1024; do \
			rsvg-convert -w $$size -h $$size $(SVG_SRC) -o $(ICONSET)/icon_$${size}x$${size}.png; \
		done; \
	fi
	@cp $(ICONSET)/icon_32x32.png    $(ICONSET)/icon_16x16@2x.png
	@cp $(ICONSET)/icon_64x64.png    $(ICONSET)/icon_32x32@2x.png
	@cp $(ICONSET)/icon_256x256.png  $(ICONSET)/icon_128x128@2x.png
	@cp $(ICONSET)/icon_512x512.png  $(ICONSET)/icon_256x256@2x.png
	@cp $(ICONSET)/icon_1024x1024.png $(ICONSET)/icon_512x512@2x.png
	@iconutil -c icns $(ICONSET) -o $(ICNS)
	@mkdir -p $$(dirname $(APP_LOGO_PNG))
	@sips -z 256 256 $(ICONSET)/icon_1024x1024.png --out $(APP_LOGO_PNG) >/dev/null || exit 1
	@mkdir -p $(XCODE_APPICON)
	@for f in icon_16x16.png icon_16x16@2x.png icon_32x32.png icon_32x32@2x.png icon_128x128.png icon_128x128@2x.png icon_256x256.png icon_256x256@2x.png icon_512x512.png icon_512x512@2x.png; do \
		cp "$(ICONSET)/$$f" "$(XCODE_APPICON)/$$f"; \
	done
	@mkdir -p $(XCODE_APPLOGO)
	@cp $(APP_LOGO_PNG) $(XCODE_APPLOGO)/AppLogo.png
	@echo "$(GREEN)Icon created: $(ICNS)$(RESET)"

bundle: build-release ## Create .app bundle in current directory (run 'make icon' first)
	@echo "$(GREEN)Building .app bundle...$(RESET)"
	@rm -rf $(BUNDLE)
	@mkdir -p $(BUNDLE)/Contents/MacOS
	@mkdir -p $(BUNDLE)/Contents/Resources
	@cp .build/release/$(APP_NAME) $(BUNDLE)/Contents/MacOS/$(APP_NAME)
	@if [ -f $(ICNS) ]; then \
		cp $(ICNS) $(BUNDLE)/Contents/Resources/AppIcon.icns; \
		echo "$(GREEN)Icon included$(RESET)"; \
	else \
		echo "$(YELLOW)No icon found — run 'make icon' to generate it$(RESET)"; \
	fi
	@/usr/libexec/PlistBuddy -c "Add :CFBundleName            string $(APP_NAME)"               $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable      string $(APP_NAME)"               $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier      string com.romanitalian.$(APP_NAME)" $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleVersion         string 1"                         $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0.0"                  $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType     string APPL"                      $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :NSPrincipalClass        string NSApplication"             $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool true"                        $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile        string AppIcon"                   $(BUNDLE)/Contents/Info.plist
	@echo "$(GREEN)Bundle created: $(BUNDLE)$(RESET)"

install: bundle ## Install app to /Applications
	@echo "$(GREEN)Installing to $(INSTALL_DIR)...$(RESET)"
	@rm -rf $(INSTALL_DIR)/$(BUNDLE)
	@cp -r $(BUNDLE) $(INSTALL_DIR)/$(BUNDLE)
	@echo "$(GREEN)Installed: $(INSTALL_DIR)/$(BUNDLE)$(RESET)"

uninstall: ## Remove app from /Applications
	@rm -rf $(INSTALL_DIR)/$(BUNDLE)
	@echo "$(YELLOW)Uninstalled: $(INSTALL_DIR)/$(BUNDLE)$(RESET)"

clean: ## Clean build artifacts, bundle and generated icons
	swift package clean
	@rm -rf $(BUNDLE) $(ICONSET) $(ICNS)

test: ## Run unit + BDD tests (swift test)
	swift test

test-ui: ## Run XCUITest via xcodebuild (needs Xcode; GUI session for automation)
	@which xcodegen >/dev/null 2>&1 || { echo "$(RED)Missing xcodegen. Run: brew install xcodegen$(RESET)"; exit 1; }
	xcodegen generate
	xcodebuild -project $(XCODEPROJ) -scheme $(XCODE_SCHEME) -destination 'platform=macOS' test

test-all: test test-ui ## Run swift test + UI tests


##@ Aliases

.PHONY: r o i
r: ## Run app
	@make run

o: ## Build and open app
	@make open

i: ## Install app to /Applications
	@make install
