# Coding Standards

## Naming
- **Classes / types**: PascalCase. Entities end with the noun
  (`VocabularyWord`, `ChatMessage`, `GrammarReport`, `UserProgress`,
  `UserProfile`). Repositories end with `Repository`. View models end with
  `ViewModel`. Views end with `View`.
- **Files**: snake_case matching the primary class
  (`vocabulary_word.dart`, `vocabulary_view_model.dart`,
  `login_view.dart`).
- **Riverpod providers**: lowerCamelCase, descriptive suffix
  (`aiProvider`, `aiApiKeyProvider`). Provider files live alongside the
  feature they serve.
- **Folder names**: lowercase, singular, feature-scoped
  (`features/vocabulary/...`, not `features/Vocabulary/...`).

## Null Safety / Effective Dart
- Sound null safety is on (`sdk: ^3.11.0`).
- Lints come from `package:flutter_lints/flutter.yaml` via
  `analysis_options.yaml`. No additional rules are currently enabled; do
  not add lint suppressions (`// ignore:`) without a written reason in
  the code.
- Prefer `final` over `var`. Prefer composition over inheritance for
  service composition.

## Error Handling
- Data-layer failures are surfaced as thrown exceptions (e.g. `Database`
  errors, Supabase exceptions). The repository does NOT swallow them.
- View models expose state to views via `AsyncValue` (loading / data /
  error) rather than throwing into the widget tree.
- AI provider calls (`GeminiProvider`) use a try/catch around `jsonDecode`
  and fall back to a safe default payload (see
  `gemini_provider.dart:80-92` and `:117-131`). This is the established
  pattern when JSON parsing of model output fails — replicate it for any
  new structured-output AI call.
- Graceful degradation at app startup: `main.dart` catches dotenv and
  Supabase init failures and continues in offline / mock mode
  (`isBackendInitialized = false` is passed to `FluentArcApp`).
  Features must check this signal (or read whatever provider surfaces
  it) before assuming remote services are reachable.
- `debugPrint` is used for diagnostic logging — do not introduce
  `print`.

## Formatting
`dart format` is mandatory before any PR. CI / pre-commit should run
`dart format --set-exit-if-changed .` and `flutter analyze`.

## Imports
- **`lib/` uses relative imports.** See `core/config/router.dart`
  which uses `../../features/.../...`. Match this convention; do
  not introduce `package:fluent_arc/...` imports inside `lib/`
  unless an existing file already uses them.
  - Depth cheat-sheet: `presentation/view_models/<file>.dart` →
    `core/` requires four `../` segments
    (`../../../../core/services/...`). Counting from the file's
    directory: `..` = `presentation/`, `../..` = `<feature>/`,
    `../../..` = `features/`, `../../../..` = `lib/`. This is a
    common off-by-one source of `uri_does_not_exist` errors.
- **`test/` uses absolute `package:fluent_arc/...` imports.** The
  existing test files (`test/view_models/*.dart`,
  `test/services/*.dart`) all use `package:fluent_arc/...` for the
  files they import from `lib/`. Mirror this style in new tests;
  do not use relative imports in `test/`.
- Group imports: Dart core, package imports, relative imports — separated
  by blank lines.

## Adding Packages (Dev or Runtime)
Before adding any package, check `pubspec.yaml`'s `environment.sdk`
constraint. The current project pins `sdk: ^3.11.0`. A package whose
own SDK floor is higher (e.g., `sqflite_common_ffi >= 2.4.1` requires
`>=3.12.0`) will fail `flutter pub get` even if the version range
looks compatible. Pin to a version whose SDK constraint satisfies the
project's floor. The pub solver will eventually error out, but
checking proactively saves a round-trip.

## Diagnostic Logging
Use `debugPrint` from `package:flutter/foundation.dart` for any
diagnostic logging in `lib/`. Do not use `print` (caught by the
analyzer). `dart:developer.log` is acceptable in special cases but
`debugPrint` is the project-wide default — match it for consistency
even in files that are otherwise "pure Dart" (e.g.,
`OfflinePronunciationAnalyzer` is synchronous and does not import
`flutter/widgets.dart`, but it still imports
`package:flutter/foundation.dart` for `debugPrint`).

## Required Before Marking Work Done
Per `CLAUDE.md` "Critical rules":
- `flutter analyze` must pass.
- `flutter test` must pass.