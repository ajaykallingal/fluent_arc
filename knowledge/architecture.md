# Architecture

## Pattern
Clean Architecture, feature-first. Each feature is self-contained under
`lib/features/<feature>/` and split into three layers:

- `domain/` — pure Dart entities and repository/service interfaces (no Flutter
  imports, no I/O).
- `data/` — concrete repository implementations that talk to SQLite,
  Supabase, Gemini, or other I/O backends. They depend on `domain/`.
- `presentation/` — `views/` (Widgets) and `view_models/` (Riverpod
  Notifiers).

Cross-cutting concerns live under `lib/core/`:
- `core/config/` — router setup.
- `core/theme/` — `AppTheme` (Material 3 light + dark).
- `core/services/` — shared services (AI providers, storage).
- `core/widgets/` — shared UI components (buttons, text field, score card,
  loading/error/empty views).

## State Management
Riverpod only (`flutter_riverpod: ^3.3.2`). No `Provider`, `Bloc`, or
`GetX`. The root widget is wrapped in `ProviderScope` in `main.dart`. There
is currently no use of `Notifier`/`NotifierProvider` in the code — most
view models appear to be `ChangeNotifier` (verify before assuming; flag if
you need to clarify). `flutter_riverpod` is the package of record per
`pubspec.yaml`; do not introduce `riverpod` or `hooks_riverpod` without
updating this file.

## Layer Rules
- No UI imports in `domain/`. Domain entities and repository interfaces
  must be plain Dart.
- No direct API/HTTP calls from widgets. Views call view models; view
  models call repositories.
- Repositories are the only layer that touches data sources (SQLite,
  Supabase, Gemini, etc.). Views must not import `sqflite`,
  `supabase_flutter`, or `google_generative_ai`.
- The AI provider is abstracted behind `AiProvider` (see
  `lib/core/services/ai/ai_provider.dart`). Concrete implementations are
  `GeminiProvider` (real) and `MockAiProvider` (offline fallback). Any
  feature using AI must depend on the interface, not a concrete class.

## Folder Conventions
```
lib/
├── core/
│   ├── config/      # router.dart
│   ├── services/
│   │   ├── ai/      # ai_provider.dart, gemini_provider.dart, mock_ai_provider.dart
│   │   └── storage/ # database_helper.dart
│   ├── theme/       # app_theme.dart
│   └── widgets/     # shared widgets (app_text_field, primary_button, score_card, etc.)
├── features/
│   ├── <feature>/
│   │   ├── data/repositories/
│   │   ├── domain/{models,repositories}/
│   │   └── presentation/{view_models,views}/
│   └── ...           # one folder per feature
└── main.dart
```

Feature naming observed: `auth`, `conversation`, `dashboard`, `grammar`,
`pronunciation`, `progress`, `vocabulary`. Match this style: short,
lowercase, singular noun.

## Dependency Direction
`presentation → domain ← data`. Both `presentation` and `data` depend on
`domain`. `domain` depends on nothing outside Dart core.

Concretely enforced by:
- View models expose `AsyncValue` (or similar) to views — they never
  return raw database rows.
- Repository implementations in `data/` `implements` the interface in
  `domain/repositories/`.
- The `AiProvider` interface in `core/services/ai/ai_provider.dart` is the
  only AI surface the rest of the app touches.

### State shape (IMPORTANT — overrides the bullet above)

The bullet above is the aspirational convention. **The current codebase
does not follow it for every feature.** As of 2026-06-26 the observed
convention in `lib/features/pronunciation/presentation/view_models/accent_coach_view_model.dart`
is a sealed-style state class (`AccentCoachState`) with explicit
boolean flags (`isAnalyzing`, `isListening`) and a nullable error
string — NOT `AsyncValue<T>`. New features in this codebase should
match the state shape used by their closest neighboring feature, not
the `AsyncValue` line above. The `AsyncValue` migration is a separate
cross-cutting cleanup; do not introduce it as part of an unrelated
feature.

### Local persistence (`DatabaseHelper`)

- Schema lives in `lib/core/services/storage/database_helper.dart`
  (`fluent_arc.db`). It is `sqflite`-backed and currently at schema
  version 1 with a single table (`vocabulary`).
- The `DatabaseHelper` exposes `onCreate` and `onUpgrade` callbacks.
  Adding a new persistent table requires:
  1. Bumping `version` in `_initDB`.
  2. Updating `onCreate` to create the new table for fresh installs.
  3. Adding an `onUpgrade(db, oldVersion, newVersion)` migration that
     creates the table when `oldVersion < newVersion`, so existing
     installs keep their data.
  4. A regression test on a fixture v1 → v2 upgrade.
- New features adding a persistent entity MUST follow this pattern.
  Do not open a second `sqflite` database or bypass `DatabaseHelper`.

### Core service boundaries

`lib/core/services/ai/` is reserved for the text-based `AiProvider`
surface (`generateText`, `generateChatResponse`, `analyzeGrammar`,
`suggestVocabulary`). Non-text features (pronunciation scoring,
speech-to-text, etc.) MUST NOT add providers or implementations under
`core/services/ai/`. Co-locate the feature's provider switch and
Riverpod wiring inside the feature itself
(`lib/features/<feature>/presentation/view_models/...`).