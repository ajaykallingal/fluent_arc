import '../models/grammar_report.dart';

abstract class GrammarRepository {
  Future<GrammarReport> checkSentence(String text);
}
