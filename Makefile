.PHONY: help run build-apk build-apk-release clean get test format analyze doctor install

# Default target
.DEFAULT_GOAL := help

# Flutter commands
FLUTTER = flutter
DEVICE_ID ?=

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)MyTransit - Flutter Makefile Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Available commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

get: ## Get Flutter dependencies
	@echo "$(BLUE)Getting Flutter dependencies...$(NC)"
	$(FLUTTER) pub get

clean: ## Clean Flutter build files
	@echo "$(BLUE)Cleaning Flutter build files...$(NC)"
	$(FLUTTER) clean
	$(FLUTTER) pub get

doctor: ## Run Flutter doctor to check environment
	@echo "$(BLUE)Running Flutter doctor...$(NC)"
	$(FLUTTER) doctor -v

format: ## Format Dart code
	@echo "$(BLUE)Formatting Dart code...$(NC)"
	$(FLUTTER) format lib test

analyze: ## Analyze Dart code for issues
	@echo "$(BLUE)Analyzing Dart code...$(NC)"
	$(FLUTTER) analyze

test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	$(FLUTTER) test

test-coverage: ## Run tests with coverage
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	$(FLUTTER) test --coverage
	@echo "$(GREEN)Coverage report generated in coverage/$(NC)"

# Run commands
run: get ## Run the app on connected device/emulator
	@echo "$(BLUE)Running app...$(NC)"
	@if [ -z "$(DEVICE_ID)" ]; then \
		$(FLUTTER) run; \
	else \
		$(FLUTTER) run -d $(DEVICE_ID); \
	fi

