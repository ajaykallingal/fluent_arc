# Dependency Impact Analysis: {dependency_name}

## Objective
Update/add dependency `{dependency_name}` to version `{version}` and evaluate its impact.

## Scope of Changes
- Dependency: `{dependency_name}` ({old_version} -> {new_version})
- Files directly referencing this dependency:
  {list of files}
- Potential side effects or breaking changes:
  {list}

## Verification Checklist
- [ ] Run `flutter pub get`
- [ ] Run static analysis (`flutter analyze`)
- [ ] Run all automated tests (`flutter test`)
- [ ] Verify functionality of features depending on this package

## Verdict
APPROVE_TO_IMPLEMENT | NEEDS_REVISION | BLOCKED
