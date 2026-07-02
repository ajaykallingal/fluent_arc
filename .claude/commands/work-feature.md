---
description: Implement a feature by executing its approved plan.yaml. Usage: /work-feature {slug}
---

You are running the Work stage for feature: "$ARGUMENTS"

Before doing anything else, confirm `features/{slug}/plan.yaml` and `features/{slug}/review.md` exist, and that the review Verdict is `APPROVE_TO_IMPLEMENT` (or the human has explicitly authorized implementation). If these files do not exist, stop and tell the human to run `/new-feature` first.

1. Adopt the persona in `agents/work-agent.md`.
2. Read the full `plan.yaml` tasks list.
3. For each task in the plan:
   - Identify which files to modify or create.
   - Look up the matching workspace skill in `.agents/skills/` (e.g., `dart-add-unit-test`, `flutter-fix-layout-issues`, etc.). Read its `SKILL.md` file using `view_file` to adopt its patterns.
   - Implement the code changes.
   - Run specific tests or compilation steps to verify the task's correctness.
4. Run the final validation commands:
   - `flutter analyze`
   - `flutter test`
5. Create the walkthrough document at `features/{slug}/walkthrough.md` summarizing:
   - The changes made.
   - The files modified.
   - The verification commands run and their results.
6. Print a summary to the user:
   - Confirming all plan tasks have been implemented.
   - Confirming `flutter analyze` and `flutter test` passed.
   - Providing the path to `features/{slug}/walkthrough.md`.
   - Explicitly stating: "The implementation is complete. Please review the changes and run `/compound-feature {slug}` to capture any new lessons learned into the knowledge base."
