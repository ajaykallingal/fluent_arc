# Pattern: Persistent Entity (SQLite)

## When to use
A feature needs to persist a small, row-shaped entity to local SQLite
and read it back later — typically for per-attempt history, per-user
saved records, or any "list of things the user has done" view. Does
NOT cover offline-first sync, complex queries, or relational data
across many tables.

## Layers involved
- **domain/models/** — plain-Dart entity with `toMap()` / `fromMap()`
  for SQLite (no Flutter imports).
- **domain/repositories/** — `abstract class XRepository` with the
  write/read methods the feature needs (`record...`, `recent...`,
  `getById...`, etc.). No Flutter imports.
- **data/repositories/** — concrete `SqliteXRepository implements XRepository`
  using `DatabaseHelper`. Lets `DatabaseException` propagate.
- **presentation/view_models/** — Riverpod provider exposing the
  repository (`xRepositoryProvider`). The view model calls
  `ref.read(xRepositoryProvider).record...(...)` at the appropriate
  moment; storage failures are caught at the view-model boundary and
  surfaced via `errorMessage` without clobbering the in-memory result.
- **test/** — roundtrip test (insert + read), plus a schema-migration
  regression test if the table is new.

## File layout
```
lib/features/<feature>/
├── domain/
│   ├── models/<entity>.dart                 # plain Dart, toMap/fromMap
│   └── repositories/<entity>_repository.dart # abstract interface
├── data/
│   └── repositories/sqlite_<entity>_repository.dart
└── presentation/view_models/<feature>_view_model.dart  # owns xRepositoryProvider

test/features/<feature>/<layer>/<file>_test.dart
```

Schema lives centrally in
`lib/core/services/storage/database_helper.dart`. Adding a new table
requires a schema-version bump + `onUpgrade` migration + a v1→v2
regression test (see `knowledge/architecture.md` "Local persistence").

## Example in this repo
- `lib/features/vocabulary/` — entity `VocabularyWord`, repository
  `VocabularyRepository` (impl in `data/repositories/`), reads from
  the existing `vocabulary` table in `DatabaseHelper` schema v1.
- `lib/features/pronunciation/` (planned by
  `features/offline-pronunciation-scoring/plan.yaml` T02–T05) —
  entity `PronunciationAttempt`, repository
  `PronunciationAttemptRepository`, requires a new
  `pronunciation_attempts` table and schema bump to v2.

## Anti-patterns
- **Don't open a second `sqflite` database** for a new feature.
  Bump `DatabaseHelper`'s schema version and add the table there.
- **Don't introduce a parallel value object** that overlaps an
  existing feature's result type. Extend the existing one (per
  finding B3 in `features/offline-pronunciation-scoring/refine_spec_findings.md`).
- **Don't swallow exceptions in the SQLite repository.** Let them
  propagate to the view model so the UI can degrade gracefully but
  not silently (per `knowledge/coding_standards.md` error handling
  rule).
- **Don't couple the repository to Riverpod.** The interface lives
  in `domain/` (no Flutter imports); the provider wiring lives in
  `presentation/view_models/`.
- **Don't add a persistence layer for transient view-model state.**
  If the data lives only for the current session and is rebuilt on
  every app launch, use a `Provider<...>` in the view model and skip
  the repository + entity.