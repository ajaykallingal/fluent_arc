# Refine-Spec Findings: Offline Pronunciation Scoring

## Blocking

### B1. The spec assumes audio input; the codebase has no audio pipeline
- **Finding.** Requirements #1 ("recorded audio buffer (PCM or file
  path)"), FR-9 ("existing recorder already captured audio"), and
  acceptance criteria #1, #3, #8 all assume the system can hand the
  scorer an audio buffer or path. But:
  - The existing `PronunciationAnalyzer.analyze(targetText,
    spokenText)` interface operates on a transcript pair — there is
    no audio in the data flow at all.
  - The current "recorder" is `MockSpeechToTextProvider`, which
    exposes a `setSimulatedTranscript` method. There is no real audio
    capture. `MockPronunciationAnalyzer` doesn't consume audio either
    — it does word-set diff on text.
  - `pubspec.yaml` has no recording or audio-decoding package
    (`record`, `flutter_sound`, `opus_dart`, `ffmpeg_kit_flutter`,
    etc.). The Flutter SDK alone cannot read raw PCM from the mic on
    iOS/Android.
  - `MockSpeechToTextProvider` doesn't expose an audio buffer; only a
    transcript.
- **Why it blocks planning.** The interface signature the planner
  will write is undefined until we know what audio shape the scorer
  receives.
- **Proposed resolution.** Two viable paths:
  1. Keep the existing `(targetText, spokenText)` text-pair interface
     and call the offline scorer "offline pronunciation scoring" in
     the sense of "no AI provider call, deterministic, on-device
     scoring of the transcribed text." This matches the current
     architecture; no audio dependencies are needed; v1 ships today.
  2. Add a real audio pipeline: introduce `record` (or similar),
     persist audio clips to a temp file, pass a file path into the
     scorer. This is a much bigger scope change (mic permission
     handling, audio format negotiation, clip storage, iOS/Android
     platform plumbing).
  This is a **product decision** (which path v1 should take). The
  Refine-Spec Agent cannot decide it — escalated to Open Questions.

### B2. SQLite schema migration is not in place
- **Finding.** Requirement #7 ("persist each score attempt to the
  local SQLite store") and acceptance criterion #4 ("a row is written
  to the local SQLite store containing target phrase, engine id,
  overall score, timestamp") both require per-attempt persistence.
  But:
  - `DatabaseHelper` is at version 1 and only contains the
    `vocabulary` table (`vocabulary`, `definition`, `example`,
    `difficulty`, `addedAt`). There is no `pronunciation_attempts`
    table and no migration scaffolding.
  - The existing `ProgressRepository.incrementSpeakingSession`
    only bumps a session counter; it does not capture per-attempt
    detail (engine id, target phrase, overall score).
- **Why it blocks planning.** Writing the new table requires a schema
  migration and a new repository — both should be planned, not
  improvised.
- **Proposed resolution.** Bump `DatabaseHelper` to version 2 with an
  `onUpgrade` migration that adds a `pronunciation_attempts` table
  (`id`, `targetPhrase`, `overallScore`, `accuracyScore`,
  `fluencyScore`, `completenessScore`, `engine`, `attemptedAt`). Add
  a `PronunciationAttemptRepository` in
  `lib/features/pronunciation/data/repositories/` and expose it via
  Riverpod. The session counter increment stays unchanged. **This is
  a fact-derivable change** and has been applied to requirements.md
  directly.

### B3. The spec defines a new result type that conflicts with the
  existing one
- **Finding.** The spec introduces `PronunciationScore` with
  `overallScore`, `accuracyScore`, `fluencyScore`,
  `completenessScore`, `phonemeBreakdown`, `feedback`, `engine`. The
  existing `PronunciationAnalysisResult` exposes `overallScore`,
  `words` (per-word with `score` + `feedback`), and
  `generalFeedback`. The view model `AccentCoachState` holds
  `result: PronunciationAnalysisResult?`. Replacing or renaming the
  existing type would touch every pronunciation view, the dashboard,
  any progress chart that reads overall score, and tests.
