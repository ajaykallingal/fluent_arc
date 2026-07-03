import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fluent_arc/core/services/ai/ai_provider.dart';
import 'package:fluent_arc/features/pronunciation/data/services/mock_pronunciation_analyzer.dart';
import 'package:fluent_arc/features/pronunciation/data/services/offline_pronunciation_analyzer.dart';
import 'package:fluent_arc/features/pronunciation/domain/models/pronunciation_attempt.dart';
import 'package:fluent_arc/features/pronunciation/domain/repositories/pronunciation_attempt_repository.dart';
import 'package:fluent_arc/features/pronunciation/domain/services/pronunciation_analyzer.dart';
import 'package:fluent_arc/features/pronunciation/domain/services/speech_to_text_provider.dart';
import 'package:fluent_arc/features/pronunciation/domain/services/text_to_speech_provider.dart';
import 'package:fluent_arc/features/pronunciation/presentation/view_models/accent_coach_view_model.dart';

class _MockRepository extends Mock implements PronunciationAttemptRepository {}

class _FakeAnalyzer implements PronunciationAnalyzer {
  final List<Map<String, String>> calls = [];
  PronunciationAnalysisResult result;

  _FakeAnalyzer(this.result);

  @override
  Future<PronunciationAnalysisResult> analyze(
    String targetText,
    String spokenText,
  ) async {
    calls.add({'targetText': targetText, 'spokenText': spokenText});
    return result;
  }
}

class _FakeStt implements SpeechToTextProvider {
  final String transcript;
  final _ctrl = StreamController<bool>.broadcast();
  bool listening = false;

  _FakeStt(this.transcript);

  @override
  Stream<bool> get isListening => _ctrl.stream;

  @override
  Future<void> startListening() async {
    listening = true;
    _ctrl.add(true);
  }

  @override
  Future<String> stopListening() async {
    listening = false;
    _ctrl.add(false);
    return transcript;
  }

  @override
  Future<void> cancel() async {
    listening = false;
    _ctrl.add(false);
  }
}

class _FakeTts implements TextToSpeechProvider {
  final _ctrl = StreamController<bool>.broadcast();

  @override
  Stream<bool> get isPlaying => _ctrl.stream;

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  setUpAll(() {
    // Register a fallback for any() on the entity type, in case the
    // test uses matchers against the entity itself.
    registerFallbackValue(
      PronunciationAttempt(
        targetPhrase: '',
        spokenText: '',
        overallScore: 0,
        accuracyScore: 0,
        fluencyScore: 0,
        completenessScore: 0,
        engine: 'offline-local',
        attemptedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  });

  group('analyzerProvider selection (T08 / AC #2)', () {
    test('empty GEMINI_API_KEY returns OfflinePronunciationAnalyzer', () {
      final container = ProviderContainer(
        overrides: [aiApiKeyProvider.overrideWithValue('')],
      );
      addTearDown(container.dispose);
      final analyzer = container.read(analyzerProvider);
      expect(analyzer, isA<OfflinePronunciationAnalyzer>());
    });

    test('non-empty GEMINI_API_KEY returns MockPronunciationAnalyzer', () {
      final container = ProviderContainer(
        overrides: [aiApiKeyProvider.overrideWithValue('test-key')],
      );
      addTearDown(container.dispose);
      final analyzer = container.read(analyzerProvider);
      expect(analyzer, isA<MockPronunciationAnalyzer>());
    });
  });

  group('AccentCoachNotifier persistence (T09 / AC #4, #7)', () {
    late _MockRepository repository;
    late _FakeAnalyzer analyzer;
    late _FakeStt stt;
    late ProviderContainer container;

    setUp(() {
      repository = _MockRepository();
      analyzer = _FakeAnalyzer(
        const PronunciationAnalysisResult(
          overallScore: 80,
          words: [],
          generalFeedback: 'Good attempt.',
          accuracyScore: 80,
          fluencyScore: 75,
          completenessScore: 90,
          engine: 'offline-local',
        ),
      );
      stt = _FakeStt('I would like to require native fluency in speaking.');

      when(() => repository.recordAttempt(any())).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          analyzerProvider.overrideWithValue(analyzer),
          sttProvider.overrideWithValue(stt),
          ttsProvider.overrideWithValue(_FakeTts()),
          pronunciationAttemptRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'successful analysis writes one row to the repository (AC #4)',
      () async {
        final notifier = container.read(accentCoachNotifierProvider.notifier);
        await notifier.stopRecordingAndAnalyze();

        // Allow the in-notifier try/catch to settle.
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final captured =
            verify(() => repository.recordAttempt(captureAny())).captured.single
                as PronunciationAttempt;
        expect(captured.engine, equals('offline-local'));
        expect(captured.overallScore, equals(80));
        expect(captured.attemptedAt, isNotNull);
      },
    );

    test('failing repository does not clobber result (AC #7)', () async {
      when(
        () => repository.recordAttempt(any()),
      ).thenThrow(Exception('disk full'));

      final notifier = container.read(accentCoachNotifierProvider.notifier);
      await notifier.stopRecordingAndAnalyze();

      // Allow the in-notifier try/catch to settle.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(accentCoachNotifierProvider);
      // Score is still in `result`.
      expect(state.result, isNotNull);
      expect(state.result!.engine, equals('offline-local'));
      // Storage error surfaced as a non-blocking message.
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('persistence'));
    });
  });
}
