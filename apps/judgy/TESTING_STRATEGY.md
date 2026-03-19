# Testing Strategy for Judgy

## 1. Overview
The testing strategy for Judgy involves a multi-tiered approach focused on maximizing reliability and rapid iteration. We utilize Flutter's built-in testing capabilities along with community-standard mocking tools to ensure stability across unit, UI, and integration layers.

## 2. Testing Layers

### Unit Tests (`test/`)
**Goal:** Verify the business logic and state management in isolation.
- **Scope:** Services, Models, and Providers.
- **Tooling:** `flutter_test` for execution, `mocktail` for mocking dependencies.
- **Approach:**
  - Inject dependencies into Services/Providers to make them testable.
  - Mock external dependencies like Firebase Authentication, Firestore, and AI Clients to ensure tests run fast and without network access.
  - Follow the naming convention: `[filename]_test.dart` mapping to files in `lib/`.

### Widget Tests (`test/ui/`)
**Goal:** Verify the functionality, layout, and interaction of reusable UI components.
- **Scope:** Core widgets used in the game (e.g., Playing Cards, Modals, Buttons).
- **Tooling:** `flutter_test` (specifically `WidgetTester`).
- **Approach:**
  - Build UI components in isolation inside a mock app context.
  - Programmatically interact with the UI (taps, drags) and assert on layout and state changes.

### Integration Tests (`integration_test/`)
**Goal:** Verify the end-to-end functionality of the application on real devices or emulators.
- **Scope:** Full app startup, user journeys (e.g., Login -> Create Game -> Play Round).
- **Tooling:** `integration_test` (Flutter SDK).
- **Approach:**
  - Run against a locally emulated environment using the Firebase Emulator Suite to mimic real backend behavior without hitting production.
  - Test critical paths: Auth flow, matchmaking, game loop.

## 3. Current Execution Checklist (from TODO.md)
We are actively implementing the following core service unit tests using `mocktail`:

- [x] auth_service_test.dart
- [x] ai_bot_service_test.dart
- [ ] analytics_service_test.dart
- [ ] consent_service_test.dart
- [ ] deck_service_test.dart
- [ ] game_loop_service_test.dart
- [ ] local_game_engine_test.dart
- [ ] matchmaking_service_test.dart
- [ ] preferences_service_test.dart
- [ ] online_game_engine_test.dart

## 4. Firebase Emulator Testing

For realistic local testing of online multiplayer features without hitting
production Firebase:

### Setup
1. Install Firebase CLI: `npm install -g firebase-tools`
2. From `apps/judgy/`, start the emulators:
   ```bash
   firebase emulators:start
   ```
3. Run the app with the emulator flag:
   ```bash
   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
   ```
4. Open the Emulator UI at `http://localhost:4000` to inspect Firestore data.

### What to Test Manually
- Create a room on one device/browser tab
- Join from another tab using the join code
- Verify real-time player list updates in the lobby
- Start game and play through a full round
- Test leaving mid-game (host transfer)
- Test joining with invalid/expired codes

### Emulator Ports
| Service    | Port |
|------------|------|
| Auth       | 9099 |
| Firestore  | 8080 |
| Emulator UI| 4000 |

## 5. Continuous Integration (CI)

Tests run automatically on PRs and pushes to `main` via GitHub Actions
(`.github/workflows/test.yml`).

### Pipeline Steps
1. **Format** — `make format` (checks `dart format`)
2. **Analyze** — `make analyze` (runs `flutter analyze`)
3. **Engine tests** — `make test-engine` (pure-Dart engine tests)
4. **Unit tests** — `make test-app-ci` (all unit/widget tests, excludes golden)
5. **Integration tests** — `make test-integration-ci` (starts Firebase Auth +
   Firestore emulators, runs `integration_test/` with
   `USE_FIREBASE_EMULATOR=true`)

### Requirements
- **Java 17** — needed by the Firebase Emulator Suite (installed via
  `actions/setup-java@v4`)
- **firebase-tools** — installed via `npm install -g firebase-tools`
- **Flutter stable** — installed via `subosito/flutter-action@v2`
