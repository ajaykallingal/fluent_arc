## FluentArc — Architecture

## System overview
FluentArc is a Flutter-based client application powered by external AI models and backend cloud services. It uses Riverpod for client-side state management, GoRouter for navigation, SQLite for local offline data caching, and Supabase for user session persistence and storage. AI capabilities are accessed directly or planned via service endpoints including Google Gemini (for conversation, grammar and vocabulary), Deepgram (for speech transcription), and ElevenLabs (for text-to-speech audio synthesis).

## Core feature domains
1. Audio recording — capturing user speech
2. AI scoring — pronunciation and fluency analysis
3. Voice playback — reference audio and user replay
4. User progression — streaks, scores, lesson history

## State management
Riverpod is the state management library used throughout the application. Key Notifiers and Providers include:
* authNotifierProvider (AuthNotifier) - Controls authentication state using Supabase
* accentCoachNotifierProvider (AccentCoachNotifier) - Manages pronunciation assessment view state, recording triggers, and analysis requests
* conversationNotifierProvider (ConversationNotifier) - Handles real-time chat messages and tutoring responses from Gemini
* grammarNotifierProvider (GrammarNotifier) - Drives sentence grammar analyses and score reporting
* vocabularyNotifierProvider (VocabularyNotifier) - Coordinates vocabulary suggestion checks and saves words locally
* progressNotifierProvider (ProgressNotifier) - Fetches and stores user streaks and overall metrics
* dashboardNotifierProvider (DashboardNotifier) - Orchestrates summary metrics displayed to the user

## Navigation
Declarative routing is handled via GoRouter. The central configuration file at lib/core/config/router.dart exposes paths for:
* /login - LoginView
* / - DashboardView
* /conversation - ConversationView
* /grammar - GrammarView
* /vocabulary - VocabularyView
* /accent - AccentCoachView
* /progress - ProgressView

## Service layer
Provides abstracted interfaces and implementations for interacting with device hardware, database frameworks, and external REST/SDK clients:
* AiProvider (lib/core/services/ai/ai_provider.dart) - Abstract interface class exposing generateText, generateChatResponse, analyzeGrammar, and suggestVocabulary methods
* GeminiProvider (lib/core/services/ai/gemini_provider.dart) - Extends AiProvider using package:google_generative_ai with gemini-1.5-flash model
* OllamaProvider (lib/core/services/ai/ollama_provider.dart) - Extends AiProvider using local Ollama HTTP endpoints (for free offline LLM execution)
* MockAiProvider (lib/core/services/ai/mock_ai_provider.dart) - Simulates LLM responses for local offline developer testing
* SpeechToTextProvider (lib/features/pronunciation/domain/services/speech_to_text_provider.dart) - Speech transcription interface
* MockSpeechToTextProvider (lib/features/pronunciation/data/services/mock_speech_to_text_provider.dart) - Simulates voice recording and returns simulated text
* TextToSpeechProvider (lib/features/pronunciation/domain/services/text_to_speech_provider.dart) - TTS conversion interface
* MockTextToSpeechProvider (lib/features/pronunciation/data/services/mock_text_to_speech_provider.dart) - Simulates speech playback actions
* PronunciationAnalyzer (lib/features/pronunciation/domain/services/pronunciation_analyzer.dart) - Pronunciation evaluation interface
* MockPronunciationAnalyzer (lib/features/pronunciation/data/services/mock_pronunciation_analyzer.dart) - Computes simulated pronunciation scores

## Data layer
* DatabaseHelper (lib/core/services/storage/database_helper.dart) - Establishes SQLite connection and sets up local vocabulary tables
* AuthRepository / SupabaseAuthRepository (lib/features/auth/) - Manages user accounts using Supabase Auth
* ConversationRepository / SupabaseConversationRepository (lib/features/conversation/) - Saves chat histories to Supabase Database
* GrammarRepository / AiGrammarRepository (lib/features/grammar/) - Requests text corrections from AiProvider
* ProgressRepository / SupabaseProgressRepository (lib/features/progress/) - Synchronizes user streaks and metrics with Supabase
* VocabularyRepository / SqliteVocabularyRepository (lib/features/vocabulary/) - Inserts and retrieves starred vocabulary terms from local SQLite storage

## AI services (planned integrations)
**Gemini 2.5 Flash**
* Role: pronunciation scoring and fluency feedback
* Input: transcribed text + audio metadata
* Output: score (0–100), feedback string, phoneme-level notes

**Deepgram Nova-3**
* Role: speech-to-text transcription
* Input: recorded audio (WAV or M4A)
* Output: transcript with word-level confidence scores

**ElevenLabs**
* Role: reference voice playback (native speaker audio)
* Input: text phrase
* Output: audio stream

**Supabase**
* Role: user auth, session storage, lesson history, audio file storage
* Tables planned: users, sessions, lessons, recordings

## Known constraints
* iOS deployment target is configured to 15.0 in the Podfile.
* Active network access is required for real API connections to Supabase and Gemini.
* An environment configuration file (.env) containing valid SUPABASE_URL, SUPABASE_ANON_KEY, and GEMINI_API_KEY variables must be bundled with the assets.
* Audio capture and recording modules require device microphone permissions (NSMicrophoneUsageDescription for iOS, RECORD_AUDIO for Android).

## What does NOT exist yet
* Live microphone input capture and audio encoding pipeline (currently uses MockSpeechToTextProvider).
* Live audio playback stream for synthesized voices (currently uses MockTextToSpeechProvider).
* Direct Deepgram HTTP/SDK transcription services.
* Direct ElevenLabs voice generation API wrappers.
* Production Supabase server-side table structure (database operations rely on Supabase instances, but schemas must be provisioned).
* Real-time audio analysis comparing user voice frequency/phonemes directly in code (relies on mock corrections in MockPronunciationAnalyzer).
