class VocabularyWord {
  final int? id;
  final String word;
  final String definition;
  final String example;
  final String difficulty;
  final DateTime addedAt;

  const VocabularyWord({
    this.id,
    required this.word,
    required this.definition,
    required this.example,
    required this.difficulty,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'word': word,
      'definition': definition,
      'example': example,
      'difficulty': difficulty,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory VocabularyWord.fromMap(Map<String, dynamic> map) {
    return VocabularyWord(
      id: map['id'] as int?,
      word: map['word'] as String? ?? '',
      definition: map['definition'] as String? ?? '',
      example: map['example'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'Intermediate',
      addedAt: map['addedAt'] != null
          ? DateTime.parse(map['addedAt'] as String)
          : DateTime.now(),
    );
  }
}
