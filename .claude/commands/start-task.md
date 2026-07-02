---
description: Start a new task (feature, bug fix, UI change, or dependency update) using the adaptive RPV pipeline. Usage: /start-task "task description"
---

You are running the adaptive RPV pipeline for a new task: "$ARGUMENTS"

Follow this sequence to orchestrate and execute the task. Do not deviate.

### Step 1: Orchestration
1. Slugify the task name (lowercase, hyphenated) to create a feature slug.
2. Create the directory `features/{slug}/` if it does not exist.
3. Adopt the persona in `agents/orchestrator-agent.md`. Read the task description, scan the codebase, and decide on the task classification:
   - **TINY**: Simple bug fixes, doc updates, single-line adjustments.
   - **MEDIUM**: Standard feature additions or logical updates spanning a few files.
   - **LARGE**: Major architectural features, multi-layered features, or new domains.
   - **DEPENDENCY**: Updating, adding, or removing pubspec.yaml packages.
   - **UI**: Visual, layout, typography, or styling adjustments.
4. Fill out `templates/orchestration_template.md` and save as `features/{slug}/orchestration.md`.
5. Present the classification and rationale clearly to the user.

### Step 2: Route Execution
Based on the classification chosen in Step 1, proceed to the corresponding route:

#### ROUTE A: TINY
1. Adopt the persona in `agents/work-agent.md`.
2. Skip requirements, refine-spec, planning, and review documents.
3. Directly implement the requested change or fix in the codebase.
4. Run validation:
   - `flutter analyze`
   - `flutter test`
5. Generate `features/{slug}/walkthrough.md` summarizing the changes and verification results.
6. Print the completion summary and stop.

#### ROUTE B: MEDIUM
1. Adopt the persona in `agents/requirement-agent.md`. Produce `features/{slug}/requirements.md` and `features/{slug}/requirements.json`.
2. Adopt the persona in `agents/refine-spec-agent.md`. Read the real codebase, update `features/{slug}/requirements.md` in place, and produce `features/{slug}/refine_spec_findings.md`.
3. Adopt the persona in `agents/planner-agent.md` to produce `features/{slug}/plan.yaml` containing the ordered atomic tasks (you may skip `plans/{slug}.yaml` copy and `review.md`).
4. Print a summary to the user listing:
   - The open questions that need manual verification/approval.
   - The created files: `orchestration.md`, `requirements.md`, `refine_spec_findings.md`, `plan.yaml`.
   - Explicitly state: "No code has been written. This medium feature requires human approval. Once approved, run `/work-feature {slug}` to implement."
5. Stop. Do not write any implementation code.

#### ROUTE C: LARGE
1. Adopt the persona in `agents/requirement-agent.md`. Produce `features/{slug}/requirements.md` and `features/{slug}/requirements.json`.
2. Adopt the persona in `agents/refine-spec-agent.md`. Read the real codebase, update `features/{slug}/requirements.md` in place, and produce `features/{slug}/refine_spec_findings.md`.
3. Adopt the persona in `agents/planner-agent.md`. Produce `features/{slug}/plan.yaml` (and copy to `plans/{slug}.yaml`).
4. Adopt the persona in `agents/review-agent.md`. Produce `features/{slug}/review.md`.
5. Print a summary to the user listing:
   - The verdict from `review.md`.
   - Open questions needing human answers.
   - The created files: `orchestration.md`, `requirements.md`, `refine_spec_findings.md`, `plan.yaml`, `review.md`.
   - Explicitly state: "No code has been written. This large feature requires human approval. Once approved, run `/work-feature {slug}` to implement."
6. Stop. Do not write any implementation code.

#### ROUTE D: DEPENDENCY
1. Scan the codebase for usage of the dependency.
2. Adopt `agents/refine-spec-agent.md` to analyze package impact. Fill out `templates/impact_analysis_template.md` and save as `features/{slug}/impact_analysis.md`.
3. Print the impact analysis and ask for confirmation, or directly apply the dependency change in `pubspec.yaml` if simple.
4. Run `flutter pub get`.
5. Run validation:
   - `flutter analyze`
   - `flutter test`
6. Generate `features/{slug}/walkthrough.md` summarizing the changes and validation status.
7. Print completion summary and stop.

#### ROUTE E: UI
1. Adopt `agents/refine-spec-agent.md` to check alignment with `knowledge/design_system.md`. Fill out `templates/design_review_template.md` and save as `features/{slug}/design_review.md`.
2. Adopt `agents/work-agent.md` and implement the styling/visual changes.
3. Run validation:
   - `flutter analyze`
   - `flutter test` (including widget tests if available).
4. Generate `features/{slug}/walkthrough.md` summarizing the UI changes.
5. Print completion summary and stop.
