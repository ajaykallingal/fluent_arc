# Design System

## Theme
- Source of truth: `lib/core/theme/app_theme.dart` (`AppTheme` class).
- Material 3 (`useMaterial3: true`), with both `lightTheme` and `darkTheme`
  configured and `ThemeMode.system` set in `main.dart`.
- The `AppTheme` constructor is private (`AppTheme._()`); access themes via
  `AppTheme.lightTheme` / `AppTheme.darkTheme`. Do not instantiate
  `ThemeData` inline elsewhere.

## Color Tokens
Defined as `static const Color` on `AppTheme`. Use these tokens — do not
hardcode hex anywhere in views.

| Token              | Light       | Dark        |
| ------------------ | ----------- | ----------- |
| `primary`          | `#4F46E5` (Indigo) | `#818CF8` (Neon Indigo) |
| `secondary`        | `#7C3AED` (Violet)  | `#A78BFA` (Pastel Violet) |
| `tertiary`         | `#0D9488` (Teal)    | `#2DD4BF` (Neon Cyan) |
| `error`            | `#DC2626`           | `#F87171` |
| `background`       | `#F8FAFC` (Slate 50) | `#0F172A` (Slate 900) |
| `surface`          | `#FFFFFF`           | `#1E293B` (Slate 800) |

When writing a view, prefer `Theme.of(context).colorScheme.primary` (etc.)
over reaching into the `AppTheme` constants directly.

## Typography
There is no custom font wired up in `pubspec.yaml` — typography inherits
from Material 3 defaults via the theme. App bar titles use
`TextStyle(fontSize: 20, fontWeight: FontWeight.w700)`. Elevated button
text is `TextStyle(fontSize: 16, fontWeight: FontWeight.w600)`. Match
these weights for new top-level headlines and primary CTAs; everything
else should inherit from `Theme.of(context).textTheme`.

## Component Library
Shared widgets live in `lib/core/widgets/`:

- `app_text_field.dart` — styled `TextField` matching the theme.
- `primary_button.dart`, `secondary_button.dart` — full-width CTA buttons
  (52px tall, 12px radius — matches `ElevatedButtonTheme`).
- `loading_view.dart`, `error_view.dart`, `empty_view.dart` — standard
  state surfaces.
- `progress_card.dart`, `score_card.dart`, `stat_card.dart` — domain
  result presentations.
- `avatar_widget.dart` — user avatar.

New shared widgets belong here, not inside a feature folder, if they are
used by two or more features. Feature-specific widgets stay under
`features/<feature>/presentation/views/` (or a `widgets/` subfolder there
if a view grows enough to need decomposition).

## Spacing / Sizing Rules
- Cards use 16px border radius (`RoundedRectangleBorder(borderRadius:
  BorderRadius.circular(16))` in `cardTheme`).
- Inputs and primary buttons use 12px border radius.
- Primary buttons are full-width by default
  (`minimumSize: Size(double.infinity, 52)`).
- Input fields use 16px horizontal / vertical content padding, filled with
  Slate 100 (light) / Slate 700 (dark).
- TBD — confirm with design team: spacing scale (4 / 8 / 16 / 24 / 32),
  responsive breakpoints, dark-mode contrast review.