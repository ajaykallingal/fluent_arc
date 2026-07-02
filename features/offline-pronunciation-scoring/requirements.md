# Feature
Offline Pronunciation Scoring

# Business Goal
Give learners an immediate, network-free pronunciation score on a
spoken attempt so they can practice without an internet connection,
using the same scoring UX slot that remote scoring will later fill.

# Actors
- **Learner (signed-in or guest)** — the primary user; submits a
  spoken attempt (today: a transcript; future: audio) and receives
  a score.
- **Pronunciation feature module** — the existing UI surface
  (`AccentCoachView`) that presents a target phrase, accepts an
  attempt, and renders a score. This feature plugs into it rather
  than introducing a new screen.
- **Offline scoring engine** — a new local component that takes
  whatever input the recorder hands it (text pair today; possibly
  audio in a follow-up) and returns a score without network.
- **Configuration / `.env`** — at deploy time, decides whether
  offline scoring is enabled (so QA can A/B against remote scoring
  later). Today: `GEMINI_API_KEY` empty → offline.

# Functional Requirements
1. Reuse the existing `PronunciationAnalyzer` interface in
   `lib/features/pronunciation/domain/services/pronunciation_analyzer.dart`
   (`analyze(targetText, spokenText) → PronunciationAnalysisResult`).
   Do not introduce a parallel `PronunciationScorer` interface.
2. Extend `PronunciationAnalysisResult` with three optional numeric
   fields and an engine tag, keeping backwards-compatible defaults:
   - `accuracyScore` (0–100, integer; defaults to 100),
   - `fluencyScore` (0–100, integer; defaults to 100),
   - `completenessScore` (0–100, integer; defaults to 100),
   - `engine` (`'offline-local'` | `'remote'`; defaults to
     `'remote'`).
   `phonemeBreakdown` from the original spec is folded into the
   existing `words` list — no separate field.
3. Ship a concrete `OfflinePronunciationAnalyzer` in
   `lib/features/pronunciation/data/services/offline_pronunciation_analyzer.dart`
   implementing `PronunciationAnalyzer`. Performs scoring
   entirely on-device: no HTTP, no `GeminiProvider` call, no
   `AiProvider` call. The algorithm choice is governed by Open
   Question #1b.
4. Update the existing `analyzerProvider` in
   `lib/features/pronunciation/presentation/view_models/accent_coach_view_model.dart`
   to switch between implementations: when `GEMINI_API_KEY` is
   empty OR a future `PRONUNCIATION_OFFLINE_ONLY` flag is set,
   return `OfflinePronunciationAnalyzer`; otherwise return the
   existing mock (or a future remote one). The switch lives in the
   pronunciation feature, NOT in `lib/core/services/ai/`.
5. The existing `AccentCoachView` consumes the result via
   `AccentCoachState` (its current shape with `result`,
   `isAnalyzing`, `errorMessage`). Do NOT refactor to
   `AsyncValue<PronunciationScore>` as part of this feature —
   that's a separate cleanup. Loading / error / empty states follow
   the patterns in `knowledge/feature_patterns/` (currently empty;
   follow the widget conventions in `lib/core/widgets/`).
6. Allow the offline scorer to be replaced (e.g., a heavier on-device
   model, or a remote one) without changing call sites — interface-
   driven, no `import` of concrete classes from views.
7. Persist each score attempt to local SQLite via a new
   `pronunciation_attempts` table (see FR-12). Bump
   `DatabaseHelper` schema version from 1 to 2 with an `onUpgrade`
   migration that creates the table without dropping existing
   `vocabulary` rows. Session counter increment
   (`incrementSpeakingSession`) is unchanged.
8. Expose a Riverpod provider that returns the active
   `PronunciationAnalyzer` for the current configuration. This is
   `analyzerProvider` (already exists; being extended, not added).
9. Do not require new microphone permission changes at this layer —
   the feature assumes the existing recorder (`MockSpeechToTextProvider`
   today) already produced its output (transcript; possibly audio
   in a future). If Open Question #1a chooses the audio path, this
   requirement is dropped and the feature is split.
10. Logging: a single debug-level log line per attempt including
    duration, engine id, and overall score — no audio bytes, no
    transcripts, no PII in logs.
