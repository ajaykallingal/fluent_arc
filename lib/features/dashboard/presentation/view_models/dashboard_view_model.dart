import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../progress/presentation/view_models/progress_view_model.dart';
import '../../../vocabulary/presentation/view_models/vocabulary_view_model.dart';

class DashboardStats {
  final int streakDays;
  final int overallProgress; // 0 to 100
  final double grammarScore; // 0 to 100
  final double speakingScore; // 0 to 100
  final int vocabularyCount;

  const DashboardStats({
    required this.streakDays,
    required this.overallProgress,
    required this.grammarScore,
    required this.speakingScore,
    required this.vocabularyCount,
  });

  factory DashboardStats.initial() {
    return const DashboardStats(
      streakDays: 3,
      overallProgress: 45,
      grammarScore: 78.0,
      speakingScore: 82.0,
      vocabularyCount: 15,
    );
  }
}

class DashboardViewModel extends Notifier<DashboardStats> {
  @override
  DashboardStats build() {
    final progressState = ref.watch(progressNotifierProvider);
    final vocabState = ref.watch(vocabularyNotifierProvider);

    final progress = progressState.progress;
    if (progress != null) {
      // Calculate speaking score mock rating
      final speakScore = progress.speakingSessionsCount > 0 ? 82.0 : 0.0;
      final overall = ((progress.grammarScoreAverage + speakScore) / 2).toInt();

      return DashboardStats(
        streakDays: progress.streakDays,
        overallProgress: overall == 0 ? 25 : overall, // Minimum progress visual
        grammarScore: progress.grammarScoreAverage,
        speakingScore: speakScore,
        vocabularyCount: vocabState.savedWords.length,
      );
    }

    return DashboardStats.initial();
  }

  void refreshStats() {
    // Intentionally left blank for reactive Notifier flow
  }
}

final dashboardViewModelProvider =
    NotifierProvider<DashboardViewModel, DashboardStats>(() {
      return DashboardViewModel();
    });
