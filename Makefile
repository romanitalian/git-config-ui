SHELL:=bash
GREEN  := $(shell tput setaf 2 2>/dev/null || echo "")
YELLOW := $(shell tput setaf 3 2>/dev/null || echo "")
RED    := $(shell tput setaf 1 2>/dev/null || echo "")
RESET  := $(shell tput sgr0  2>/dev/null || echo "")

APP_NAME    := GitConfigs
BUNDLE      := $(APP_NAME).app
INSTALL_DIR := /Applications
SVG_SRC     := Assets/icon.svg
ICONSET     := Assets/AppIcon.iconset
ICNS        := Assets/AppIcon.icns

.DEFAULT_GOAL := help



help: ## Available commands
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[0;33m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""




##@ Targets

.PHONY: build build-release run open icon bundle install uninstall clean test help

build: ## Build debug binary
	swift build

build-release: ## Build release binary (optimized)
	swift build -c release

run: ## Run app (terminal-attached, may lose keyboard focus)
	swift run

open: build ## Build and open as .app (correct keyboard focus)
	open .build/debug/$(APP_NAME)

icon: ## Generate AppIcon.icns from Assets/icon.svg (requires: brew install librsvg)
	@which rsvg-convert > /dev/null 2>&1 || { echo "$(RED)Missing rsvg-convert. Run: brew install librsvg$(RESET)"; exit 1; }
	@mkdir -p $(ICONSET)
	@echo "$(GREEN)Rendering icon sizes...$(RESET)"
	@for size in 16 32 64 128 256 512 1024; do \
		rsvg-convert -w $$size -h $$size $(SVG_SRC) -o $(ICONSET)/icon_$${size}x$${size}.png; \
	done
	@cp $(ICONSET)/icon_32x32.png    $(ICONSET)/icon_16x16@2x.png
	@cp $(ICONSET)/icon_64x64.png    $(ICONSET)/icon_32x32@2x.png
	@cp $(ICONSET)/icon_256x256.png  $(ICONSET)/icon_128x128@2x.png
	@cp $(ICONSET)/icon_512x512.png  $(ICONSET)/icon_256x256@2x.png
	@cp $(ICONSET)/icon_1024x1024.png $(ICONSET)/icon_512x512@2x.png
	@iconutil -c icns $(ICONSET) -o $(ICNS)
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
	@/usr/libexec/PlistBuddy -c "Add :CFBundleVersion         string 1.0"                       $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0"                    $(BUNDLE)/Contents/Info.plist
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

test: ## Run tests
	swift test


##@ Aliases

.PHONY: r o i
r: ## Run app
	@make run

o: ## Build and open app
	@make open

i: ## Install app to /Applications
	@make install
