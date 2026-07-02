class GrammarReport {
  final String originalText;
  final String correctedText;
  final String explanation;
  final int score;

  const GrammarReport({
    required this.originalText,
    required this.correctedText,
    required this.explanation,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'correctedText': correctedText,
      'explanation': explanation,
      'score': score,
    };
  }

  factory GrammarReport.fromJson(Map<String, dynamic> json) {
    return GrammarReport(
      originalText: json['originalText'] as String? ?? '',
      correctedText: json['correctedText'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      score: json['score'] as int? ?? 100,
    );
  }
}
