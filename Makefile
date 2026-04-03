SHELL:=bash
GREEN := $(shell tput setaf 2 2>/dev/null || echo "")
YELLOW := $(shell tput setaf 3 2>/dev/null || echo "")
RED := $(shell tput setaf 1 2>/dev/null || echo "")
RESET := $(shell tput sgr0 2>/dev/null || echo "")

APP_NAME    := GitToggleUserUI
BUNDLE      := $(APP_NAME).app
INSTALL_DIR := /Applications

.DEFAULT_GOAL := help



help: ## Available commands
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[0;33m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""




##@ Targets


.PHONY: build run open bundle install uninstall clean test help

build: ## Build debug binary
	swift build

build-release: ## Build release binary (optimized)
	swift build -c release

run: ## Run app (terminal-attached, may lose keyboard focus)
	swift run

open: build ## Build and open as .app (correct keyboard focus)
	open .build/debug/$(APP_NAME)

bundle: build-release ## Create .app bundle in current directory
	@echo "$(GREEN)Building .app bundle...$(RESET)"
	@rm -rf $(BUNDLE)
	@mkdir -p $(BUNDLE)/Contents/MacOS
	@cp .build/release/$(APP_NAME) $(BUNDLE)/Contents/MacOS/$(APP_NAME)
	@/usr/libexec/PlistBuddy -c "Add :CFBundleName           string $(APP_NAME)"        $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable     string $(APP_NAME)"        $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier     string com.romanitalian.$(APP_NAME)" $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundleVersion        string 1.0"                $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType    string APPL"               $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :NSPrincipalClass       string NSApplication"      $(BUNDLE)/Contents/Info.plist
	@/usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool true"                $(BUNDLE)/Contents/Info.plist
	@echo "$(GREEN)Bundle created: $(BUNDLE)$(RESET)"

install: bundle ## Install app to /Applications
	@echo "$(GREEN)Installing to $(INSTALL_DIR)...$(RESET)"
	@rm -rf $(INSTALL_DIR)/$(BUNDLE)
	@cp -r $(BUNDLE) $(INSTALL_DIR)/$(BUNDLE)
	@echo "$(GREEN)Installed: $(INSTALL_DIR)/$(BUNDLE)$(RESET)"

uninstall: ## Remove app from /Applications
	@rm -rf $(INSTALL_DIR)/$(BUNDLE)
	@echo "$(YELLOW)Uninstalled: $(INSTALL_DIR)/$(BUNDLE)$(RESET)"

clean: ## Clean build artifacts and bundle
	swift package clean
	@rm -rf $(BUNDLE)

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