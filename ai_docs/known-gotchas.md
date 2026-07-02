## FluentArc — Known Gotchas

Pre-seeded before first ACT session. Update this file whenever a new gotcha is discovered during development.

## Audio recording (iOS)
* Requires NSMicrophoneUsageDescription in Info.plist
* AVAudioSession must be configured before recording starts
* Background audio requires UIBackgroundModes: audio in Info.plist
* M4A format preferred for iOS; WAV for Deepgram compatibility — may need format conversion step

## Deepgram
* Nova-3 model requires model=nova-3 query param
* Streaming vs file upload: for accent coaching, batch file upload is simpler to implement first
* Word-level timestamps require punctuate=true&words=true params

## Gemini 2.5 Flash
* Multimodal input (audio + text) available but adds latency
* For scoring: send transcript text + Deepgram confidence scores rather than raw audio — cheaper and faster
* Rate limits: check current tier before designing retry logic

## ElevenLabs
* Streaming playback requires chunked HTTP response handling
* Voice cloning not needed — use a standard voice ID
* Audio format: MP3 stream works on iOS with AVPlayer

## Supabase
* Row Level Security (RLS) must be enabled on all tables
* Auth tokens expire — implement refresh token logic early
* Storage buckets for audio files: set to private, use signed URLs

## Flutter general
* flutter analyze must pass with zero errors before any commit
* flutter test must pass before any commit
* Do not add packages without explicit approval — check pubspec.yaml first
* Always run on physical device for audio testing — simulator has no microphone

## State management
* The project uses Riverpod with Notifier and NotifierProvider for state management instead of BLoC or Cubit.
* Screen states are modeled by immutable state classes (such as AuthState, AccentCoachState, ConversationState, GrammarState, VocabularyState, ProgressState) and modified exclusively inside the Notifier subclasses.
* UI files should utilize ConsumerWidget or ConsumerStatefulWidget to watch notifier providers and rebuild when state properties change.

## Known issues found in current codebase
* Redundant non-null assertions on non-nullable receivers in repository classes:
  * lib/features/auth/data/repositories/supabase_auth_repository.dart
  * lib/features/conversation/data/repositories/supabase_conversation_repository.dart
  * lib/features/progress/data/repositories/supabase_progress_repository.dart
* Deprecated member usage warnings in Flutter 3.22+:
  * withOpacity is used in multiple widgets under lib/core/widgets/ and feature views (e.g., accent_coach_view.dart, conversation_view.dart, vocabulary_view.dart, grammar_view.dart, dashboard_view.dart). This should be replaced with withValues(alpha: ...).
  * surfaceVariant is used in lib/features/conversation/presentation/views/conversation_view.dart. This should be replaced with surfaceContainerHighest.
  * anonKey is used in lib/main.dart for Supabase initialization. This should be replaced with publishableKey.
* The local .env asset dependency: pubspec.yaml registers .env as a project asset, but it is not committed to source control. A local .env file must be created (e.g., using .env.example) for builds, analyses, and tests to run successfully.
