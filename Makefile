.PHONY: all format analyze test test-engine test-app test-app-ci test-golden-ci fix clean run run-widgetbook

# Device to run on: chrome, macos, ios, android (default: chrome)
DEVICE ?= chrome

## Run all checks (format, analyze, test)
all: format analyze test

## Run the app (use DEVICE=macos, DEVICE=ios, etc.)
run:
	cd apps/judgy && flutter run -d $(DEVICE)

## Run the Widgetbook background demo
run-widgetbook:
	cd apps/judgy && flutter run -d $(DEVICE) -t tool/background_demo.dart

## Format all Dart code
format:
	dart format .

## Run the analyzer across all packages
analyze:
	flutter analyze apps/

## Run all tests
test: test-app

## Run app tests
test-app:
	cd apps/judgy && flutter test

## Run app tests for CI (excludes golden/mac tests, injects build info)
test-app-ci:
	cd apps/judgy && flutter test --exclude-tags mac \
		--dart-define=COMMIT_HASH=$$(git rev-parse --short HEAD) \
		--dart-define=BUILD_DATE="$$(date -u +'%Y-%m-%d %H:%M UTC')"

### Run golden tests for CI (macOS only)
#test-golden-ci:
#	cd apps/judgy && flutter test --tags mac

## Apply auto-fixes
fix:
	dart fix --apply

## Delete build artifacts
clean:
	cd apps/judgy && flutter clean
