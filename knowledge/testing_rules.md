# Testing Rules

## Required Test Types Per Feature
- **Unit tests** for domain entities (pure Dart) and data-layer
  repositories (with mocked I/O backends).
- **View model tests** for presentation logic — drive Notifiers /
  `ChangeNotifier`s through their public API and assert on the emitted
  state.
- **Widget tests** for individual views where there is non-trivial UI
  logic (forms, multi-step flows). TBD — currently no widget tests for
  views exist; only the placeholder `test/widget_test.dart` shipped with
  the Flutter template.

## Existing Test Layout
```
test/
├── services/
│   └── mock_ai_provider_test.dart
├── view_models/
│   ├── auth_view_model_test.dart
│   ├── conversation_view_model_test.dart
│   ├── dashboard_view_model_test.dart
│   ├── grammar_view_model_test.dart
│   ├── progress_view_model_test.dart
│   └── vocabulary_view_model_test.dart
└── widget_test.dart
```

The convention already in use: `test/<mirror-of-source>/<file>_test.dart`.
Mirror the `lib/` structure for new tests.

## Mocking
`mocktail: ^1.0.5` is the mocking library of record (`pubspec.yaml`
`dev_dependencies`). No `mockito` or `test_mocks` codegen step is
configured — prefer `mocktail`'s runtime `Mock` classes so the build
stays codegen-free.

## Minimum Coverage Target
TBD — propose 80% line coverage for domain + data layers and 60% for
view models. Widget-test coverage should track user-visible behavior
changes. Confirm with the team before treating this as a hard gate.

## Test Folder Convention
- Mirror `lib/` under `test/`.
- `lib/features/<f>/presentation/view_models/<x>_view_model.dart` →
  `test/view_models/<x>_view_model_test.dart` (current convention
  intentionally flattens to `test/view_models/` rather than nesting by
  feature — match what is already there or propose a refactor).
- `lib/core/services/<area>/<file>.dart` →
  `test/services/<file>_test.dart`.

## Required Before Merge (per `CLAUDE.md`)
- `flutter analyze` — zero errors / warnings introduced.
- `flutter test` — all tests pass; new tests added for new behavior.

## Testing SQLite in Isolation (sqflite on the test host)

`flutter test` runs on the Dart VM on the host (macOS, Linux, etc.).
The runtime `sqflite: ^2.4.2+1` package depends on platform plugin
channels that are not available under `flutter test`, so a test
that opens the real `DatabaseHelper` directly will fail at runtime
with a missing-plugin error.

To run schema-migration and roundtrip tests in `flutter test`, add
`sqflite_common_ffi` as a `dev_dependency` (pinned to a version
compatible with the runtime `sqflite` package's SDK floor — see
`knowledge/coding_standards.md` "Adding Packages"). Then in the
test's `setUpAll`:

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
});
```

Notes:
- The import path is `package:sqflite_common_ffi/sqflite_ffi.dart`,
  not `package:sqflite_common_ffi/sqflite_common_ffi.dart`. The
  package name and the library name differ.
- To exercise the actual `DatabaseHelper` class (not just raw
  sqflite), the helper's private `_initDB` would need to accept an
  injectable `DatabaseFactory`. If a test needs that level of
  fidelity, propose a small refactor in `plan.yaml` rather than
  copy-pasting the schema SQL into the test — drift between the
  test's SQL and the helper's SQL is a real failure mode.
- For most use cases, the migration test re-creates the schema
  inline and exercises the migration SQL directly. This is good
  enough as a regression test for "v1 → v2 preserves vocabulary";
  a higher-fidelity test (driving `DatabaseHelper.openDatabase`
  end-to-end) is a follow-up if needed.