# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

FluentArc is an AI-powered accent and fluency coaching app for non-native English speakers (pronunciation, conversation, grammar, vocabulary). Flutter app rooted at this directory (`pubspec.yaml` at repo root).

## Commands

Run from repo root.

| Task | Command |
| --- | --- |
| Get dependencies | `flutter pub get` |
| Analyze (lint + type check) | `flutter analyze` |
| Run **all** tests | `flutter test` |
| Run **a single test file** | `flutter test test/path/to/<file>_test.dart` |
| Run **a single test by name** | `flutter test --plain-name "<test name substring>"` |
| Format | `dart format .` (CI should run `dart format --set-exit-if-changed .`) |
| Run the app (debug) | `flutter run` |
| Update lockfile after `pubspec.yaml` change | `flutter pub get` |
| **Start task (adaptive)** | `/start-task "<task description>"` |
| **Work on task** | `/work-feature <slug>` |
| **Compound task** | `/compound-feature <slug>` |

`flutter analyze` and `flutter test` must both pass before a task is considered done. Never silence a lint with `// ignore:` without a written reason in the code.

## RPV pipeline (meta-layer)

This repo uses an **Adaptive RPV** pipeline dynamically routed by an orchestrator based on complexity (TINY, MEDIUM, LARGE, DEPENDENCY, UI).

- Overview: `PIPELINE.md`
- Knowledge base (read by every agent): `knowledge/` — `architecture.md`, `coding_standards.md`, `design_system.md`, `navigation.md`, `testing_rules.md`, `api_contracts.md`, `feature_patterns/`
- Agent personas: `agents/` — orchestrator, requirement, refine-spec, planner, review, work, compound
- Templates: `templates/`
- Claude Code commands: `.claude/commands/start-task.md`, `.claude/commands/new-feature.md` (legacy), `.claude/commands/work-feature.md`, `.claude/commands/compound-feature.md`
- Per-feature artifacts live at `features/<slug>/`; canonical plan copies at `plans/<slug>.yaml`
- Audit trail of knowledge-base updates: `COMPOUND_LOG.md`

**Hard rule for Claude Code in this repo:** when starting work on a task, do not start writing Dart.
1. Run `/start-task "<task description>"` and let the orchestrator classify the task.
2. If classified as **MEDIUM** or **LARGE**, wait for human approval of the generated specification and plans before running `/work-feature <slug>`.
3. If classified as **TINY**, **DEPENDENCY**, or **UI**, let the agent execute implementation and verification directly.
4. After implementation is verified, run `/compound-feature <slug>` if architectural/project lessons need to be saved.

The Compound Agent is the **only** persona allowed to write to `knowledge/` or `agents/` (except when creating new agent definitions); every other agent reads only.

## Architecture

Clean Architecture, feature-first. Each feature under `lib/features/<feature>/` is split into `domain/` (pure Dart entities + repository/service interfaces), `data/` (concrete repos hitting SQLite / Supabase / Gemini), and `presentation/` (`views/` widgets + `view_models/`). Cross-cutting concerns live in `lib/core/` — `config/` (router), `theme/` (`AppTheme`, Material 3), `services/` (`ai/`, `storage/`), `widgets/` (shared UI).

Dependency direction: `presentation → domain ← data`. Domain must not import Flutter; views must not import `sqflite`, `supabase_flutter`, or `google_generative_ai`. AI access is gated behind the `AiProvider` interface in `lib/core/services/ai/ai_provider.dart` — concrete implementations are `GeminiProvider` (real) and `MockAiProvider` (offline fallback). When `GEMINI_API_KEY` is empty the app silently falls back to mock.

`go_router` is the only router (`lib/core/config/router.dart`); use `context.go(...)` / `context.push(...)`, never raw `Navigator` for top-level navigation. New routes go in that one file.

`main.dart` loads `.env` via `flutter_dotenv`, initializes Supabase inside a `try/catch` so the app continues in offline/mock mode when keys are missing or init throws, and wraps the tree in `ProviderScope`. Features must tolerate either mode; do not assume remote calls succeed.

## State management

Riverpod (`flutter_riverpod`). Do not introduce `provider`, `bloc`, `getx`, or `hooks_riverpod`. View models expose state via `AsyncValue` (loading / data / error) — they do not throw into the widget tree.

## Tests

`mocktail` is the mocking library of record (no codegen). Mirror `lib/` under `test/`; current convention flattens view-model tests to `test/view_models/` (preserve what is there; propose a refactor if changing it). New structured-output AI calls should follow the try/`jsonDecode` fallback pattern in `lib/core/services/ai/gemini_provider.dart`.

## Active integrations

- **Gemini 1.5 Flash** (`gemini-1.5-flash`) is live for text generation, grammar review, and vocabulary suggestions. Planned bump to **Gemini 2.5 Flash** for scoring.
- **Supabase** for auth + remote storage, gated by `.env` keys (`SUPABASE_URL`, `SUPABASE_ANON_KEY`); graceful offline fallback.
- **Deepgram Nova-3** (transcription) and **ElevenLabs** (voice playback) are planned but not yet integrated.

## Critical rules

- Do not write Flutter/Dart code for a feature until the adaptive RPV pipeline has approved it (direct execution for TINY/DEPENDENCY/UI, or human approval for MEDIUM/LARGE).
- Never add packages without reading `pubspec.yaml` first; pin versions consciously.
- `flutter analyze` + `flutter test` must both pass before a task is considered done.
- The Compound Agent is the only writer of `knowledge/` and `agents/` (except when creating new agent definitions). Every other agent reads only.
- `.env` contains secrets and is gitignored — never commit it; `.env.example` lists expected keys.

## Active plan

None. See `ai_specs/` for upcoming spec drafts and `PIPELINE.md` for the workflow that will produce per-feature plans into `plans/<slug>.yaml`.