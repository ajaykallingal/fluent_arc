# Feature Patterns

This folder holds one markdown file per established feature pattern
(e.g. `list_detail_pattern.md`, `form_with_validation_pattern.md`).
Each time a new feature ships, the Compound Agent checks whether it
established a reusable pattern and, if so, adds a file here describing
it, so future Planner Agent runs can reference it instead of
re-deriving structure from scratch.

Currently empty — populated automatically by the Compound Agent as
features ship.

## Pattern File Conventions
When the Compound Agent adds a new pattern file, it should follow this
shape:

```
# Pattern: <name>

## When to use
<Triggering situation.>

## Layers involved
<domain / data / presentation — and what role each plays.>

## File layout
<Concrete file tree for a feature using this pattern.>

## Example in this repo
<Existing feature that demonstrates the pattern, with paths.>

## Anti-patterns
<What NOT to do when using this pattern — call out specific mistakes.>
```