# Apples (Working Title: Judgy)

An Apples to Apples inspired multiplayer card game built with Flutter and Firebase, featuring AI bot personalities.

## Project Structure

This repository is structured as a monorepo containing the main game application, shared game data, artwork, and documentation.

### Rough Layout

* **`apps/judgy/`**: The main Flutter game application codebase. It includes the application UI, state management, game logic, and services (like the AI bot service).
* **`artwork/`**: Visual assets, designs, and game artwork.
* **`data/`**: Raw game data in CSV format (e.g., `adjectives.csv` and `nouns.csv` for the game cards).
* **`docs/`**: Project documentation, such as `characters.md` detailing the AI bot personalities.
* **`AGENTS.md`**: Rules and instructions for AI coding agents working within this repository.
* **`DESIGN.md`**: Architecture and game design decisions.
* **`TODO.md`**: Master list of planned features, bugs, and tasks.

## Getting Started

To run the main application:

```bash
cd apps/judgy
flutter pub get
flutter run
```

For more specific details on setting up native platforms and Firebase configurations, see the app-specific README at [`apps/judgy/README.md`](apps/judgy/README.md).
