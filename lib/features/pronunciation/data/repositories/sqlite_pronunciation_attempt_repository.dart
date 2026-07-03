import '../../../../core/services/storage/database_helper.dart';
import '../../domain/models/pronunciation_attempt.dart';
import '../../domain/repositories/pronunciation_attempt_repository.dart';

/// SQLite-backed implementation of [PronunciationAttemptRepository]
/// against the `pronunciation_attempts` table (schema v2).
///
/// Errors from the underlying sqflite call are allowed to propagate
/// per `knowledge/coding_standards.md` "Error Handling"; the view
/// model layer catches them and degrades gracefully.
class SqlitePronunciationAttemptRepository
    implements PronunciationAttemptRepository {
  final DatabaseHelper _helper;

  SqlitePronunciationAttemptRepository({DatabaseHelper? helper})
    : _helper = helper ?? DatabaseHelper.instance;

  @override
  Future<void> recordAttempt(PronunciationAttempt attempt) async {
    final db = await _helper.database;
    await db.insert(
      'pronunciation_attempts',
      attempt.toMap(),
      // conflictAlgorithm omitted — id is autoincrement and callers
      // supply null when inserting a new row.
    );
  }

  @override
  Future<List<PronunciationAttempt>> recentAttempts({int limit = 50}) async {
    final db = await _helper.database;
    final rows = await db.query(
      'pronunciation_attempts',
      orderBy: 'attemptedAt DESC',
      limit: limit,
    );
    return rows.map(PronunciationAttempt.fromMap).toList();
  }
}
