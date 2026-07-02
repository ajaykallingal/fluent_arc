# Adaptive RPV Pipeline

This repo uses an **Adaptive RPV (Requirements -> Refine-Spec -> Planning -> Verification -> Work -> Compound)** pipeline. To optimize token efficiency and speed up turnaround times, task execution is routed dynamically by an orchestrator based on the scale and type of changes, preserving high architectural rigor only where it is needed.

## Pipeline Paths

When a task starts, the orchestrator classifies it into one of five pathways:

1. **TINY (Bug Fixes, Minor Tweaks)**
   - *Workflow*: Direct Implementation -> Verification.
   - *Description*: Skips requirements, refine-spec, planning, and review documents. Directly implement the changes, run tests, and generate `walkthrough.md`.
2. **MEDIUM (Standard Feature / Component)**
   - *Workflow*: Requirements -> Refine-Spec -> Simplified Plan -> Implementation -> Compound.
   - *Description*: Produces requirements and codebase-grounded refine-spec findings. Generates a simplified, atomic task list in `plan.yaml` and skips the review and central plan copy stages to save tokens.
3. **LARGE (Major Architectural Feature)**
   - *Workflow*: Requirements -> Refine-Spec -> Planning -> Review -> Implementation -> Compound.
   - *Description*: Runs the full RPV pipeline. Generates all four pre-work files (`requirements.md`, `refine_spec_findings.md`, `plan.yaml`, `review.md`) and enforces strict human approval gates.
4. **DEPENDENCY (Package Upgrades / Modifications)**
   - *Workflow*: Impact Analysis -> Direct Implementation -> Verification.
   - *Description*: Scans package usage, generates `impact_analysis.md` outlining changes and potential side effects, performs updates, and runs verification tests.
5. **UI (Pure Styling / Visual Adjustment)**
   - *Workflow*: Design Review -> Direct Implementation -> Verification.
   - *Description*: Conducts a compliance check against `knowledge/design_system.md`, generates `design_review.md`, implements UI changes, and verifies them.

---

## How to start a new task

Run `/start-task "Your task description here"`

This initializes the feature directory `features/{slug}/`, runs the `agents/orchestrator-agent.md` to classify the task, creates the initial artifacts for the chosen path, and summarizes the plan.

## How to implement a task

For paths requiring approval (MEDIUM, LARGE), once the pre-work plan is approved, run `/work-feature {slug}` to implement:
- Adopts the `agents/work-agent.md` persona.
- Sequentially implements task lists in `plan.yaml`.
- References technical guidelines from `.agents/skills/`.
- Verifies intermediate stages with tests and lints.
- Produces `features/{slug}/walkthrough.md` summarizing the changes.

## How to compound a cycle

For tasks that introduce new architectural lessons or updates, run `/compound-feature {slug}` to update `knowledge/` or `agents/` files with lessons from the cycle.

## Human approval gates

Depending on the chosen path, human verification is required:
- **TINY, DEPENDENCY, UI**: Human reviews the final code changes, lints, and the generated `walkthrough.md`.
- **MEDIUM**: Human reviews `requirements.md`, `refine_spec_findings.md`, and `plan.yaml` before running `/work-feature {slug}`.
- **LARGE**: Human reviews requirements, refinement findings, task breakdown, and `review.md` (confirming `APPROVE_TO_IMPLEMENT`) before running `/work-feature {slug}`.