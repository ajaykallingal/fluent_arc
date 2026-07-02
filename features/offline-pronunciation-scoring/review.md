# Review: Offline Pronunciation Scoring

## Requirement Clarity
- **Open Question #1a (input shape: text-pair vs audio)** is unresolved
  and is the most consequential decision in the spec. The requirements
  document is internally consistent but assumes a shape the human has
  not picked. FR-9 ("do not require new microphone permission changes
  at this layer") is only valid if Option A (text-pair) is chosen.
- **Open Question #1b (algorithm given shape)** is unresolved but only
  blocks if Option B is chosen for #1a. The plan defaults to a
  Levenshtein-based heuristic (T06) which is a reasonable placeholder
  for Option A.
- **Open Question #3 (accuracy target)** is unresolved but is
  non-blocking: the planner ships a deterministic scorer regardless;
  accuracy alignment with a future remote scorer is a tuning task.
- **Open Question #4 (selection policy)** is unresolved but
  non-blocking: the plan defaults to "offline when `GEMINI_API_KEY` is
  empty," which is the conservative behavior and is explicitly called
  out as such.
- **Open Question #5 (history retention UI)** is unresolved but
  non-blocking for this feature — `recentAttempts` is plumbed
  (T03 / T05) so a follow-up UI can consume it.
- **Open Question #6 (recorder upgrade)** is unresolved but is only
  triggered by Open Question #1a picking Option B.
- All ten acceptance criteria are written as testable, falsifiable
  statements and map cleanly onto tasks (see Plan Soundness below).
  No vague language remains.

## Plan Soundness
- **Coverage of acceptance criteria**: every one of AC1–AC10 maps to
  at least one task in `plan.yaml`. Specifically:
  - AC1 → T06, T08, T10, T12
  - AC2 → T08, T12
  - AC3 → T06, T11
  - AC4 → T04, T05, T09, T13
  - AC5 → T08, T10
  - AC6 → T06, T11
  - AC7 → T09, T12
  - AC8 → T06
  - AC9 → T04, T13
  - AC10 → T04, T13
- **Coverage of Should-Resolve findings**: S1 (reuse existing
  analyzer) → T01, T06, T08. S2 (don't refactor to `AsyncValue`) →
  not a task; enforced by FR-5 and the absence of any AsyncValue
  refactor in the plan. S3 (selection switch location) → T08. S4
  (mic permission conditional) → FR-9 + risk note in plan. S5 (open
  question reformulated) → see Open Question #1b.
- **Tests**: T11 covers `OfflinePronunciationAnalyzer` and the
  SQLite repo; T12 covers the view-model provider switch and DB
  failure isolation; T13 covers the schema migration. T14 enforces
  the `flutter analyze` + `flutter test` gate. **No implementation
  task is missing a test.** Good.
- **Localization**: No new user-facing strings are introduced. The
  existing score-card renders numeric scores; if a textual descriptor
  is added (T10), it should be a small set of en-US strings
  (Excellent / Good / Needs work) — does not warrant a separate
  localization task at this scope. Acceptable.
- **Gaps**:
  - The plan does not include a task to verify that the
    `recentAttempts` repository method (T03/T05) has a consumer; it
    is plumbed but unused. This is intentional (it exists for the
    future history UI), but the reviewer should note that no
    downstream task depends on it. Not a blocker.
  - The plan does not include an explicit "feature flag" task for
    the offline-vs-mock switch in T08. The risk section flags this,
    but a defensive default (e.g., always require an explicit env
    var to enable offline in production) is not codified. Worth
    raising with the human — see Open Questions.

## Architecture Fit
- **Layering**: Domain entities and interfaces are pure Dart (T01,
  T02, T03). Data layer implements interfaces (T04, T05, T06, T07).
  Presentation wires up Riverpod providers and updates the existing
  view model (T08, T09, T10). No view file imports concrete
  data-layer classes directly. ✅
- **Interface reuse**: The plan correctly extends
  `PronunciationAnalyzer` and `PronunciationAnalysisResult` rather
  than introducing a parallel `PronunciationScorer`. ✅ (Per
  refine-spec finding S1.)
- **Selection switch location**: Lives in
  `lib/features/pronunciation/presentation/view_models/accent_coach_view_model.dart`
  (T08), not in `core/services/ai/`. ✅ (Per refine-spec finding S3.)
- **No `AsyncValue` refactor**: Plan explicitly preserves the existing
  sealed-style `AccentCoachState`. ✅ (Per refine-spec finding S2 and
  FR-5.)
- **Database migration**: Bumps schema version with `onUpgrade`; does
  not drop or modify the existing `vocabulary` table. ✅ (Per
  refine-spec finding B2.)
- **Error handling**: T05 lets SQLite exceptions propagate (per
  coding_standards). T09 catches them at the view-model boundary and
  sets `errorMessage` without clobbering `result`. ✅ (AC7.)
- **Logging**: Uses `debugPrint` (per coding_standards). ✅
- **Imports**: Plan uses relative imports within `lib/` per coding
  standards. ✅
- **Naming**: Classes end with entity/repository suffix per coding
  standards. Files are snake_case. ✅

## Risks
1. **Unresolved input-shape decision (Open Question #1a)** is the
   single biggest risk. The plan as written is only implementable
   if the human picks Option A (text-pair). Option B would
   invalidate T06, change T08, and require new packages.
2. **`analyzerProvider` change (T08)** is a high-blast-radius edit —
   it alters how every pronunciation attempt is scored. The plan
   notes this in its own risks section; the reviewer echoes it.
   Mitigation: ship behind an env flag, not a hard switch.
3. **SQLite schema bump (T04)** affects every upgrading user.
   Mitigation: T13 covers it, but the migration code must be
   idempotent and tested on a real v1 fixture DB.
4. **Algorithm alignment with future remote scorer (Open Question
   #3)**: the v1 offline scorer may produce systematically different
   scores than the eventual remote scorer. A learner who upgrades
   may see their progress chart shift. This is acknowledged in the
   spec; mitigation is to label the engine id prominently in the UI
   so users know what they're seeing.
5. **Coverage gap on the pronunciation feature**: the existing
   feature has thin test coverage. T11–T13 add the first tests for
   it. They should not be merged without running
   `flutter analyze` + `flutter test` on the whole project to
   confirm no regressions in unrelated features.
6. **Architectural drift on view-model state shape**: the
   architecture doc says `AsyncValue` is the convention but the
   codebase does not follow it. The plan deliberately does not
   refactor; if a follow-up feature standardizes on `AsyncValue`,
   T09 will need rework. Not a blocker.

## Open Questions for Human
**All open questions resolved by human on 2026-06-26:**

1. ✅ **Input shape** — Option A (text-pair, no audio).
2. ✅ **Algorithm** — Levenshtein-based deterministic scorer (T06).
3. ✅ **Accuracy target** — must align with eventual remote scorer;
   calibration is a follow-up tuning task (parameter change, no
   structural rework). Captured in T06's description.
4. ✅ **Selection policy** — offline wins when `GEMINI_API_KEY` is
   empty (T08).
5. ✅ **History retention UI** — no engine distinction required for
   UI in this feature; `engine` column is still recorded for future
   use.
6. ✅ **Recorder upgrade** — not applicable under Option A;
   `MockSpeechToTextProvider` is unchanged.
7. ✅ **Defensive default** — flip automatically on empty
   `GEMINI_API_KEY`; no env flag required. (A CI/build-flag
   safeguard is recommended in the plan's risks section but is not
   a hard requirement.)

**No open questions remain.**

## Verdict
APPROVE_TO_IMPLEMENT. The plan is internally consistent, fully covers
every acceptance criterion, resolves all Blocking refine-spec findings,
and all open questions have been answered. Implementation may proceed
once a human acts on this approval; per `CLAUDE.md`, the next step is
`/compound-feature offline-pronunciation-scoring`, after which the
diff to `knowledge/` and `agents/` should be reviewed before
committing.