- **Why it blocks planning.** The planner cannot decide whether to
  (a) extend `PronunciationAnalysisResult` with the new fields
  (and treat `accuracyScore`/`fluencyScore`/`completenessScore` as
  optional), (b) replace it, or (c) co-exist (new type alongside).
- **Proposed resolution.** Extend the existing
  `PronunciationAnalysisResult` with optional `accuracyScore`,
  `fluencyScore`, `completenessScore`, and `engine` fields
  (defaulting to `'remote'` or empty for backwards compat). The
  per-word list maps cleanly onto the existing `words` field; do not
  introduce a separate `phonemeBreakdown`. **This is a
  fact-derivable change** and has been applied to requirements.md
  directly.

## Should-Resolve

### S1. `PronunciationScorer` interface conflicts with existing
  `PronunciationAnalyzer`
- **Finding.** FR-1 calls for a new `PronunciationScorer` interface.
  The existing `PronunciationAnalyzer` interface in
  `lib/features/pronunciation/domain/services/pronunciation_analyzer.dart`
  already exists and is implemented by `MockPronunciationAnalyzer`.
  The Riverpod provider `analyzerProvider` already returns a
  `Provider<PronunciationAnalyzer>`. Adding a parallel `scorerProvider`
  will create two interfaces for the same job, with no obvious
  migration path.
- **Resolution.** Reuse `PronunciationAnalyzer` as the abstraction;
  it is already in place. The new offline implementation lives at
  `lib/features/pronunciation/data/services/offline_pronunciation_analyzer.dart`
  and implements `PronunciationAnalyzer`. `analyzerProvider` switches
  between `MockPronunciationAnalyzer`, `OfflinePronunciationAnalyzer`,
  or a future remote one. **Applied to requirements.md directly.**

### S2. View model state shape: spec says `AsyncValue<PronunciationScore>`
  but current state is sealed
- **Finding.** Requirement #5 says the view consumes
  `AsyncValue<PronunciationScore>`. The actual
  `AccentCoachNotifier` exposes `AccentCoachState` with
  `result: PronunciationAnalysisResult?`, `isAnalyzing: bool`,
  `errorMessage: String?` — not an `AsyncValue`. The architecture doc
  states "view models expose state via `AsyncValue` (loading / data /
  error)", but the codebase itself does not follow this — it uses
  sealed states with explicit boolean flags.
- **Resolution.** Match the codebase, not the architecture doc:
  continue using `AccentCoachState` with `result`, `isAnalyzing`,
  `errorMessage`. Do not refactor to `AsyncValue` as part of this
  feature — that's a separate cleanup. **Applied to requirements.md
  directly.**

### S3. Selection switch location
- **Finding.** FR-4 says "gate selection between offline and remote
  scoring behind a single provider switch in `lib/core/services/ai/`
  or a sibling location." But `lib/core/services/ai/` is for AI text
  generation (`AiProvider`), not for pronunciation scoring — mixing
  the two would muddle that abstraction.
- **Resolution.** Add the switch in the pronunciation feature itself:
  the `analyzerProvider` already lives at
  `lib/features/pronunciation/presentation/view_models/accent_coach_view_model.dart`.
  Select based on `GEMINI_API_KEY` (empty → offline) and/or a config
  flag. **Applied to requirements.md directly.**

### S4. Microphone permission is upstream
- **Finding.** FR-9 says "do not require microphone permission changes
  at this layer — the feature assumes the existing recorder already
  captured audio." That is consistent with the codebase today
  (recording is mocked). However, if the resolution chosen for B1 is
  path (2) — real audio capture — then this requirement becomes
  false and mic permission must be added. Flagged here so the
  planner doesn't drop this requirement without thinking.
- **Resolution.** Conditional: only valid if B1 path (1) (text-pair)
  is chosen. Otherwise, defer the whole feature or split into a
  follow-up that adds audio capture first.

### S5. Open question on scoring algorithm depends on B1
- **Finding.** Open Question #1 ("which on-device approach is
  acceptable for v1") is meaningless if B1 path (1) is taken — the
  algorithm becomes a deterministic on-device word/text scoring
  function, not a phoneme model.
