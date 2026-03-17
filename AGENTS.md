# Agent Rules

- **Commit Policy**: You must fully tested all code before commmiting. Do not commit changes automatically. Wait for the user to review and ask for a commit.
- **Code Style**: Prefer modern Dart syntax.
- **Testing**: Code should be designed to be testable (dependency injection, pure functions where possible).
- **Git**: Prefer `git add [file]` over `git add .` to ensure atomic and precise commits. Never run a command that wipes out uncommited work. No `git reset --hard` unless explicitly asked.
- **Pre-commit**: Before every `git commit`, run `pre-commit run` (without `--all-files`) so hooks only process staged files. Re-stage any files modified by the hooks, then commit. This avoids failed commits from hook violations.
- **File Safety**: DO NOT forcefully delete files (e.g. `rm -f`, `git rm -f`). If a file is in the way or causing issues, ask the user or use safer alternatives (e.g. moving/renaming or unstaging).
- **Engine Dependencies**: Engine files (`lib/engine/`) must avoid Flutter-specific imports (e.g., `flutter/foundation.dart`) to ensure CLI tools and pure Dart tests can run. Use `package:meta` and `package:collection`.
- **Test Naming**: Tests for a file `name.dart` should be named `name_test.dart` and located in the corresponding directory in `test/`.
