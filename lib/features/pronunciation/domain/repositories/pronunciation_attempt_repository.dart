import '../models/pronunciation_attempt.dart';

/// Persistence boundary for per-attempt pronunciation scoring
/// history. Implementations are responsible for surfacing backend
/// errors via thrown exceptions; view models catch them at the
/// boundary and degrade gracefully (see `knowledge/coding_standards.md`
/// "Error Handling").
abstract class PronunciationAttemptRepository {
  /// Persists [attempt]. When [attempt.id] is null a new row is
  /// inserted and the resulting id is ignored (callers that need
  /// the id can read it back via [recentAttempts]).
  Future<void> recordAttempt(PronunciationAttempt attempt);

  /// Returns up to [limit] most-recent attempts, newest first.
  /// Defaults to 50 when [limit] is not provided.
  Future<List<PronunciationAttempt>> recentAttempts({int limit = 50});
}