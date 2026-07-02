import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fluent_arc/features/grammar/domain/models/grammar_report.dart';
import 'package:fluent_arc/features/grammar/domain/repositories/grammar_repository.dart';
import 'package:fluent_arc/features/grammar/presentation/view_models/grammar_view_model.dart';
import 'package:fluent_arc/core/services/ai/ai_provider.dart';

class MockGrammarRepository extends Mock implements GrammarRepository {}
class MockAiProvider extends Mock implements AiProvider {}

void main() {
  late MockGrammarRepository mockGrammarRepository;
  late ProviderContainer container;

  setUp(() {
    mockGrammarRepository = MockGrammarRepository();

    container = ProviderContainer(
      overrides: [
        grammarRepositoryProvider.overrideWithValue(mockGrammarRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('GrammarNotifier Tests', () {
    test('initial state is empty and not loading', () {
      final state = container.read(grammarNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.report, isNull);
      expect(state.errorMessage, isNull);
    });

    test('checkGrammar success returns report and updates state', () async {
      const mockReport = GrammarReport(
        originalText: 'He go there yesterday.',
        correctedText: 'He went there yesterday.',
        explanation: 'Use past tense "went" instead of present "go".',
        score: 80,
      );

      when(() => mockGrammarRepository.checkSentence('He go there yesterday.'))
          .thenAnswer((_) => Future.value(mockReport));

      final notifier = container.read(grammarNotifierProvider.notifier);
      final future = notifier.checkGrammar('He go there yesterday.');

      // Check loading state immediately
      expect(container.read(grammarNotifierProvider).isLoading, isTrue);

      await future;

      final finalState = container.read(grammarNotifierProvider);
      expect(finalState.isLoading, isFalse);
      expect(finalState.report?.correctedText, equals('He went there yesterday.'));
      expect(finalState.report?.score, equals(80));
    });

    test('checkGrammar failure sets error message', () async {
      when(() => mockGrammarRepository.checkSentence('bad text'))
          .thenThrow(Exception('Timeout error'));

      final notifier = container.read(grammarNotifierProvider.notifier);
      await notifier.checkGrammar('bad text');

      final state = container.read(grammarNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('Failed to analyze grammar'));
    });

    test('reset clears report and errors', () async {
      const mockReport = GrammarReport(
        originalText: 'ok',
        correctedText: 'ok',
        explanation: 'Good',
        score: 100,
      );
      when(() => mockGrammarRepository.checkSentence('ok'))
          .thenAnswer((_) => Future.value(mockReport));

      final notifier = container.read(grammarNotifierProvider.notifier);
      await notifier.checkGrammar('ok');
      expect(container.read(grammarNotifierProvider).report, isNotNull);

      notifier.reset();
      final state = container.read(grammarNotifierProvider);
      expect(state.report, isNull);
      expect(state.errorMessage, isNull);
    });
  });
}
