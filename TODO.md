# Judgy Flutter Game Design

## Overview
A multiplayer Apples-to-Apples style mobile/web game (Adjective vs. Noun) using Flutter. We will use Firebase for the backend (Authentication, Firestore, Analytics) and Firebase AI (Vertex AI) for AI bot players. The project structure and conventions are bootstrapped from the existing template at `/Users/bramp/personal/judgy`.

## Work Breakdown Structure (TODO)

### 1. Bootstrapping
- [x] Copy the template structure from `/Users/bramp/personal/grids` to the current workspace.
- [x] Rename the package to `judgy`.
- [x] Update imports to reflect the new package name.
- [x] Ensure existing linting rules, `agents.md`, and project layout are preserved.

### 2. Firebase Setup
- [ ] Initialize Firebase (`flutterfire configure`).
- [ ] Enable Authentication providers:
  - Anonymous Login
  - Google Sign-In
  - Apple Sign-In
  - Email/Password
- [ ] Initialize Firestore Database.
- [x] Initialize Firebase Analytics.
- [ ] Setup Firebase App Check

### 3. Domain Modeling
- [x] Define `GameRoom` model.
- [x] Define `Player` model (with support for AI/bot flags).
- [x] Define `Card` model (Adjective/Noun).
- [x] Define `Round` model.
- [x] Define `GameState` model (Lobby, Dealing, JudgeSelection, PlayerPlaying, Judging, Scoring).

### 4. Core Game Logic
- [x] Implement game loop synchronized with Firestore.
- [x] Handle Deal state (randomly assigning 7 noun cards to players).
- [x] Handle Judge state (judge given an adjective, players select noun).
- [x] Handle Judging state (judge selects the winning noun).
- [x] Handle Scoring and advancing to the next round / next judge.

### 5. Matchmaking & Lobbies
- [x] Create matchmaking service.
- [x] Support private custom room codes.
- [ ] Support random public matchmaking (queuing system).

### 6. AI Integration
- [x] Implement `AIService`.
- [x] Integrate with Firebase AI (Vertex AI/LLM).
- [x] AI Logic: Select the "best", smartest, or funniest noun card from hand matching the adjective.
- [x] AI Logic: As Judge, evaluate submitted nouns and pick the winner.
- [ ] AI Personalities: Bots will have unique personalities based on the roles defined in `docs/characters.md`.
- [x] AI Character Icons: Extract character icons from `artwork/Gemini_Generated_Image_f3kt3rf3kt3rf3kt.png` to represent the AI bots in the UI.

### 7. UI Implementation
- [ ] Develop Auth screens.
- [ ] Develop Main Menu.
- [ ] Develop Lobby/Matchmaking views.
- [ ] Develop main Game Board.
  - Hand view (swipe/select cards).
  - Played cards area (hidden until everyone plays).
  - Judge selection UI.
  - Animations for card play, reveals, and scoring.

### 8. Final Polish & Analytics
- [ ] Wire up Firebase Analytics to track game completions.
- [ ] Add polish to graphics and transitions.
- [ ] Error tracking.

## Technical Decisions
- **Cards**: Classic Adjective (judge) / Noun (players) format.
- **Matchmaking**: Support for both Invite Codes and Random Queues.
- **AI Logic**: Rely on Firebase AI (LLM) to make human-like card selections.

## Misc

- [] We have some JSON models - maybe we should use https://pub.dev/packages/json_serializable
- [ ] Rewrite apps/judgy/assets/data/bots.json in terms of "what the bot is" and "how the bot is described to the other players"
- [ ] Fix consent and privacy policies
- [ ] There are various keys in the app - I wonder if they should be stored in a config - so they can be compiled into the app.
- [ ] Update our csv to use category ids
- [ ] Shrink bot avatars (apps/judgy/assets/images/bots/) with a PNG optimizer

## Testing Checklist
- [x] test/services/auth_service_test.dart (local mocktail tests)
- [x] test/services/ai_bot_service_test.dart (local mocktail tests)
- [x] test/services/analytics_service_test.dart
- [x] test/services/consent_service_test.dart
- [x] test/services/deck_service_test.dart
- [x] test/services/game_loop_service_test.dart
- [x] test/services/local_game_engine_test.dart
- [x] test/services/matchmaking_service_test.dart
- [x] test/services/preferences_service_test.dart
