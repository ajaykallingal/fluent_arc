import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_arc/core/services/ai/mock_ai_provider.dart';

void main() {
  group('MockAiProvider Tests', () {
    late MockAiProvider mockAiProvider;

    setUp(() {
      mockAiProvider = MockAiProvider();
    });

    test('generateText returns response containing prompt', () async {
      final response = await mockAiProvider.generateText('hello');
      expect(response, contains('hello'));
    });

    test('generateChatResponse responds to greetings', () async {
      final response = await mockAiProvider.generateChatResponse(
        [],
        'Hello tutor!',
      );
      expect(response, contains('AI language tutor'));
    });

    test('analyzeGrammar detects standard grammatical errors', () async {
      final result = await mockAiProvider.analyzeGrammar(
        'I is going to the market.',
      );
      expect(result.correctedSentence, contains('I am going'));
      expect(result.grammarScore, lessThan(100));

      final correctResult = await mockAiProvider.analyzeGrammar(
        'I am going to the market.',
      );
      expect(correctResult.grammarScore, equals(100));
    });

    test('suggestVocabulary returns words matching topic', () async {
      final results = await mockAiProvider.suggestVocabulary('travel');
      expect(results.length, equals(3));
      expect(results.first.word, equals('Itinerary'));
    });
  });
}
