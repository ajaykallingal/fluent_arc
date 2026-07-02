import '../models/user_progress.dart';

abstract class ProgressRepository {
  Future<UserProgress> getUserProgress(String userId);

  Future<void> saveUserProgress(UserProgress progress);

  Future<void> incrementSpeakingSession(String userId);

  Future<void> updateGrammarScore(String userId, double newScore);
}
