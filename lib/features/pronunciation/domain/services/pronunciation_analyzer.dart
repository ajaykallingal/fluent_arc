class PronunciationWord {
  final String word;
  final int score; // 0 to 100
  final String feedback;

  const PronunciationWord({
    required this.word,
    required this.score,
    required this.feedback,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'score': score,
        'feedback': feedback,
      };
}

class PronunciationAnalysisResult {
  final double overallScore;
  final List<PronunciationWord> words;
  final String generalFeedback;
  // Optional sub-scores introduced for offline / hybrid scoring.
  // Defaults preserve backwards compatibility with existing call
  // sites (mock + any future remote implementations).
  final int accuracyScore;
  final int fluencyScore;
  final int completenessScore;
  // Identifier for the engine that produced this result.
  // 'offline-local' for on-device scorers, 'remote' for any
  // remote-backed scorer (Gemini today, mock today, future
  // services). Defaults to 'remote' so pre-existing UI does not
  // see null.
  final String engine;

  const PronunciationAnalysisResult({
    required this.overallScore,
    required this.words,
    required this.generalFeedback,
    this.accuracyScore = 100,
    this.fluencyScore = 100,
    this.completenessScore = 100,
    this.engine = 'remote',
  });

  Map<String, dynamic> toJson() => {
        'overallScore': overallScore,
        'words': words.map((w) => w.toJson()).toList(),
        'generalFeedback': generalFeedback,
        'accuracyScore': accuracyScore,
        'fluencyScore': fluencyScore,
        'completenessScore': completenessScore,
        'engine': engine,
      };
}

abstract class PronunciationAnalyzer {
  Future<PronunciationAnalysisResult> analyze(String targetText, String spokenText);
}