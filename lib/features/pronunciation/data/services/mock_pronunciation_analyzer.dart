import 'dart:math';
import '../../domain/services/pronunciation_analyzer.dart';

class MockPronunciationAnalyzer implements PronunciationAnalyzer {
  final Random _random = Random();

  @override
  Future<PronunciationAnalysisResult> analyze(
    String targetText,
    String spokenText,
  ) async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate remote analysis

    final cleanTarget = targetText.replaceAll(
      RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()]'),
      '',
    );
    final targetWords = cleanTarget
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    final cleanSpoken = spokenText.toLowerCase().replaceAll(
      RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()]'),
      '',
    );
    final spokenWords = cleanSpoken
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    final wordsResult = <PronunciationWord>[];
    double totalScore = 0.0;

    for (int i = 0; i < targetWords.length; i++) {
      final targetWord = targetWords[i];
      final targetLower = targetWord.toLowerCase();

      int score;
      String feedback = '';

      // Check if word exists in spoken phrase
      if (spokenWords.contains(targetLower)) {
        // For demonstration purposes, trigger a simulated accent correction on the third word
        if (i == 2 && targetWords.length > 2) {
          score = 58;
          feedback =
              'Shorten the vowel sound slightly. Ensure your tongue touches the roof of your mouth.';
        } else {
          score = 86 + _random.nextInt(14); // 86 to 99
          feedback = 'Excellent pronunciation!';
        }
      } else {
        score = 35 + _random.nextInt(20); // 35 to 55
        feedback =
            'Word was omitted or mispronounced. Practice repeating this sound.';
      }

      wordsResult.add(
        PronunciationWord(word: targetWord, score: score, feedback: feedback),
      );
      totalScore += score;
    }

    final overall = targetWords.isEmpty
        ? 100.0
        : totalScore / targetWords.length;

    // Mock sub-scores: keep behavior obviously synthetic (range 60-95)
    // so a real future remote scorer can be told apart from this one
    // even without inspecting `engine`. Mirrors OfflinePronunciationAnalyzer's
    // shape so UI never renders null.
    final accuracy = 60 + _random.nextInt(36);
    final completeness = 60 + _random.nextInt(36);
    final fluency = 60 + _random.nextInt(36);

    String generalFeedback = 'Good attempt! ';
    if (overall >= 85) {
      generalFeedback +=
          'Your pronunciation is highly accurate and flows naturally.';
    } else if (overall >= 70) {
      generalFeedback +=
          'Try to focus on the highlighted word with lower accuracy and repeat the sentence slowly.';
    } else {
      generalFeedback +=
          'Work on articulation and sentence speed. Take a breath between clauses.';
    }

    return PronunciationAnalysisResult(
      overallScore: overall,
      words: wordsResult,
      generalFeedback: generalFeedback,
      accuracyScore: accuracy,
      fluencyScore: fluency,
      completenessScore: completeness,
      engine: 'remote',
    );
  }
}
