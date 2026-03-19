.PHONY: all format analyze test test-engine test-app test-app-ci test-golden-ci fix clean run run-emulator run-player2 run-widgetbook

# Device to run on: chrome, macos, ios, android (default: chrome)
DEVICE ?= chrome
# Port for Flutter web dev server
WEB_PORT ?= 3000

# Shorthand for running commands in the app directory
APP = cd apps/judgy

## Run all checks (format, analyze, test)
all: format analyze test

## Run the app (use DEVICE=macos, DEVICE=ios, etc.)
run:
	$(APP) && flutter run -d $(DEVICE)

# Flags for the second Chrome instance (matches Flutter's Chrome launch flags)
CHROME_FLAGS = \
	--disable-extensions \
	--disable-popup-blocking \
	--no-default-browser-check \
	--no-first-run

## Run the app against Firebase emulators (opens two Chrome windows for multiplayer testing)
run-emulator:
	$(APP) && firebase emulators:exec --only auth,firestore \
		" \
		  flutter run -d chrome \
		    --web-port=$(WEB_PORT) \
		    --dart-define=USE_FIREBASE_EMULATOR=true & \
		  sleep 5; \
		  open -na 'Google Chrome' --args \
		    $(CHROME_FLAGS) \
			--user-data-dir=/tmp/judgy-player2 \
		    http://localhost:$(WEB_PORT); \
		  wait \
		"

## Run the Widgetbook background demo
run-widgetbook:
	$(APP) && flutter run -d $(DEVICE) -t tool/background_demo.dart

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
	$(APP) && flutter test

## Run app tests for CI (excludes golden/mac tests, injects build info)
test-app-ci:
	$(APP) && flutter test \
		--exclude-tags mac \
		--dart-define=COMMIT_HASH=$$(git rev-parse --short HEAD) \
		--dart-define=BUILD_DATE="$$(date -u +'%Y-%m-%d %H:%M UTC')"

## Run integration tests against Firebase emulators
test-integration-ci:
	$(APP) && firebase emulators:exec \
		--only auth,firestore \
		"flutter test integration_test/ \
		  --dart-define=USE_FIREBASE_EMULATOR=true"

### Run golden tests for CI (macOS only)
#test-golden-ci:
#	$(APP) && flutter test --tags mac

## Apply auto-fixes
fix:
	dart fix --apply

## Delete build artifacts
clean:
	$(APP) && flutter clean
