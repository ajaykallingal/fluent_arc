# API Contracts

## Base Conventions

### Backend (Supabase)
- Client: `supabase_flutter: ^2.5.0`.
- Initialization in `lib/main.dart` reads `SUPABASE_URL` and
  `SUPABASE_ANON_KEY` from a `.env` file (loaded via
  `flutter_dotenv: ^5.1.0`). `.env` is registered as a Flutter asset in
  `pubspec.yaml`. `.env.example` lists the expected keys.
- If either key is missing OR Supabase init throws, the app continues
  in offline / mock mode (`isBackendInitialized = false`). Features must
  not assume remote calls succeed.

### AI (Gemini)
- Client: `google_generative_ai: ^0.4.7`.
- The API key (`GEMINI_API_KEY`) is sourced from
  `String.fromEnvironment('GEMINI_API_KEY')` via
  `aiApiKeyProvider`. When the key is empty, the app falls back to
  `MockAiProvider` (offline behavior).
- Active model: `gemini-1.5-flash` (see
  `lib/core/services/ai/gemini_provider.dart`). Planned migration to
  `gemini-2.5-flash` for scoring (see `CLAUDE.md` "AI service
  integrations") — confirm before bumping.
- The AI surface is abstracted behind `AiProvider` with four methods:
  - `generateText(String prompt) → String`
  - `generateChatResponse(List<AiChatMessage> history, String
    newMessage) → String`
  - `analyzeGrammar(String text) → AiGrammarAnalysis`
  - `suggestVocabulary(String topic, {String difficulty}) →
    List<AiVocabularyWord>`

  New AI-backed features must extend the `AiProvider` interface (or
  these established return types) rather than instantiating
  `GenerativeModel` directly.

## Structured-Output Convention
For Gemini calls that need structured output, the established pattern is:
1. Embed a JSON schema in the prompt with an explicit `Provide ONLY the
   raw JSON ... Do not include markdown code blocks.` instruction.
2. After receiving the response, run it through `_cleanJsonOutput`
   (strips leading/trailing ``` fences).
3. `jsonDecode` inside a try/catch with a safe fallback object.

This is the contract callers can rely on: if the model returns bad JSON,
the call returns the fallback shape rather than throwing.

## Error Response Shape
TBD — there is no documented canonical error envelope from either
Supabase or Gemini in this repo. `supabase_flutter` surfaces
`AuthException` / `PostgrestException`; Gemini surfaces raw exceptions
from the SDK. Until a shared `Result<T, AppError>` type is introduced,
data-layer repositories should let these throw and let view models wrap
them into `AsyncValue.error`.

## Versioning
TBD — no API versioning policy is documented. Both Supabase (REST +
PostgREST) and Gemini are external SaaS — versioning is theirs to
break. When pinning, capture the model name and the Supabase project
URL via `.env`, not in code.