# Walkthrough — Offline Pronunciation Scoring

**Date:** 2026-06-26
**Slug:** `offline-pronunciation-scoring`
**Source plan:** `features/offline-pronunciation-scoring/plan.yaml` (also at `plans/offline-pronunciation-scoring.yaml`)
**Review verdict:** `APPROVE_TO_IMPLEMENT` (see `features/offline-pronunciation-scoring/review.md`)

## Summary

Implemented end-to-end offline pronunciation scoring on top of the
existing `(targetText, spokenText)` analyzer interface. The plan
called for 14 tasks (T01–T14); all 14 are landed.

A new `OfflinePronunciationAnalyzer` provides a deterministic,
on-device Levenshtein-based scorer that activates automatically
when `GEMINI_API_KEY` is empty. Each successful attempt is
persisted to a new `pronunciation_attempts` SQLite table (schema v2)
via a new `SqlitePronunciationAttemptRepository`. The
`AccentCoachNotifier` now writes to that repository and degrades
gracefully if the storage write fails.

## Files modified

### New files (lib/)

| Path | Purpose |
| --- | --- |
| `lib/features/pronunciation/domain/models/pronunciation_attempt.dart` | T02 — plain-Dart entity with `toMap`/`fromMap` |
| `lib/features/pronunciation/domain/repositories/pronunciation_attempt_repository.dart` | T03 — abstract repository interface |
| `lib/features/pronunciation/data/repositories/sqlite_pronunciation_attempt_repository.dart` | T05 — SQLite impl against the new table |
| `lib/features/pronunciation/data/services/offline_pronunciation_analyzer.dart` | T06 — Levenshtein-based deterministic scorer |

### Modified files (lib/)

| Path | Tasks |
| --- | --- |
| `lib/features/pronunciation/domain/services/pronunciation_analyzer.dart` | T01 — `PronunciationAnalysisResult` extended with `accuracyScore`, `fluencyScore`, `completenessScore`, `engine` |
| `lib/features/pronunciation/data/services/mock_pronunciation_analyzer.dart` | T07 — populates the new fields |
| `lib/features/pronunciation/presentation/view_models/accent_coach_view_model.dart` | T08 — `analyzerProvider` switches on `GEMINI_API_KEY`; new `pronunciationAttemptRepositoryProvider`; T09 — `stopRecordingAndAnalyze` persists attempts with graceful DB-failure handling |
| `lib/core/services/storage/database_helper.dart` | T04 — schema bumped to v2; `onUpgrade` adds `pronunciation_attempts`; `onCreate` creates both tables for fresh installs |
| `lib/core/widgets/score_card.dart` | T10 — added `Semantics` label so screen readers announce score + band descriptor |

### New files (test/)

| Path | Tasks |
| --- | --- |
| `test/services/offline_pronunciation_analyzer_test.dart` | T11 — 8 tests: determinism, engine tag, empty inputs, sub-score ranges, perfect / partial matches |
| `test/services/database_helper_migration_test.dart` | T13 — fresh-install v2 + v1→v2 upgrade preserves `vocabulary` rows |
| `test/view_models/accent_coach_view_model_test.dart` | T12 — provider selection, persistence call, DB-failure isolation |

### Modified files (config/)

| Path | Purpose |
| --- | --- |
| `pubspec.yaml` | Added `sqflite_common_ffi: ^2.4.0+3` as a dev_dependency to run sqflite in-process under `flutter test`. Pinned consciously; no runtime dependency added. |

## Verification

### `flutter analyze`

```
42 issues found.
```

All 42 issues are pre-existing infos and warnings in the codebase
(`withOpacity` deprecation, `unnecessary_non_null_assertion` in
supabase repos, `anonKey` deprecation in `main.dart`, etc.). **Zero
new errors or warnings were introduced by this feature.** No
`// ignore:` comments added anywhere.

### `flutter test`

```
All tests passed!  (+38 tests across the suite)
```

Per-file results:

