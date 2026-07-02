/// Plain-Dart record of a single pronunciation scoring attempt.
///
/// Persisted to the `pronunciation_attempts` SQLite table introduced
/// in schema v2. Has no Flutter imports; serializes via [toMap] /
/// [fromMap] for sqflite.
class PronunciationAttempt {
  // null when the row has not been persisted yet; populated by the
  // SQLite autoincrement column on insert.
  final int? id;
  final String targetPhrase;
  final String spokenText;
  final int overallScore;
  final int accuracyScore;
  final int fluencyScore;
  final int completenessScore;
  // 'offline-local' or 'remote' — matches the engine field on
  // PronunciationAnalysisResult.
  final String engine;
  final DateTime attemptedAt;

  const PronunciationAttempt({
    this.id,
    required this.targetPhrase,
    required this.spokenText,
    required this.overallScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.engine,
    required this.attemptedAt,
  });

  PronunciationAttempt copyWith({int? id}) => PronunciationAttempt(
        id: id ?? this.id,
        targetPhrase: targetPhrase,
        spokenText: spokenText,
        overallScore: overallScore,
        accuracyScore: accuracyScore,
        fluencyScore: fluencyScore,
        completenessScore: completenessScore,
        engine: engine,
        attemptedAt: attemptedAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'targetPhrase': targetPhrase,
        'spokenText': spokenText,
        'overallScore': overallScore,
        'accuracyScore': accuracyScore,
        'fluencyScore': fluencyScore,
        'completenessScore': completenessScore,
        'engine': engine,
        // SQLite has no DateTime type — store ISO-8601 strings.
        'attemptedAt': attemptedAt.toIso8601String(),
      };

  factory PronunciationAttempt.fromMap(Map<String, Object?> map) {
    return PronunciationAttempt(
      id: map['id'] as int?,
      targetPhrase: map['targetPhrase'] as String? ?? '',
      spokenText: map['spokenText'] as String? ?? '',
      overallScore: map['overallScore'] as int? ?? 0,
      accuracyScore: map['accuracyScore'] as int? ?? 0,
      fluencyScore: map['fluencyScore'] as int? ?? 0,
      completenessScore: map['completenessScore'] as int? ?? 0,
      engine: map['engine'] as String? ?? 'remote',
      attemptedAt:
          DateTime.tryParse(map['attemptedAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}