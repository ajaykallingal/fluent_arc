import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fluent_arc/features/vocabulary/domain/models/vocabulary_word.dart';
import 'package:fluent_arc/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:fluent_arc/features/vocabulary/presentation/view_models/vocabulary_view_model.dart';
import 'package:fluent_arc/core/services/ai/ai_provider.dart';

class MockVocabularyRepository extends Mock implements VocabularyRepository {}
class MockAiProvider extends Mock implements AiProvider {}

void main() {
  late MockVocabularyRepository mockVocabularyRepository;
  late MockAiProvider mockAiProvider;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      VocabularyWord(
        word: '',
        definition: '',
        example: '',
        difficulty: '',
        addedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockVocabularyRepository = MockVocabularyRepository();
    mockAiProvider = MockAiProvider();

    // Default mock behavior
    when(() => mockVocabularyRepository.getSavedWords()).thenAnswer((_) => Future.value([]));
    when(() => mockVocabularyRepository.saveWord(any())).thenAnswer((_) => Future.value());
    when(() => mockVocabularyRepository.deleteWord(any())).thenAnswer((_) => Future.value());

    container = ProviderContainer(
      overrides: [
        vocabularyRepositoryProvider.overrideWithValue(mockVocabularyRepository),
        aiProvider.overrideWithValue(mockAiProvider),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('VocabularyNotifier Tests', () {
    test('initial state loads saved words from database', () async {
      final initialWord = VocabularyWord(
        id: 1,
        word: 'Acquire',
        definition: 'Obtain',
        example: 'Acquire skills',
        difficulty: 'Intermediate',
        addedAt: DateTime.now(),
      );

      when(() => mockVocabularyRepository.getSavedWords()).thenAnswer((_) => Future.value([initialWord]));

      // Read to trigger build()
      container.read(vocabularyNotifierProvider);

      // Wait for initial SQLite fetch microtask
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(vocabularyNotifierProvider);
      expect(state.savedWords.length, equals(1));
      expect(state.savedWords.first.word, equals('Acquire'));
      expect(state.isLoadingSaved, isFalse);
    });

    test('generateSuggestions fetches words from AI provider', () async {
      final mockSuggestions = [
        AiVocabularyWord(
          word: 'Travel',
          definition: 'Journey',
          example: 'I love travel',
          difficulty: 'Beginner',
        )
      ];

      when(() => mockAiProvider.suggestVocabulary('travel', difficulty: 'Beginner'))
          .thenAnswer((_) => Future.value(mockSuggestions));

      // Trigger provider build
      container.read(vocabularyNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 10));

      final notifier = container.read(vocabularyNotifierProvider.notifier);
      await notifier.generateSuggestions('travel', difficulty: 'Beginner');

      final state = container.read(vocabularyNotifierProvider);
      expect(state.suggestions.length, equals(1));
      expect(state.suggestions.first.word, equals('Travel'));
      expect(state.isLoadingSuggestions, isFalse);
    });

    test('saveWord invokes repository insert and reloads list', () async {
      final newWord = AiVocabularyWord(
        word: 'Gourmet',
        definition: 'Fine food',
        example: 'Gourmet dining',
        difficulty: 'Advanced',
      );

      // Trigger provider build
      container.read(vocabularyNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 10));

      final notifier = container.read(vocabularyNotifierProvider.notifier);
      
      // We expect saveWord to call repository insert
      await notifier.saveWord(newWord);
      await Future.delayed(const Duration(milliseconds: 10));

      verify(() => mockVocabularyRepository.saveWord(any())).called(1);
      verify(() => mockVocabularyRepository.getSavedWords()).called(2); // Initial build + reload
    });
  });
}