11. Update `MockPronunciationAnalyzer` so its returned
    `PronunciationAnalysisResult` populates the new fields with
    sensible defaults (so the score card and any dashboard widget
    don't render `null`).
12. Define a `PronunciationAttempt` domain entity in
    `lib/features/pronunciation/domain/models/pronunciation_attempt.dart`
    and a `PronunciationAttemptRepository` interface in
    `lib/features/pronunciation/domain/repositories/pronunciation_attempt_repository.dart`
    with method
    `Future<void> recordAttempt(PronunciationAttempt attempt)`.
    Ship an `SqlitePronunciationAttemptRepository` implementation
    under `lib/features/pronunciation/data/repositories/`.

# Non-Functional Requirements
- **Offline-first**: works with airplane mode on and with no AI
  credentials configured.
- **Latency**: p50 scoring latency on a mid-tier mobile device ≤ 1s
  for a target phrase ≤ 30 words.
- **Determinism**: the same `(targetText, spokenText)` + same
  algorithm version must produce the same `overallScore`,
  `accuracyScore`, `fluencyScore`, `completenessScore`. Use
  `Random(seed)` or equivalent for any randomness.
- **No new heavy native dependencies** in v1 (text-pair path). If
  the audio path is later chosen, dependencies must be justified in
  `pubspec.yaml` per the project's package rules.
- **Accessibility**: numeric scores also have a textual descriptor
  ("Excellent" / "Good" / "Needs work") for screen readers. The
  existing `ScoreCard` widget renders scores; verify it surfaces
  the textual descriptor.

# Edge Cases
1. Empty `targetText` or empty `spokenText` — return an error
   state, do not throw.
2. `spokenText` differs dramatically from `targetText` (length
   ratio outside `[0.5, 2.0]`) — return a low completeness score
   with feedback rather than a numeric crash.
3. Audio duration exceeds a configured cap (only relevant if audio
   path is chosen; default 30s) — return an error state with a
   "clip too long" message.
4. Audio sample rate / channel count differs from scorer
   expectation (only relevant if audio path is chosen) — scorer
   normalizes internally and returns a result; never silently
   mis-score.
5. Two rapid successive attempts on the same target phrase — each
   runs independently; no cross-attempt state leaks.
6. App is killed mid-scoring — the next launch shows no half-
   finished attempt; partial DB rows are rolled back or marked
   failed.
7. Storage write fails after a successful score — surface the
   error in the UI but still show the score (degrade gracefully).
8. Backend later comes online and remote scoring is preferred — the
   switch routes to the remote scorer without view changes.
9. User denies microphone permission upstream — this feature is not
   invoked (handled by the existing recorder); the scorer must not
   re-prompt.
10. `MockPronunciationAnalyzer` is removed and only the offline
    implementation remains — view model continues to render
    correctly because the type is interface-driven.

# Acceptance Criteria
1. Given the offline scorer is selected and the device is offline,
   when a learner submits an attempt, then the pronunciation view
   shows a `PronunciationAnalysisResult` with `engine ==
   'offline-local'` within 1s (p50) for target phrases ≤ 30 words.
2. Given `GEMINI_API_KEY` is empty, when a learner submits an
   attempt, then the offline scorer is selected (not the existing
   mock-remote one) and a score is returned.
3. Given an empty `spokenText`, when the scorer runs, then the
   returned state is a non-throwing error with a user-readable
   message ("No speech detected" or similar); no uncaught exception
   reaches the widget tree.
4. Given a successful score, when the attempt completes, then a
   row is written to the new `pronunciation_attempts` table in
   `fluent_arc.db` (now schema version 2) containing target
   phrase, overall score, engine id, and timestamp. Existing
   `vocabulary` rows are unaffected.
5. Given the analyzer interface, when a developer writes a new
   implementation, the existing `AccentCoachView` renders the
   result without any view-level changes.
6. Given the offline scorer is run on the same `(targetText,
   spokenText)` twice in succession, both calls return identical
   `overallScore`, `accuracyScore`, `fluencyScore`, and
   `completenessScore` values.
7. Given the local SQLite write fails, when the analyzer returns
   a valid score, then the view still renders the score and a
   non-blocking error message is surfaced — no crash.
8. Given the same scoring run, when the log line is emitted, it
   contains duration, engine id, and overall score — and does NOT
   contain raw audio bytes or transcript content.
9. Given a brand-new install (no prior `fluent_arc.db`), when the
   app starts, then `DatabaseHelper` creates both `vocabulary` and
   `pronunciation_attempts` tables without error.
10. Given an upgraded install (existing `fluent_arc.db` at schema
    version 1), when the app starts after this feature ships, then
    `DatabaseHelper.onUpgrade` adds the `pronunciation_attempts`
    table and existing `vocabulary` rows are preserved.

# Open Questions
All resolved by human on 2026-06-26.

1. **Input shape** — ✅ **Option A** (text-pair). Existing
   `(targetText, spokenText)` interface; no audio pipeline; no new
   packages.
2. **Algorithm given shape** — ✅ **Levenshtein-based heuristic**
   (T06 as planned).
3. **Accuracy target** — ✅ **Must align with eventual remote
   scorer.** V1 ships the deterministic Levenshtein scorer;
   calibration against the future remote scorer is a follow-up
   tuning task (does not change call sites because the engine is
   versioned and `engine` is recorded per attempt).
4. **Selection policy** — ✅ **Offline wins when `GEMINI_API_KEY`
   is empty** (T08 as planned). No additional user setting or env
   flag.
5. **Score history retention UI** — ✅ **No UI distinction
   required.** The `engine` column is still recorded on every
   attempt for future use, but no UI consumer is in scope for this
   feature.
6. **Recorder upgrade** — ✅ **Not applicable** under Option A.
   `MockSpeechToTextProvider` is unchanged.

No further product decisions block implementation.

# Refinement Findings
See `refine_spec_findings.md` for the full review. Key applied
changes: reused the existing `PronunciationAnalyzer` interface and
its `PronunciationAnalysisResult` type (extended, not replaced);
selection switch lives in the pronunciation feature rather than
`core/services/ai/`; SQLite bumped to schema version 2 with an
`onUpgrade` migration adding `pronunciation_attempts`. The
input-shape question (audio vs text-pair) is the most consequential
open item and must be answered by a human before planning proceeds.