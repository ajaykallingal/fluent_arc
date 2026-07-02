# Orchestration Plan: Change default Ollama model to qwen3:4b in env

## Task Classification
**Path**: TINY

## Rationale
This task is a single-line configuration change. The user wants the default Ollama model to be `qwen3:4b` instead of whatever it was previously. The change touches two locations:

1. `.env.example` — update the placeholder/default for `OLLAMA_MODEL`.
2. `lib/core/services/ai/ai_provider.dart` — update the `ollamaModelProvider` fallback default to match.

No architectural changes, no new behavior, no new files in `lib/` or `test/`. Both edits are already applied in the working tree (verified via `git diff`). This fits squarely into the TINY bucket per `agents/orchestrator-agent.md` ("Simple bug fixes, minor refactors, typo/doc updates").

## Active Pipeline Stages
Direct Implementation -> Verification -> Walkthrough

(Requirements, Refine-Spec, Planning, and Review are intentionally skipped per the TINY pipeline.)

## Expected Artifacts
- features/change-default-ollama-model/orchestration.md (this file)
- features/change-default-ollama-model/walkthrough.md
