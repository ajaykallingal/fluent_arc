# Navigation

## Router
`go_router: ^17.3.0` is the routing package of record (see `pubspec.yaml`).
Configuration lives in `lib/core/config/router.dart` as a single
top-level `goRouter` instance. `MaterialApp.router(routerConfig:
goRouter)` is wired in `main.dart`. Do not introduce
`Navigator.push`/`Navigator.pop` for top-level navigation — use
`context.go(...)` or `context.push(...)` from `go_router`.

## Route Table
Current routes (from `lib/core/config/router.dart`):

| Path             | View             | Notes                                 |
| ---------------- | ---------------- | ------------------------------------- |
| `/login`         | `LoginView`      | `initialLocation` — app starts here.  |
| `/`              | `DashboardView`  | Post-login home.                      |
| `/conversation`  | `ConversationView` | AI chat tutoring.                    |
| `/grammar`       | `GrammarView`    | Sentence check.                       |
| `/vocabulary`    | `VocabularyView` | Vocabulary list / suggestions.        |
| `/accent`        | `AccentCoachView` | Pronunciation practice.             |
| `/progress`      | `ProgressView`   | User progress dashboard.              |

## Route Naming Convention
- Lowercase, kebab-case for multi-word paths if/when introduced (none
  currently).
- Singular nouns preferred (`/grammar`, not `/grammars`).
- Path matches the destination View file's purpose — e.g. `/accent`
  maps to `accent_coach_view.dart`. Keep the path/feature folder name
  aligned; if you rename a feature folder, update its route path in the
  same commit.

## Adding a New Route
1. Add the View file under
   `features/<feature>/presentation/views/<feature>_view.dart`.
2. Import it in `lib/core/config/router.dart` alongside the other
   imports.
3. Add a `GoRoute(path: '<path>', builder: (context, state) =>
   const <FeatureView>())` inside the `routes: [...]` list.
4. Preserve `initialLocation: '/login'` unless the team has explicitly
   decided to change the boot destination.

## Deep Linking Rules
TBD — no deep linking is currently configured. If/when introduced, the
default `go_router` config requires explicit `path` matching; document
the intended link contract here before wiring `goRouter`'s
`debugLogDiagnostics` or platform-specific link config.

## Auth Gate
There is no `redirect:` rule on the router yet — `LoginView` is reachable
without an auth check. The post-auth dashboard is at `/`. If/when auth
gating is added, prefer doing it via `goRouter`'s `redirect` callback
with a small session provider, rather than wrapping individual routes.