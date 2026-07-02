# Compound Log

This file is appended to (never rewritten) by the Compound Agent after
each approved feature cycle. Each entry explains what was learned and
which /knowledge or /agents files were updated, so the knowledge base
carries an audit trail of why each rule exists.

Format per entry:

  ## {date} — {feature_slug}
  Lessons captured:
  - {lesson 1}
  - {lesson 2}
  Files updated:
  - {file path}: {one-line description of the change}

Entries below, newest first.

## 2026-06-26 — offline-pronunciation-scoring (work stage)

Lessons captured — distinct from the planning-stage entry above
(which covered RPV-cycle friction). These are lessons from the
implementation pass.

- **Relative-import depth from `presentation/view_models/` to
  `core/` is four `../`, not three.** Off-by-one happened in the
  work stage (caught immediately by `flutter analyze`'s
  `uri_does_not_exist`). Codified in `coding_standards.md` "Imports"
  with an explicit depth cheat-sheet so the next feature does not
  trip on it.
- **`test/` uses absolute `package:fluent_arc/...` imports; `lib/`
  uses relative.** The previous `coding_standards.md` only
  mentioned the `lib/` rule, which is misleading. The new
  convention explicitly carves out `test/` as an exception, with
  the rationale that all existing tests follow it.
- **Adding a package needs an SDK-floor check.** Asked for
  `sqflite_common_ffi: ^2.4.2`; the resolver rejected it because
  that version needs `sdk >=3.12.0` and the project pins
  `^3.11.0`. Downgraded to `^2.4.0+3`. The pub solver catches this
  but loses a round-trip. Codified in `coding_standards.md` "Adding
  Packages".
- **`debugPrint` is the project-wide default for diagnostic
  logging, even in files that are otherwise "pure Dart."** The
  coding standards doc said "`debugPrint` is used — do not
  introduce `print`" but did not address `dart:developer.log` or
  pure-Dart files. Codified: use `debugPrint` from
  `package:flutter/foundation.dart` everywhere in `lib/`.
- **The `sqflite_common_ffi` library import path is
  `package:sqflite_common_ffi/sqflite_ffi.dart`, not
  `package:sqflite_common_ffi/sqflite_common_ffi.dart`.** Caught
  only at compile time. Documented in `testing_rules.md` "Testing
  SQLite in Isolation".

Files updated:
- `knowledge/coding_standards.md`: added depth cheat-sheet under
  "Imports"; clarified that `test/` uses `package:fluent_arc/...`
  imports; added "Adding Packages" section with SDK-floor rule;
  added "Diagnostic Logging" section codifying `debugPrint` as the
  default in all of `lib/`.
- `knowledge/testing_rules.md`: added "Testing SQLite in Isolation
  (sqflite on the test host)" section with the `sqflite_ffi`
  import path, a `setUpAll` snippet, and a note that copy-pasted
  schema SQL is a drift hazard.

## 2026-06-26 — offline-pronunciation-scoring
Lessons captured:
- The Requirement Agent invented an audio pipeline (`pubspec.yaml`
  has no recording package; `MockSpeechToTextProvider` is the only
  "recorder" and it doesn't produce audio). The pre-refine-spec
  instruction "light context on what's technically feasible" was too
  weak; a feasibility scan for input sources is now an explicit step.
- The Requirement Agent invented `PronunciationScorer` and
  `PronunciationScore` parallel to the existing `PronunciationAnalyzer`
  and `PronunciationAnalysisResult`, and a parallel
  `AsyncValue<PronunciationScore>` contract that contradicts the
  codebase's sealed-style state. Both happened because the agent did
  not look for existing types / state shapes in the same feature
  before drafting. Now an explicit step.
- `knowledge/architecture.md` claims view models expose `AsyncValue`
  but the existing `AccentCoachState` does not. The doc's bullet was
  contradicting the codebase and would mislead every future agent.
  Amended with a "state shape" override section that codifies the
  actual convention ("match the neighboring feature, do not refactor
  to `AsyncValue` as part of an unrelated feature").
- `DatabaseHelper` schema versioning was undocumented. Adding a new
  persistent table requires a version bump + `onUpgrade` migration
  + regression test, but no knowledge file said so. Documented in
  `knowledge/architecture.md` under "Local persistence".
- The boundary of `lib/core/services/ai/` was undocumented. The
  Requirement Agent suggested a pronunciation switch live there; it
  should not — that directory is for the text-based `AiProvider`
  surface only. Documented in `knowledge/architecture.md` under
  "Core service boundaries".
- Two features now use the same SQLite-backed domain entity +
  repository + Riverpod provider shape (vocabulary, pronunciation
  attempts). That is a reusable pattern, not a coincidence. New
  `knowledge/feature_patterns/persistent_entity_pattern.md`.
Files updated:
- `knowledge/architecture.md`: added "State shape" override, "Local
  persistence" section, and "Core service boundaries" section.
- `agents/requirement-agent.md`: inserted a "Feasibility scan before
  drafting" step (check existing types, state shapes, provider
  locations, and real-vs-mock implementations).
- `knowledge/feature_patterns/persistent_entity_pattern.md`: new file
  documenting the SQLite-backed domain entity / repository / provider
  shape with examples from `vocabulary` and `pronunciation`.