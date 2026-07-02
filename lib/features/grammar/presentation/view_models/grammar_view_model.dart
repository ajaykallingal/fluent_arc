import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai/ai_provider.dart';
import '../../../progress/presentation/view_models/progress_view_model.dart';
import '../../data/repositories/ai_grammar_repository.dart';
import '../../domain/models/grammar_report.dart';
import '../../domain/repositories/grammar_repository.dart';

final grammarRepositoryProvider = Provider<GrammarRepository>((ref) {
  final ai = ref.watch(aiProvider);
  return AiGrammarRepository(aiProvider: ai);
});

class GrammarState {
  final GrammarReport? report;
  final bool isLoading;
  final String? errorMessage;

  const GrammarState({
    this.report,
    required this.isLoading,
    this.errorMessage,
  });

  factory GrammarState.initial() => const GrammarState(isLoading: false);
}

class GrammarNotifier extends Notifier<GrammarState> {
  late final GrammarRepository _repository;

  @override
  GrammarState build() {
    _repository = ref.watch(grammarRepositoryProvider);
    return GrammarState.initial();
  }

  Future<void> checkGrammar(String text) async {
    if (text.trim().isEmpty) return;
    state = const GrammarState(isLoading: true);

    try {
      final report = await _repository.checkSentence(text);
      if (ref.mounted) {
        state = GrammarState(report: report, isLoading: false);
        ref.read(progressNotifierProvider.notifier).recordGrammarCheck(report.score.toDouble());
      }
    } catch (e) {
      if (ref.mounted) {
        state = GrammarState(
          isLoading: false,
          errorMessage: 'Failed to analyze grammar. Please try again.',
        );
      }
    }
  }

  void reset() {
    state = GrammarState.initial();
  }
}

final grammarNotifierProvider = NotifierProvider<GrammarNotifier, GrammarState>(() {
  return GrammarNotifier();
});
