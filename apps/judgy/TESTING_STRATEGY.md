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

## 4. Continuous Integration (CI)
- Tests should be run on PR submission and merges to `main` via GitHub Actions.
- Command: `flutter test` for standard tests.
