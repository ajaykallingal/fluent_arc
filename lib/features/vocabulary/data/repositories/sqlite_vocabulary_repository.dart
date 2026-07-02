import 'package:sqflite/sqflite.dart';
import '../../../../core/services/storage/database_helper.dart';
import '../../domain/models/vocabulary_word.dart';
import '../../domain/repositories/vocabulary_repository.dart';

class SqliteVocabularyRepository implements VocabularyRepository {
  final DatabaseHelper _dbHelper;

  SqliteVocabularyRepository({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<List<VocabularyWord>> getSavedWords() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('vocabulary', orderBy: 'addedAt DESC');
      return maps.map((map) => VocabularyWord.fromMap(map)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveWord(VocabularyWord word) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'vocabulary',
        word.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (_) {
      // Handle silently for MVP
    }
  }

  @override
  Future<void> deleteWord(String word) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'vocabulary',
        where: 'word = ?',
        whereArgs: [word],
      );
    } catch (_) {
      // Handle silently
    }
  }

  @override
  Future<bool> isWordSaved(String word) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'vocabulary',
        where: 'word = ?',
        whereArgs: [word],
      );
      return maps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
