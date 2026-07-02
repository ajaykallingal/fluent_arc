import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/repositories/progress_repository.dart';

class SupabaseProgressRepository implements ProgressRepository {
  final SupabaseClient? _supabaseClient;
  final bool _isBackendEnabled;

  // Local fallback cache
  final Map<String, UserProgress> _localCache = {};

  SupabaseProgressRepository({
    SupabaseClient? supabaseClient,
    bool isBackendEnabled = true,
  })  : _supabaseClient = supabaseClient,
        _isBackendEnabled = isBackendEnabled;

  @override
  Future<UserProgress> getUserProgress(String userId) async {
    if (_isBackendEnabled && _supabaseClient != null) {
      try {
        final response = await _supabaseClient!
            .from('user_progress')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
            
        if (response != null) {
          return UserProgress.fromJson(response);
        }
      } catch (_) {
        // Fallback to local cache
      }
    }
    return _localCache.putIfAbsent(userId, () => UserProgress.initial(userId));
  }

  @override
  Future<void> saveUserProgress(UserProgress progress) async {
    _localCache[progress.uid] = progress;
    if (_isBackendEnabled && _supabaseClient != null) {
      try {
        final data = progress.toJson();
        data['user_id'] = progress.uid; // Mapping key
        await _supabaseClient!
            .from('user_progress')
            .upsert(data);
      } catch (_) {
        // Handled via local cache
      }
    }
  }

  @override
  Future<void> incrementSpeakingSession(String userId) async {
    final current = await getUserProgress(userId);
    final updated = current.copyWith(
      speakingSessionsCount: current.speakingSessionsCount + 1,
      lastActiveDate: DateTime.now(),
    );
    await saveUserProgress(updated);
  }

  @override
  Future<void> updateGrammarScore(String userId, double newScore) async {
    final current = await getUserProgress(userId);
    final currentAvg = current.grammarScoreAverage;
    final totalChecks = current.lessonsCompleted;
    final newAvg = ((currentAvg * totalChecks) + newScore) / (totalChecks + 1);

    final updated = current.copyWith(
      lessonsCompleted: totalChecks + 1,
      grammarScoreAverage: double.parse(newAvg.toStringAsFixed(1)),
      lastActiveDate: DateTime.now(),
    );
    await saveUserProgress(updated);
  }
}