- **Resolution.** Reformulate as: "Given the chosen input shape
  (text-pair vs audio), which scoring heuristic is acceptable?"
  Linked to the new B1 question.

## Minor

### M1. Result type extension affects `MockPronunciationAnalyzer`
- The existing mock returns random scores in `[86, 99]` / `[35, 55]`.
  When `accuracyScore`/`fluencyScore`/`completenessScore` are added
  with sensible defaults, the mock should populate them too so the
  dashboard or score card renders without `null`. Add a note in
  requirements.

### M2. Score-card widget already exists
- `lib/core/widgets/score_card.dart` exists. The planner should use
  it; do not introduce a new score widget. (Verified by file
  listing.)

### M3. Logging guidance already lives in `MockAiProvider`
- The logging requirement (FR-10) should use the same debug-level
  pattern; no new logger package is needed.

## Spec Changes Applied Directly

The following changes were folded into `requirements.md` because
each is a fact derivable from the codebase:

1. **FR-1 / FR-2 / FR-3 unified under existing `PronunciationAnalyzer`.**
   Removed the new `PronunciationScorer` interface and `PronunciationScore`
   value object — instead reuse `PronunciationAnalyzer` and extend
   `PronunciationAnalysisResult` with `accuracyScore`, `fluencyScore`,
   `completenessScore`, and `engine` (with backwards-compatible
   defaults). Rationale: a parallel interface with no callers is dead
   weight; the existing one is already wired into the view model and
   the Riverpod graph.

2. **FR-5 / FR-6 reframed.** Removed the `AsyncValue<PronunciationScore>`
   contract. The current `AccentCoachState` uses sealed-style state
   with `isAnalyzing` / `errorMessage` flags and that is what the
   planner will match. Refactoring to `AsyncValue` is out of scope
   for this feature.

3. **FR-4 reframed.** Selection switch lives at
   `lib/features/pronunciation/presentation/view_models/accent_coach_view_model.dart`
   (`analyzerProvider`), not in `core/services/ai/`. Rationale:
   pronunciation scoring is not part of the `AiProvider` text
   surface; co-locating the switch with the existing analyzer
   provider avoids cross-cutting changes to `core/services/ai/`.

4. **FR-7 / AC-4 expanded.** Bump `DatabaseHelper` schema version to
   2 and add a `pronunciation_attempts` table. Rationale: there is no
   existing table to reuse; current schema version is 1.

5. **Open Question #1 rewritten** as two questions: (a) input shape
   (text-pair vs audio), (b) scoring heuristic given that shape.
   Rationale: these are separable product decisions and both belong
   on the human's desk.

## Escalated to Open Questions

The following findings depend on a product decision and have been
added to `requirements.md`'s Open Questions section:

- **Input shape (B1).** Should v1 operate on the existing text-pair
  `(targetText, spokenText)` interface, or should it introduce a real
  audio pipeline (mic capture, audio file path, scoring on audio)?
  - Option A (text-pair, low risk): fits current architecture, ships
    today, no new dependencies, "offline" means "no Gemini call" —
    effectively a deterministic on-device scoring of the
    already-transcribed text. Does NOT analyze audio.
  - Option B (audio, high fidelity): adds `record` (or similar) +
    iOS/Android permission plumbing, plus a much larger feature.
- **Accuracy target (existing Q2).** Unchanged — depends on whether
  v1 is a placeholder or a real scorer.
- **Algorithm given shape (rewritten from Q1).** What algorithm
  powers the offline scorer once shape is decided? For text-pair: a
  deterministic Levenshtein/diff scorer? For audio: bundled
  phoneme model vs. cloud-deferred remote with offline queue?
- **Bundle size (existing Q4).** Tied to algorithm: only relevant
  if Option B or a bundled phoneme model is chosen.
- **Selection policy (existing Q5).** When remote is later wired,
  does offline win if API key is empty (current proposal) or do we
  follow another rule?
- **Schema migration owner (existing Q6 partially resolved).**
  Who owns the SQLite version bump — `DatabaseHelper` change must
  not break the existing `vocabulary` table or its tests.