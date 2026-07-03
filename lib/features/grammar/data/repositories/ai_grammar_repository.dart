import '../../../../core/services/ai/ai_provider.dart';
import '../../domain/models/grammar_report.dart';
import '../../domain/repositories/grammar_repository.dart';

class AiGrammarRepository implements GrammarRepository {
  final AiProvider _aiProvider;

  AiGrammarRepository({required AiProvider aiProvider})
    : _aiProvider = aiProvider;

  @override
  Future<GrammarReport> checkSentence(String text) async {
    final analysis = await _aiProvider.analyzeGrammar(text);
    return GrammarReport(
      originalText: analysis.originalSentence,
      correctedText: analysis.correctedSentence,
      explanation: analysis.explanation,
      score: analysis.grammarScore,
    );
  }
}
