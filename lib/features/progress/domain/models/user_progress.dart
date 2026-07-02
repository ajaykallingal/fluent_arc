class UserProgress {
  final String uid;
  final int lessonsCompleted;
  final double grammarScoreAverage;
  final int vocabularyLearnedCount;
  final int speakingSessionsCount;
  final int streakDays;
  final DateTime lastActiveDate;

  const UserProgress({
    required this.uid,
    required this.lessonsCompleted,
    required this.grammarScoreAverage,
    required this.vocabularyLearnedCount,
    required this.speakingSessionsCount,
    required this.streakDays,
    required this.lastActiveDate,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'lessonsCompleted': lessonsCompleted,
        'grammarScoreAverage': grammarScoreAverage,
        'vocabularyLearnedCount': vocabularyLearnedCount,
        'speakingSessionsCount': speakingSessionsCount,
        'streakDays': streakDays,
        'lastActiveDate': lastActiveDate.toIso8601String(),
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      uid: json['uid'] as String? ?? '',
      lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
      grammarScoreAverage: (json['grammarScoreAverage'] as num?)?.toDouble() ?? 0.0,
      vocabularyLearnedCount: json['vocabularyLearnedCount'] as int? ?? 0,
      speakingSessionsCount: json['speakingSessionsCount'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'] as String)
          : DateTime.now(),
    );
  }

  factory UserProgress.initial(String uid) {
    return UserProgress(
      uid: uid,
      lessonsCompleted: 4,
      grammarScoreAverage: 78.0,
      vocabularyLearnedCount: 15,
      speakingSessionsCount: 6,
      streakDays: 3,
      lastActiveDate: DateTime.now(),
    );
  }

  UserProgress copyWith({
    int? lessonsCompleted,
    double? grammarScoreAverage,
    int? vocabularyLearnedCount,
    int? speakingSessionsCount,
    int? streakDays,
    DateTime? lastActiveDate,
  }) {
    return UserProgress(
      uid: uid,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      grammarScoreAverage: grammarScoreAverage ?? this.grammarScoreAverage,
      vocabularyLearnedCount: vocabularyLearnedCount ?? this.vocabularyLearnedCount,
      speakingSessionsCount: speakingSessionsCount ?? this.speakingSessionsCount,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}
