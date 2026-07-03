import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:fluent_arc/core/services/ai/ollama_provider.dart';
import 'package:fluent_arc/core/services/ai/ai_provider.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('OllamaProvider Tests', () {
    late MockHttpClient mockClient;
    late OllamaProvider ollamaProvider;
    const baseUrl = 'http://localhost:11434';
    const model = 'gemma:2b';

    setUpAll(() {
      registerFallbackValue(Uri.parse(baseUrl));
    });

    setUp(() {
      mockClient = MockHttpClient();
      ollamaProvider = OllamaProvider(
        baseUrl: baseUrl,
        model: model,
        client: mockClient,
      );
    });

    test('generateText returns correct string', () async {
      final mockResponse = jsonEncode({
        'response': 'This is a local response from Gemma.',
      });

      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockResponse, 200));

      final response = await ollamaProvider.generateText('Hello local Gemma');
      expect(response, equals('This is a local response from Gemma.'));
    });

    test('generateChatResponse returns content from message', () async {
      final mockResponse = jsonEncode({
        'message': {'content': 'I am your local AI tutor.'},
      });

      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockResponse, 200));

      final response = await ollamaProvider.generateChatResponse([
        AiChatMessage(role: 'user', text: 'Hello'),
      ], 'How are you?');
      expect(response, equals('I am your local AI tutor.'));
    });

    test('analyzeGrammar parses JSON correctly', () async {
      final mockResponse = jsonEncode({
        'response': jsonEncode({
          'originalSentence': 'I is coding.',
          'correctedSentence': 'I am coding.',
          'explanation': 'Verb agreement.',
          'grammarScore': 90,
        }),
      });

      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockResponse, 200));

      final result = await ollamaProvider.analyzeGrammar('I is coding.');
      expect(result.correctedSentence, equals('I am coding.'));
      expect(result.grammarScore, equals(90));
    });

    test('suggestVocabulary parses JSON list correctly', () async {
      final mockResponse = jsonEncode({
        'response': jsonEncode([
          {
            'word': 'Local',
            'definition': 'Relating to a particular area.',
            'example': 'This runs local.',
            'difficulty': 'Beginner',
          },
        ]),
      });

      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockResponse, 200));

      final words = await ollamaProvider.suggestVocabulary('tech');
      expect(words.length, equals(1));
      expect(words.first.word, equals('Local'));
    });
  });
}
