import '../models/vocabulary_word.dart';

abstract class VocabularyRepository {
  Future<List<VocabularyWord>> getSavedWords();

  Future<void> saveWord(VocabularyWord word);

  Future<void> deleteWord(String word);

  Future<bool> isWordSaved(String word);
}
