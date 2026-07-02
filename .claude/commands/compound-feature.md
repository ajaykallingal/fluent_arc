---
description: Capture lessons learned from an approved feature cycle and update the knowledge base. Usage: /compound-feature {slug}
---

You are running the Compound stage for feature: "$ARGUMENTS"

Before doing anything else, confirm features/{slug}/review.md exists and
its Verdict is APPROVE_TO_IMPLEMENT (or that the human has explicitly
told you they're approving it despite a different verdict — e.g. they
fixed something manually). If review.md doesn't exist yet, stop and
tell the human to run /new-feature first.

1. Adopt the persona in agents/compound-agent.md.
2. Read features/{slug}/requirements.md, refine_spec_findings.md,
   plan.yaml, and review.md in full.
3. Identify real lessons per that persona's process — do not pad the
   list with generic advice that didn't actually arise from this cycle.
4. Apply the diffs to /knowledge and/or /agents files as instructed.
5. Append the entry to COMPOUND_LOG.md.
6. Print a summary: what was learned, which files were updated, and a
   reminder that the human should review the resulting diff (e.g. via
   `git diff knowledge/ agents/`) before committing, since this agent's
   edits to the knowledge base affect every future feature cycle.