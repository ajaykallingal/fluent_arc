import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../data/repositories/supabase_progress_repository.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/repositories/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final isBackendEnabled = supabaseClient != null;
  return SupabaseProgressRepository(
    supabaseClient: supabaseClient,
    isBackendEnabled: isBackendEnabled,
  );
});

class ProgressState {
  final UserProgress? progress;
  final bool isLoading;
  final String? errorMessage;

  const ProgressState({
    this.progress,
    required this.isLoading,
    this.errorMessage,
  });

  factory ProgressState.initial() => const ProgressState(isLoading: false);
}

class ProgressNotifier extends Notifier<ProgressState> {
  late final ProgressRepository _repository;
  String? _userId;

  @override
  ProgressState build() {
    _repository = ref.watch(progressRepositoryProvider);

    final authState = ref.watch(authNotifierProvider);
    if (authState.status == AuthStatus.authenticated &&
        authState.user != null) {
      _userId = authState.user!.uid;
      _loadProgress();
    } else {
      _userId = null;
    }

    return ProgressState.initial();
  }

  void _loadProgress() {
    Future.microtask(() async {
      if (_userId == null || !ref.mounted) return;
      state = const ProgressState(isLoading: true);
      try {
        final progress = await _repository.getUserProgress(_userId!);
        if (ref.mounted) {
          state = ProgressState(progress: progress, isLoading: false);
        }
      } catch (e) {
        if (ref.mounted) {
          state = ProgressState(
            isLoading: false,
            errorMessage: 'Failed to load progress.',
          );
        }
      }
    });
  }

  Future<void> recordSpeakingSession() async {
    if (_userId == null) return;
    await _repository.incrementSpeakingSession(_userId!);
    _loadProgress();
  }

  Future<void> recordGrammarCheck(double score) async {
    if (_userId == null) return;
    await _repository.updateGrammarScore(_userId!, score);
    _loadProgress();
  }
}

final progressNotifierProvider =
    NotifierProvider<ProgressNotifier, ProgressState>(() {
      return ProgressNotifier();
    });
