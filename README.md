# Grids

"Grids" is an interactive, grid-based puzzle game inspired by Taiji and The Witness. Built cross-platform with Flutter using modern, strict Dart testing environments and `provider` state management.

## Documentation

* [Game Design Document](docs/game_design.md): Explains the overarching puzzle rules, how different grid mechanics work, and rule logic.
* [Architecture Design Document](docs/architecture_design.md): High-level overview of the application components and tech stack.
* [TODO Tracker](TODO.md): Track the immediate goals and task progress.

## Setup & Running

This project uses [Dart pub workspaces](https://dart.dev/tools/pub/workspaces) with Flutter.

1. Ensure you have Flutter SDK installed (3.11.0 or newer).
2. Install packages from the workspace root:

   ```bash
   flutter pub get
   ```

3. Run or deploy to your target emulator/browser:

   ```bash
   cd apps/judgy && flutter run -d chrome
   ```

   (Alternatively, use `-d macos` or an iPhone/Android emulator).

## Firebase Analytics Setup

This project uses Firebase Analytics to track puzzle solve attempts and timing. To configure it for your own Firebase project:

1. Install the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).
2. Run the configuration command in the root of the project:

   ```bash
   flutterfire configure
   ```

3. Follow the prompts to select your Firebase project and select the platforms you wish to support.
4. This will overwrite the placeholder `apps/judgy/lib/firebase_options.dart` file with your real credentials, enabling analytics to begin tracking automatically.

## Project Structure

This project uses [Dart pub workspaces](https://dart.dev/tools/pub/workspaces) to split the codebase into focused packages:

| Package | Path | Description |
|---------|------|-------------|
| `judgy` | `apps/judgy/` | Flutter app — UI, providers, services, platform dirs |
| `judgy_engine` | `packages/engine/` | Pure Dart game engine — grid logic, solver, validators, level data |
| `judgy_tools` | `packages/tools/` | CLI tools — puzzle solver, generator |

## Testing

The core engine is 100% decoupled from the UI, so it is extensively tested via unit tests. A `Makefile` provides convenient commands for running checks across all packages:

| Command | Description |
|---------|-------------|
| `make` | Run format, analyze, and all tests |
| `make format` | Format all Dart code |
| `make analyze` | Run the analyzer across all packages |
| `make test` | Run all tests (engine + app) |
| `make test-engine` | Run engine tests only (pure Dart, fast) |
| `make test-app` | Run app tests only |
| `make fix` | Apply auto-fixes from the analyzer |
| `make clean` | Delete build artifacts |

## Development

To ensure code quality and consistency, we use [pre-commit](https://pre-commit.com/) hooks. To set them up locally:

1. Install `pre-commit` (e.g., `brew install pre-commit`).
2. Install the hooks in the repository:

   ```bash
   pre-commit install
   ```

The hooks will now run automatically on every `git commit` (they delegate to the Makefile targets). You can also run them manually on all files:

```bash
pre-commit run --all-files
```

### Puzzle Solver CLI

The project includes a brute-force solver that can find all possible solutions for the levels defined in the game.

To run a summary of all levels:

```bash
cd packages/tools && dart run bin/solve.dart
```

To see all solutions for a specific level (and copy-pastable ASCII):

```bash
cd packages/tools && dart run bin/solve.dart shrine_5
```

This tool is useful for verifying puzzle uniqueness and ensuring that every level in the repository is actually solvable.