run-dev: get ## Run the app in development mode (with hot reload)
	@echo "$(BLUE)Running app in development mode...$(NC)"
	@echo "$(YELLOW)Hot reload enabled - Press 'r' to reload, 'R' to restart$(NC)"
	@# Load environment variables from .env, check configuration, and run Flutter
	@if [ -f .env ]; then \
		echo "$(YELLOW)Loading environment variables from .env file...$(NC)"; \
		export $$(grep -v '^#' .env | grep -v '^$$' | xargs); \
	fi; \
	if [ -z "$$ACCESS_TOKEN" ]; then \
		echo "$(YELLOW)Warning: ACCESS_TOKEN not set. Mapbox features will not work.$(NC)"; \
		echo "$(YELLOW)Create a .env file with ACCESS_TOKEN=pk.your_token or export ACCESS_TOKEN$(NC)"; \
	else \
		echo "$(GREEN)ACCESS_TOKEN found: $${ACCESS_TOKEN:0:20}...$(NC)"; \
	fi; \
	if [ -z "$$SUPABASE_URL" ]; then \
		echo "$(YELLOW)Warning: SUPABASE_URL not set. Supabase features will not work.$(NC)"; \
	else \
		echo "$(GREEN)SUPABASE_URL found: $${SUPABASE_URL:0:30}...$(NC)"; \
	fi; \
	if [ -z "$$SUPABASE_ANON_KEY" ]; then \
		echo "$(YELLOW)Warning: SUPABASE_ANON_KEY not set. Supabase features will not work.$(NC)"; \
	else \
		echo "$(GREEN)SUPABASE_ANON_KEY found: $${SUPABASE_ANON_KEY:0:20}...$(NC)"; \
	fi; \
	DART_DEFINES=""; \
	if [ -n "$$ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define ACCESS_TOKEN=$$ACCESS_TOKEN"; \
	fi; \
	if [ -n "$$SUPABASE_URL" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_URL=$$SUPABASE_URL"; \
	fi; \
	if [ -n "$$SUPABASE_ANON_KEY" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_ANON_KEY=$$SUPABASE_ANON_KEY"; \
	fi; \
	if [ -n "$$MAPBOX_ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define MAPBOX_ACCESS_TOKEN=$$MAPBOX_ACCESS_TOKEN"; \
	fi; \
	if [ -z "$(DEVICE_ID)" ]; then \
		$(FLUTTER) run --debug $$DART_DEFINES; \
	else \
		$(FLUTTER) run --debug $$DART_DEFINES -d $(DEVICE_ID); \
	fi

run-release: get ## Run the app in release mode
	@echo "$(BLUE)Running app in release mode...$(NC)"
	@# Load environment variables from .env file
	@if [ -f .env ]; then \
		export $$(grep -v '^#' .env | grep -v '^$$' | xargs); \
	fi; \
	DART_DEFINES=""; \
	if [ -n "$$ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define ACCESS_TOKEN=$$ACCESS_TOKEN"; \
	fi; \
	if [ -n "$$SUPABASE_URL" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_URL=$$SUPABASE_URL"; \
	fi; \
	if [ -n "$$SUPABASE_ANON_KEY" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_ANON_KEY=$$SUPABASE_ANON_KEY"; \
	fi; \
	if [ -n "$$MAPBOX_ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define MAPBOX_ACCESS_TOKEN=$$MAPBOX_ACCESS_TOKEN"; \
	fi; \
	if [ -z "$(DEVICE_ID)" ]; then \
		$(FLUTTER) run --release $$DART_DEFINES; \
	else \
		$(FLUTTER) run --release $$DART_DEFINES -d $(DEVICE_ID); \
	fi

run-profile: get ## Run the app in profile mode
	@echo "$(BLUE)Running app in profile mode...$(NC)"
	@# Load environment variables from .env file
	@if [ -f .env ]; then \
		export $$(grep -v '^#' .env | grep -v '^$$' | xargs); \
	fi; \
	DART_DEFINES=""; \
	if [ -n "$$ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define ACCESS_TOKEN=$$ACCESS_TOKEN"; \
	fi; \
	if [ -n "$$SUPABASE_URL" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_URL=$$SUPABASE_URL"; \
	fi; \
	if [ -n "$$SUPABASE_ANON_KEY" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_ANON_KEY=$$SUPABASE_ANON_KEY"; \
	fi; \
	if [ -n "$$MAPBOX_ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define MAPBOX_ACCESS_TOKEN=$$MAPBOX_ACCESS_TOKEN"; \
	fi; \
	if [ -z "$(DEVICE_ID)" ]; then \
		$(FLUTTER) run --profile $$DART_DEFINES; \
	else \
		$(FLUTTER) run --profile $$DART_DEFINES -d $(DEVICE_ID); \
	fi

devices: ## List connected devices
	@echo "$(BLUE)Connected devices:$(NC)"
	$(FLUTTER) devices

# Build commands
build-apk: get ## Build debug APK
	@echo "$(BLUE)Building debug APK...$(NC)"
	@# Load environment variables from .env file
	@if [ -f .env ]; then \
		export $$(grep -v '^#' .env | grep -v '^$$' | xargs); \
	fi; \
	DART_DEFINES=""; \
	if [ -n "$$ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define ACCESS_TOKEN=$$ACCESS_TOKEN"; \
	fi; \
	if [ -n "$$SUPABASE_URL" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_URL=$$SUPABASE_URL"; \
	fi; \
	if [ -n "$$SUPABASE_ANON_KEY" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_ANON_KEY=$$SUPABASE_ANON_KEY"; \
	fi; \
	if [ -n "$$MAPBOX_ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define MAPBOX_ACCESS_TOKEN=$$MAPBOX_ACCESS_TOKEN"; \
	fi; \
	$(FLUTTER) build apk --debug $$DART_DEFINES
	@echo "$(GREEN)Debug APK built at: build/app/outputs/flutter-apk/app-debug.apk$(NC)"

build-apk-release: get ## Build release APK
	@echo "$(BLUE)Building release APK...$(NC)"
	@# Load environment variables from .env file
	@if [ -f .env ]; then \
		echo "$(YELLOW)Loading environment variables from .env file...$(NC)"; \
		export $$(grep -v '^#' .env | grep -v '^$$' | xargs); \
	fi; \
	if [ -z "$$ACCESS_TOKEN" ]; then \
		echo "$(YELLOW)Warning: ACCESS_TOKEN not set. Mapbox features will not work.$(NC)"; \
	else \
		echo "$(GREEN)ACCESS_TOKEN found$(NC)"; \
	fi; \
	if [ -z "$$SUPABASE_URL" ]; then \
		echo "$(YELLOW)Warning: SUPABASE_URL not set. Supabase features will not work.$(NC)"; \
	else \
		echo "$(GREEN)SUPABASE_URL found$(NC)"; \
	fi; \
	if [ -z "$$SUPABASE_ANON_KEY" ]; then \
		echo "$(YELLOW)Warning: SUPABASE_ANON_KEY not set. Supabase features will not work.$(NC)"; \
	else \
		echo "$(GREEN)SUPABASE_ANON_KEY found$(NC)"; \
	fi; \
	DART_DEFINES=""; \
	if [ -n "$$ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define ACCESS_TOKEN=$$ACCESS_TOKEN"; \
	fi; \
	if [ -n "$$SUPABASE_URL" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_URL=$$SUPABASE_URL"; \
	fi; \
	if [ -n "$$SUPABASE_ANON_KEY" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_ANON_KEY=$$SUPABASE_ANON_KEY"; \
	fi; \
	if [ -n "$$MAPBOX_ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define MAPBOX_ACCESS_TOKEN=$$MAPBOX_ACCESS_TOKEN"; \
	fi; \
	$(FLUTTER) build apk --release $$DART_DEFINES
	@echo "$(GREEN)Release APK built at: build/app/outputs/flutter-apk/app-release.apk$(NC)"

build-apk-split: get ## Build release APK (split by ABI)
	@echo "$(BLUE)Building release APK (split by ABI)...$(NC)"
	@# Load environment variables from .env file
	@if [ -f .env ]; then \
		export $$(grep -v '^#' .env | grep -v '^$$' | xargs); \
	fi; \
	DART_DEFINES=""; \
	if [ -n "$$ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define ACCESS_TOKEN=$$ACCESS_TOKEN"; \
	fi; \
	if [ -n "$$SUPABASE_URL" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_URL=$$SUPABASE_URL"; \
	fi; \
	if [ -n "$$SUPABASE_ANON_KEY" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_ANON_KEY=$$SUPABASE_ANON_KEY"; \
	fi; \
	if [ -n "$$MAPBOX_ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define MAPBOX_ACCESS_TOKEN=$$MAPBOX_ACCESS_TOKEN"; \
	fi; \
	$(FLUTTER) build apk --release --split-per-abi $$DART_DEFINES
	@echo "$(GREEN)Split APKs built at: build/app/outputs/flutter-apk/$(NC)"

build-appbundle: get ## Build Android App Bundle (AAB)
	@echo "$(BLUE)Building Android App Bundle...$(NC)"
	@# Load environment variables from .env file
	@if [ -f .env ]; then \
		export $$(grep -v '^#' .env | grep -v '^$$' | xargs); \
	fi; \
	DART_DEFINES=""; \
	if [ -n "$$ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define ACCESS_TOKEN=$$ACCESS_TOKEN"; \
	fi; \
	if [ -n "$$SUPABASE_URL" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_URL=$$SUPABASE_URL"; \
	fi; \
	if [ -n "$$SUPABASE_ANON_KEY" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define SUPABASE_ANON_KEY=$$SUPABASE_ANON_KEY"; \
	fi; \
	if [ -n "$$MAPBOX_ACCESS_TOKEN" ]; then \
		DART_DEFINES="$$DART_DEFINES --dart-define MAPBOX_ACCESS_TOKEN=$$MAPBOX_ACCESS_TOKEN"; \
	fi; \
	$(FLUTTER) build appbundle --release $$DART_DEFINES
	@echo "$(GREEN)App Bundle built at: build/app/outputs/bundle/release/app-release.aab$(NC)"

# Installation commands
install: build-apk-release ## Build and install release APK on connected device
	@echo "$(BLUE)Installing release APK...$(NC)"
	adb install -r build/app/outputs/flutter-apk/app-release.apk
	@echo "$(GREEN)APK installed successfully$(NC)"

install-debug: build-apk ## Build and install debug APK on connected device
	@echo "$(BLUE)Installing debug APK...$(NC)"
	adb install -r build/app/outputs/flutter-apk/app-debug.apk
	@echo "$(GREEN)Debug APK installed successfully$(NC)"

# Utility commands
check: format analyze ## Format and analyze code
	@echo "$(GREEN)Code check complete$(NC)"

pre-commit: clean get format analyze test ## Run pre-commit checks (clean, format, analyze, test)
	@echo "$(GREEN)Pre-commit checks complete$(NC)"

upgrade: ## Upgrade Flutter and dependencies
	@echo "$(BLUE)Upgrading Flutter...$(NC)"
	$(FLUTTER) upgrade
	@echo "$(BLUE)Upgrading dependencies...$(NC)"
	$(FLUTTER) pub upgrade

downgrade: ## Downgrade Flutter dependencies
	@echo "$(BLUE)Downgrading dependencies...$(NC)"
	$(FLUTTER) pub downgrade

outdated: ## Check for outdated dependencies
	@echo "$(BLUE)Checking for outdated dependencies...$(NC)"
	$(FLUTTER) pub outdated

# Development workflow
dev: clean get run ## Clean, get dependencies, and run (development workflow)

rebuild: clean get build-apk-release ## Clean, get dependencies, and build release APK

sync-env: ## Sync Mapbox token from .env to android/local.properties
	@echo "$(BLUE)Syncing Mapbox token from .env to local.properties...$(NC)"
	@if [ -f "scripts/sync-env-to-local.sh" ]; then \
		./scripts/sync-env-to-local.sh; \
	else \
		echo "$(YELLOW)Script not found. Please manually copy MAPBOX_SDK_REGISTRY_TOKEN from .env to android/local.properties$(NC)"; \
	fi

# APK location shortcuts
apk-debug: build-apk ## Alias for build-apk
	@echo "$(GREEN)Debug APK: build/app/outputs/flutter-apk/app-debug.apk$(NC)"

apk-release: build-apk-release ## Alias for build-apk-release
	@echo "$(GREEN)Release APK: build/app/outputs/flutter-apk/app-release.apk$(NC)"

# Show APK info
apk-info: ## Show APK file sizes and locations
	@echo "$(BLUE)APK Information:$(NC)"
	@if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then \
		echo "$(GREEN)Debug APK:$(NC) build/app/outputs/flutter-apk/app-debug.apk"; \
		ls -lh build/app/outputs/flutter-apk/app-debug.apk | awk '{print "  Size: " $$5}'; \
	fi
	@if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then \
		echo "$(GREEN)Release APK:$(NC) build/app/outputs/flutter-apk/app-release.apk"; \
		ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print "  Size: " $$5}'; \
	fi

# Quick commands
q: run ## Quick run (alias)
r: run-dev ## Quick run dev (alias)
b: build-apk-release ## Quick build (alias)

