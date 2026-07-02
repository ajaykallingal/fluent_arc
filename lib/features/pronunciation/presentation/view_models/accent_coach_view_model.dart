import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/sqlite_pronunciation_attempt_repository.dart';
import '../../data/services/mock_pronunciation_analyzer.dart';
import '../../data/services/mock_speech_to_text_provider.dart';
import '../../data/services/mock_text_to_speech_provider.dart';
import '../../data/services/offline_pronunciation_analyzer.dart';
import '../../domain/models/pronunciation_attempt.dart';
import '../../domain/repositories/pronunciation_attempt_repository.dart';
import '../../domain/services/pronunciation_analyzer.dart';
import '../../domain/services/speech_to_text_provider.dart';
import '../../domain/services/text_to_speech_provider.dart';
import '../../../../core/services/ai/ai_provider.dart';
import '../../../progress/presentation/view_models/progress_view_model.dart';

final sttProvider = Provider<SpeechToTextProvider>((ref) {
  return MockSpeechToTextProvider();
});

final ttsProvider = Provider<TextToSpeechProvider>((ref) {
  return MockTextToSpeechProvider();
});

/// Selects between [OfflinePronunciationAnalyzer] and
/// [MockPronunciationAnalyzer] based on whether
/// `GEMINI_API_KEY` is configured. Empty key → offline scorer. The
/// switch lives here in the pronunciation feature, NOT in
/// `core/services/ai/`, so adding a future remote (non-Gemini)
/// implementation does not require touching the shared AI surface.
final analyzerProvider = Provider<PronunciationAnalyzer>((ref) {
  final apiKey = ref.watch(aiApiKeyProvider);
  if (apiKey.isEmpty) {
    return OfflinePronunciationAnalyzer();
  }
  return MockPronunciationAnalyzer();
});

/// Repository for the per-attempt persistence introduced in schema
/// v2. Override in tests via `pronunciationAttemptRepositoryProvider
/// .overrideWithValue(...)`.
final pronunciationAttemptRepositoryProvider =
    Provider<PronunciationAttemptRepository>((ref) {
  return SqlitePronunciationAttemptRepository();
});

class AccentCoachState {
  final String targetText;
  final String spokenText;
  final PronunciationAnalysisResult? result;
  final bool isListening;
  final bool isPlayingTts;
  final bool isAnalyzing;
  final String? errorMessage;

  const AccentCoachState({
    required this.targetText,
    required this.spokenText,
    this.result,
    required this.isListening,
    required this.isPlayingTts,
    required this.isAnalyzing,
    this.errorMessage,
  });

  factory AccentCoachState.initial() => const AccentCoachState(
        targetText: 'I would like to acquire native fluency in speaking.',
        spokenText: '',
        isListening: false,
        isPlayingTts: false,
        isAnalyzing: false,
      );

  AccentCoachState copyWith({
    String? targetText,
    String? spokenText,
    PronunciationAnalysisResult? result,
    bool? isListening,
    bool? isPlayingTts,
    bool? isAnalyzing,
    String? errorMessage,
  }) {
    return AccentCoachState(
      targetText: targetText ?? this.targetText,
      spokenText: spokenText ?? this.spokenText,
      result: result ?? this.result,
      isListening: isListening ?? this.isListening,
      isPlayingTts: isPlayingTts ?? this.isPlayingTts,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AccentCoachNotifier extends Notifier<AccentCoachState> {
  late final SpeechToTextProvider _stt;
  late final TextToSpeechProvider _tts;
  late final PronunciationAnalyzer _analyzer;
  late final PronunciationAttemptRepository _attemptRepository;
  StreamSubscription<bool>? _sttSubscription;
  StreamSubscription<bool>? _ttsSubscription;

  @override
  AccentCoachState build() {
    _stt = ref.watch(sttProvider);
    _tts = ref.watch(ttsProvider);
    _analyzer = ref.watch(analyzerProvider);
    _attemptRepository = ref.watch(pronunciationAttemptRepositoryProvider);

    _sttSubscription = _stt.isListening.listen((listening) {
      if (ref.mounted) {
        state = state.copyWith(isListening: listening);
      }
    });

    _ttsSubscription = _tts.isPlaying.listen((playing) {
      if (ref.mounted) {
        state = state.copyWith(isPlayingTts: playing);
      }
    });

    ref.onDispose(() {
      _sttSubscription?.cancel();
      _ttsSubscription?.cancel();
    });

    return AccentCoachState.initial();
  }

  void updateTargetText(String text) {
    state = state.copyWith(
      targetText: text,
      spokenText: '',
      result: null,
      errorMessage: null,
    );
  }

  Future<void> speakPrompt() async {
    state = state.copyWith(errorMessage: null);
    try {
      await _tts.speak(state.targetText);
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(errorMessage: 'TTS playback error');
      }
    }
  }

  Future<void> startRecording() async {
    state = state.copyWith(spokenText: '', result: null, errorMessage: null);
    try {
      await _stt.startListening();
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(errorMessage: 'Microphone permission error');
      }
    }
  }

  Future<void> stopRecordingAndAnalyze() async {
    state = state.copyWith(isAnalyzing: true);
    try {
      // Simulate that the user mispronounced the word 'acquire' as 'require'
      final spoken = state.targetText.replaceAll('acquire', 'require').replaceAll('Acquire', 'require');
      if (_stt is MockSpeechToTextProvider) {
        _stt.setSimulatedTranscript(spoken);
      }

      final transcript = await _stt.stopListening();
      final analysis = await _analyzer.analyze(state.targetText, transcript);

      if (ref.mounted) {
        state = state.copyWith(
          spokenText: transcript,
          result: analysis,
          isAnalyzing: false,
        );
        ref.read(progressNotifierProvider.notifier).recordSpeakingSession();
      }

      // Persist the attempt. A storage failure MUST NOT clobber
      // `result` — the score is still useful to the learner; only
      // `errorMessage` is set as a non-blocking signal.
      try {
        await _attemptRepository.recordAttempt(
          PronunciationAttempt(
            targetPhrase: state.targetText,
            spokenText: transcript,
            overallScore: analysis.overallScore.round(),
            accuracyScore: analysis.accuracyScore,
            fluencyScore: analysis.fluencyScore,
            completenessScore: analysis.completenessScore,
            engine: analysis.engine,
            attemptedAt: DateTime.now(),
          ),
        );
      } catch (e) {
        if (ref.mounted) {
          state = state.copyWith(
            errorMessage: 'Score saved in memory; persistence failed.',
          );
        }
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isAnalyzing: false,
          errorMessage: 'Pronunciation analysis failed.',
        );
      }
    }
  }
}

final accentCoachNotifierProvider =
    NotifierProvider<AccentCoachNotifier, AccentCoachState>(() {
  return AccentCoachNotifier();
});