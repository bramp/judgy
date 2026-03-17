# TODOs

## Puzzle Engine

- [x] Define immutable `GridState`.
- [x] Implement contiguous area extraction (flood-fill algorithm).
- [x] Implement `RuleValidator` interface.
- [x] Implement validation for Colored Diamonds Constraint.
- [x] Implement validation for Strict Number Areas Constraint.
- [x] Add comprehensive unit tests around the validation logic.
- [ ] Puzzle types
  - [x] Numbers, Flowers, Diamonds, Dashes, Diagonal Dashes
  - [ ] Start - end logic
- [ ] Implement different interaction styles
  - [x] Tapping toggles the state
  - [ ] Walking puzzles
  - [ ] Cluster toggling (e.g press and all the squares around change state)

## App Setup

- [x] Setup state management (e.g., Provider/Riverpod).
- [X] Implement local persistence for user progress (unlocked levels, solutions, last played level).
- [x] Verify web builds
- [ ] Verify mobile builds

## UI / Presentation

- [x] Implement `GridWidget` for rendering interactive tiles.
- [x] Implement `CellSymbolRenderer` for numbers.
- [x] Implement `CellSymbolRenderer` for colored diamonds.
- [x] Create basic placeholder artwork/assets for the game.
- [ ] Acquire or design finalized high-quality artwork.
- [x] Build the main Game loop/screen UI.
- [x] When a unlit cell is wrong, it does not light up red.
- [x] Fix accessibility / keyboard use - space to toggle, enter to solve, left-right to switch puzzles, etc.
- [ ] When a lit square is tab focus - you can't tell
- [ ] The lit color now seems a little consistent.

## Sounds

- [ ] Add sound effects for solving puzzles.

## Backgrounds

- [x] Gaussian "Cloud" Orbs — soft, blurred color blobs that react to cell toggles.
- [x] Parallax Depth — tiny particle layer with gyroscope/mouse parallax.
- [x] Flowing Plasma Trails — smoke-like wisps that burst on cell toggle.
- [x] Matrix Data Rain — dark hex numbers falling in columns, flashing on combos.
- [x] Sound Waves — oscilloscope-style lines reacting to input.
- [x] Augmented Reality Interface (Light Theme) — thin saturated neon on white with scan-lines.
- [x] Bio-Neural Network — glowing bio-luminescent tendrils lighting up on cell toggle.
- [x] Particle Accelerator Ring — orbiting energy particles in a circular chamber.
- [x] Plasma Lightning — electrical arcs crackling across the background.
- [ ] Warp speed - stars flying towards the user.

## Backgrounds (to do later)

- [ ] Circuit Pathing — PCB-style lines with occasional light pulses.
- [ ] Ghost Layer (Light Theme) — white background with inner shadow / outer glow cells.
- [ ] Negative Glow (Light Theme) — depressed cells with color-tinted shadows.

## Future / Polish

- [ ] Level Selection screen.
- [ ] Setup Daily Challenges + Leaderboards.
- [ ] The won color is a different shade to the check answer button - fix that.
- [ ] Ensure puzzles are always displayed in the best orentation for the device.
- [x] On web, I need a cookie warning banner.
- [x] I need a privacy policy
- [x] I need a setting / about page
- [x] Move the version number to the setting / about page
- [ ] Give more screen space to the puzzle
- [X] Clicking mine puzzle -> map -> mine puzzle - lands you on mine_2 instead of mine_1
- [ ] Add a hint button
- [x] Click Drag to the right highlights the next row
- [x] Solve, but don't click solve. Go back and forward and it appears solved
- [x] If I return to a puzzle I've never cliecked "solved" on, but the solution was correct, it defaults to being highlgihted as solved.
- [ ] Colour that button correctly
- [x] Check mine_13
- [x] All the radius should match
- [x] Set android:navigationBarColor
- [ ] Make "success" more obvious.
- [x] If the puzzle is a small grid, don't make it too large - default to max size of a 4x4 for example
- [ ] Should we use shaders for the backgrounds?
- [ ] The dice with 6 or more, are too compact
- [ ] The flowers look wrong.
- [ ] Should the padlocks be bright green
- [ ] Every use of random in the code base, should optionally be passed into the class using the random generator. This is so we can have a single seed / better mockability.

