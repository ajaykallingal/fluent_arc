import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai/ai_provider.dart';
import '../../../../core/services/storage/database_helper.dart';
import '../../data/repositories/sqlite_vocabulary_repository.dart';
import '../../domain/models/vocabulary_word.dart';
import '../../domain/repositories/vocabulary_repository.dart';

final dbHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  final dbHelper = ref.watch(dbHelperProvider);
  return SqliteVocabularyRepository(dbHelper: dbHelper);
});

class VocabularyState {
  final List<VocabularyWord> savedWords;
  final List<AiVocabularyWord> suggestions;
  final bool isLoadingSaved;
  final bool isLoadingSuggestions;
  final String? errorMessage;

  const VocabularyState({
    required this.savedWords,
    required this.suggestions,
    required this.isLoadingSaved,
    required this.isLoadingSuggestions,
    this.errorMessage,
  });

  factory VocabularyState.initial() => const VocabularyState(
        savedWords: [],
        suggestions: [],
        isLoadingSaved: false,
        isLoadingSuggestions: false,
      );

  VocabularyState copyWith({
    List<VocabularyWord>? savedWords,
    List<AiVocabularyWord>? suggestions,
    bool? isLoadingSaved,
    bool? isLoadingSuggestions,
    String? errorMessage,
  }) {
    return VocabularyState(
      savedWords: savedWords ?? this.savedWords,
      suggestions: suggestions ?? this.suggestions,
      isLoadingSaved: isLoadingSaved ?? this.isLoadingSaved,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VocabularyNotifier extends Notifier<VocabularyState> {
  late final VocabularyRepository _repository;
  late final AiProvider _aiProvider;

  @override
  VocabularyState build() {
    _repository = ref.watch(vocabularyRepositoryProvider);
    _aiProvider = ref.watch(aiProvider);
    
    _loadSavedWords();
    return VocabularyState.initial();
  }

  void _loadSavedWords() {
    Future.microtask(() async {
      if (!ref.mounted) return;
      state = state.copyWith(isLoadingSaved: true);
      try {
        final saved = await _repository.getSavedWords();
        if (ref.mounted) {
          state = state.copyWith(savedWords: saved, isLoadingSaved: false);
        }
      } catch (_) {
        if (ref.mounted) {
          state = state.copyWith(isLoadingSaved: false, errorMessage: 'Failed to load saved vocabulary.');
        }
      }
    });
  }

  Future<void> generateSuggestions(String topic, {String difficulty = 'Intermediate'}) async {
    if (topic.trim().isEmpty) return;
    state = state.copyWith(isLoadingSuggestions: true, errorMessage: null);

    try {
      final suggested = await _aiProvider.suggestVocabulary(topic, difficulty: difficulty);
      if (ref.mounted) {
        state = state.copyWith(suggestions: suggested, isLoadingSuggestions: false);
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          isLoadingSuggestions: false,
          errorMessage: 'Failed to fetch suggestions from AI Tutor.',
        );
      }
    }
  }

  Future<void> saveWord(AiVocabularyWord word) async {
    final vocabWord = VocabularyWord(
      word: word.word,
      definition: word.definition,
      example: word.example,
      difficulty: word.difficulty,
      addedAt: DateTime.now(),
    );

    await _repository.saveWord(vocabWord);
    _loadSavedWords();
  }

  Future<void> deleteWord(String word) async {
    await _repository.deleteWord(word);
    _loadSavedWords();
  }
}

final vocabularyNotifierProvider = NotifierProvider<VocabularyNotifier, VocabularyState>(() {
  return VocabularyNotifier();
});
