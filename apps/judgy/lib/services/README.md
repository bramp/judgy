# lib/services/

Cross-cutting application services.

These handle platform concerns that sit outside the core engine: persistence,
analytics, and user preferences. Services are injected via providers and should
not import Flutter widgets.

- **analytics_service** — Event tracking (Firebase Analytics).
- **consent_service** — User consent state management.
- **preferences_service** — Local key-value preferences.
- **progress_service** — Puzzle completion progress persistence.