## Code Audit (March 2026)

### HIGH Priority

- [x] Remove unused `rule_validator.dart` import in `lib/providers/level_provider.dart` (line 12).
- [x] Fix side-effects inside `CustomPainter.paint()` in `lib/ui/widgets/parallax_dust.dart` and `lib/ui/widgets/plasma_lightning.dart`. Both call mutation functions (`ensureParticles()`, `_tick()`) inside `paint()`. Flutter can call `paint()` multiple times per frame during layout. Move state mutations into the `State` class (e.g. animation listener or `build()`), not the painter.
- [x] Refactor `_backtrack()` in `lib/engine/solver.dart` — it takes 10 parameters. Wrap them in a `_SolveContext` class for readability and to reduce error potential.
- [x] `AreaExtractor` (`lib/engine/area_extractor.dart`) uses mutable static buffers (`_visitedBuffer`, `_queueBuffer`). Not safe if `extract()` is ever called from an isolate. Document the single-threaded constraint or switch to local allocations.

### MEDIUM Priority

- [x] `ThemeProvider` (`lib/providers/theme_provider.dart`) exposes the mutable `_themes` list directly via `availableThemes`. Return `List.unmodifiable(_themes)` or `UnmodifiableListView` instead.
- [x] `ThemeProvider` uses unnecessary `late` for `_themes` and `_activeTheme`. Both are assigned in the constructor and could be `final` fields with direct initialization.
- [x] Add `@immutable` annotation to `Level` class (`lib/engine/level.dart`) — all fields are final but the annotation is missing.
- [x] Cache `GridShape.signature` and `rotations` (`lib/engine/grid_shape.dart`) — they recompute (sort + join / generate 4 rotations) on every access. Use `late final` to compute once: `late final String signature = _computeSignature();`
- [x] `LevelRepository` (`lib/data/level_repository.dart`) exposes mutable `worldMap` (Map) and `levels` (List). Callers could accidentally modify the game data. Wrap with `Map.unmodifiable()` and `List.unmodifiable()`.
- [x] Simplify `ProgressService` (`lib/services/progress_service.dart`) methods to idiomatic Dart: `areAllLevelsSolved` → `ids.every(isLevelSolved)`, `getSolvedCount` → `ids.where(isLevelSolved).length`.

### LOW Priority

- [x] Hard-coded colors in UI: `world_map_screen.dart` uses `Color(0xFF00CC00)`, `game_bottom_bar.dart` uses `Colors.green` for solved state. Move these to the theme.
- [ ] `DashValidator` (`lib/engine/validators/dash_validator.dart`) is ~150 lines with quadruple nested loops. Extract helper methods like `_findDashesByColor()` and `_getSignaturesForColor()`.
- [ ] `GridFormat.parse()` (`lib/engine/grid_format.dart`) is 200+ lines. Extract modifier-parsing logic into a separate method.
- [ ] Missing tests for: `progress_service.dart`, `analytics_service.dart`, `preferences_service.dart`, `grid_cell_widget.dart`, `grid_widget.dart`, `game_bottom_bar.dart`, `dice_dots_widget.dart`, `gaussian_orbs.dart`, `parallax_dust.dart`, `plasma_lightning.dart`.
- [ ] Move TODO comments in level data files (`garden_levels.dart`, `mine_levels.dart`, `shrine_levels.dart`) into this file or an issue tracker.
- [ ] `consent_banner.dart` uses a `StatefulWidget` for one boolean (`_analyticsEnabled`). Could derive it directly from `ConsentService` state instead.