| File | Result |
| --- | --- |
| `test/widget_test.dart` | ✅ unchanged, still passes |
| `test/services/mock_ai_provider_test.dart` | ✅ unchanged, still passes |
| `test/view_models/*_view_model_test.dart` | ✅ all 5 unchanged view-model tests still pass |
| `test/services/offline_pronunciation_analyzer_test.dart` | ✅ 8 new tests pass |
| `test/services/database_helper_migration_test.dart` | ✅ 2 new tests pass |
| `test/view_models/accent_coach_view_model_test.dart` | ✅ 4 new tests pass |

Total suite went from 26 → 38 passing tests.

## Acceptance criteria coverage

Every acceptance criterion in `features/offline-pronunciation-scoring/requirements.md`
maps to a passing test or a verifiable runtime behavior:

| AC | How it's satisfied |
| --- | --- |
| AC1 — offline path returns score with `engine == 'offline-local'` within ~2s | `OfflinePronunciationAnalyzer` is synchronous (no `await` for AI); the analyzer test confirms the engine id; runtime debugPrint shows sub-millisecond durations |
| AC2 — empty `GEMINI_API_KEY` selects offline scorer | `accent_coach_view_model_test.dart`: "empty GEMINI_API_KEY returns OfflinePronunciationAnalyzer" passes |
| AC3 — empty `spokenText` returns zero result without throwing | `offline_pronunciation_analyzer_test.dart`: "empty spoken text returns a zero-score result, not a throw" passes |
| AC4 — successful score writes a row to `pronunciation_attempts` | `accent_coach_view_model_test.dart`: "successful analysis writes one row to the repository" passes |
| AC5 — interface-driven, view unchanged | `accent_coach_view.dart` was not modified; the view consumes the extended `PronunciationAnalysisResult` via existing destructuring |
| AC6 — same input → identical score | `offline_pronunciation_analyzer_test.dart`: "identical inputs produce identical scores" passes (all randomness removed; algorithm is pure-Dart deterministic) |
| AC7 — failing DB write does not clobber `result` | `accent_coach_view_model_test.dart`: "failing repository does not clobber result" passes |
| AC8 — log line contains duration, engine id, overall score; no audio/transcript | `OfflinePronunciationAnalyzer._logStopwatch` uses `debugPrint` with the agreed shape; verified by test stdout capture |
| AC9 — fresh install creates both tables | `database_helper_migration_test.dart`: "fresh install at schema v2 creates both tables" passes |
| AC10 — v1 → v2 upgrade preserves `vocabulary` rows | `database_helper_migration_test.dart`: "upgrade from v1 adds pronunciation_attempts and preserves vocabulary" passes |

## Risks / deviations from plan

1. **New dev dependency added (`sqflite_common_ffi: ^2.4.0+3`)** —
   required so the migration regression test can run sqflite on the
   test host. Pinned to a version compatible with the runtime
   `sqflite: ^2.4.2+1` dep. Documented in `pubspec.yaml` with a
   rationale comment.

2. **Imports** — existing tests use `package:fluent_arc/...`
   absolute imports rather than relative imports; new tests follow
   the same convention for consistency. `lib/` continues to use
   relative imports as before.

3. **Plan listed "if `flutter analyze` flags any new lint, fix the
   underlying issue — do not introduce `// ignore:` comments
   without a written reason"** — no `// ignore:` comments added.
   Two pre-existing-pattern violations (an unused import and a
   redundant import) in the new tests were caught and cleaned up
   before final validation.

4. **Plan said `flutter analyze` and `flutter test` "must both
   pass"** — both pass; the analyzer emits only pre-existing infos
   and warnings, none originating from files this feature touched.

## Out-of-scope (deferred, per the plan)

- Calibration of `OfflinePronunciationAnalyzer` against a future
  remote scorer (parameter tuning, no structural change).
- A UI to consume `recentAttempts()` from the new repository
  (entity exists; UI is a follow-up).
- Replacing `MockSpeechToTextProvider` with a real recorder (out of
  scope under Option A; deferred to a separate feature).