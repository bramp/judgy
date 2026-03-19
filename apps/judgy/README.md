# Judgy

Apples to Apples inspired game.

## Project Setup

If you need to recreate the native platform folders (Android, iOS, macOS, web, etc.) to fix project references, follow these steps:

1. Delete the existing native directories (excluding `web` to preserve custom files like `privacy.html`) and recreate them using `flutter create`:
   ```bash
   rm -rf android macos ios windows linux
   flutter create --org net.bramp --project-name judgy .
   ```

2. Re-download Firebase configurations using the FlutterFire CLI:
   ```bash
   flutterfire configure
   ```

3. Recreate the native splash screens so that deleted splash images are restored:
   ```bash
   dart run flutter_native_splash:create
   ```

## Firebase AI Logic (Prompt Templates)

The bot logic utilizes Firebase AI Logic. The prompts defining the bots' personalities are deployed as **Server Prompt Templates** locally in the `prompt_templates/` directory.

Since Firebase's AI Logic is currently in preview, the Firebase CLI doesn't yet have native commands to wrap these deployments (`firebase deploy --only templates` is not yet a thing).

### How to push templates:

**Option 1: Deploy manually via console (Recommended)**
1. Navigate to your Firebase project console.
2. Go to **Build -> AI Logic -> Prompt Templates**.
3. Create new templates named `bot-select-noun` and `bot-judge`.
4. Copy the contents of the `.yaml` files in `prompt_templates/` into the editor.

**Option 2: Use the REST API helper script**
If you have the `gcloud` CLI installed and authenticated to your project:
```bash
cd apps/judgy
./scripts/push_prompt_templates.sh
```
*Note: Because the API is in preview, the REST API payload requirements might change. Using the Console UI is currently the most stable approach.*

## Sync Card Data From Google Sheets

Use the helper script below to export the first 4 visible tabs from the shared sheet into CSV files in `assets/data/`.

```bash
cd ../..
./scripts/fetch_sheet_tabs.sh
```

Requirements:
- `gws` (Google Workspace CLI)
- `jq`

Optional mapping (for exact filenames):

```bash
./scripts/fetch_sheet_tabs.sh \
   --map "Nouns=nouns.csv" \
   --map "Adjectives=adjectives.csv"
```

## Testing

### Unit Tests

Run all unit tests (no Firebase or network required):

```bash
cd apps/judgy
flutter test
```

Tests use `mocktail` to mock all Firebase dependencies. Key test files:

| File | Coverage |
|------|----------|
| `test/services/online_game_engine_test.dart` | Online game lifecycle (21 tests) |
| `test/services/matchmaking_service_test.dart` | Room creation, joining, validation |
| `test/services/local_game_engine_test.dart` | Local single-device game flow |
| `test/services/auth_service_test.dart` | Authentication methods |
| `test/services/deck_service_test.dart` | CSV parsing and category filtering |

### Firebase Emulator Testing

For manual testing of online multiplayer without hitting production Firebase:

1. Install Firebase CLI (if not already):
   ```bash
   npm install -g firebase-tools
   ```

2. Start the emulators from `apps/judgy/`:
   ```bash
   firebase emulators:start
   ```

3. Run the app with the emulator flag:
   ```bash
   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
   ```

4. Open the Emulator UI at http://localhost:4000 to inspect Firestore data and Auth state.

#### Emulator Ports

| Service     | Port |
|-------------|------|
| Auth        | 9099 |
| Firestore   | 8080 |
| Emulator UI | 4000 |

#### Manual Test Scenarios

- **Create a room** on one device/browser tab, verify the join code appears
- **Join from another tab** using the code, verify the player list updates in real-time
- **Start the game** as host, verify cards are dealt and the round begins
- **Play through a full round**: submit cards, judge selects winner, advance to next round
- **Leave mid-game** as host, verify host transfers to remaining player
- **Join with invalid code**, verify error feedback

### CI

All tests run automatically on PRs and pushes to `main` via GitHub Actions. The
workflow (`.github/workflows/test.yml`) runs formatting, analysis, unit tests,
and integration tests (against Firebase emulators). See
`TESTING_STRATEGY.md § 5` for full details.
