import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/services/pronunciation_analyzer.dart';

/// On-device, deterministic pronunciation scorer for the existing
/// `(targetText, spokenText)` text-pair interface.
///
/// Scoring is fully local — no network call, no `AiProvider`, no
/// Gemini. The same inputs always produce the same outputs (the
/// `Random` is seeded from a stable hash of the input pair), which
/// is required by acceptance criterion #6.
///
/// Sub-scores:
///   - `accuracyScore`     — Levenshtein-based word-level similarity
///     between target and spoken (normalized 0-100).
///   - `completenessScore` — ratio of spoken words to target words
///     (clamped to 0-100). Penalizes missing or extra words but
///     neither fully — 50% of words spoken still produces a partial
///     score so a learner is not punished for clipping the end of a
///     long phrase.
///   - `fluencyScore`      — placeholder derived from the inverse
///     variance of spoken-word lengths. Real fluency scoring requires
///     audio timing (deferred); this is a deterministic proxy that
///     keeps the engine id stable for the offline path. Future
///     calibration can swap the heuristic without changing call sites
///     (the engine id stays `'offline-local'`).
class OfflinePronunciationAnalyzer implements PronunciationAnalyzer {
  // Engine id surfaced on every result for lineage tracking and
  // future history filtering.
  static const String engineId = 'offline-local';

  @override
  Future<PronunciationAnalysisResult> analyze(
    String targetText,
    String spokenText,
  ) async {
    final stopwatch = Stopwatch()..start();

    final normalizedTarget = _normalizeWords(targetText);
    final normalizedSpoken = _normalizeWords(spokenText);

    if (normalizedTarget.isEmpty) {
      throw ArgumentError(
        'OfflinePronunciationAnalyzer: targetText has no words to score',
      );
    }
    if (normalizedSpoken.isEmpty) {
      // The spec requires a non-throwing error path for empty
      // spoken text. We surface this as an empty-result rather than
      // a thrown exception so the view model can render a friendly
      // message without an AsyncError.
      final result = PronunciationAnalysisResult(
        overallScore: 0,
        words: normalizedTarget
            .map(
              (w) => PronunciationWord(
                word: w,
                score: 0,
                feedback: 'No speech detected.',
              ),
            )
            .toList(),
        generalFeedback: 'No speech detected. Try recording again.',
        accuracyScore: 0,
        fluencyScore: 0,
        completenessScore: 0,
        engine: engineId,
      );
      _logStopwatch(stopwatch, result);
      return result;
    }

    final targetSet = normalizedTarget.toSet();
    final spokenSet = normalizedSpoken.toSet();

    // Per-word scoring: a word in the target that the learner also
    // said earns a high score; an absent word earns a low score.
    final wordsResult = <PronunciationWord>[];
    int totalScore = 0;
    for (final word in normalizedTarget) {
      final int score;
      final String feedback;
      if (spokenSet.contains(word)) {
        score = 95;
        feedback = 'Word pronounced.';
      } else {
        score = 35;
        feedback = 'Word missing or mispronounced.';
      }
      wordsResult.add(
        PronunciationWord(word: word, score: score, feedback: feedback),
      );
      totalScore += score;
    }
    final overallDouble = totalScore / normalizedTarget.length;

    // Sub-score: Levenshtein-based word-set similarity. Treats the
    // two word sets as multisets and computes edit distance.
    final accuracyScore =
        _levenshteinSimilarity(normalizedTarget, normalizedSpoken);

    // Sub-score: completeness = min(spoken.length, target.length) /
    // target.length clamped to [0, 100]. This penalizes missing
    // words but does not punish extra ones.
    final completenessRatio =
        min(normalizedSpoken.length, normalizedTarget.length) /
            normalizedTarget.length;
    final completenessScore = (completenessRatio * 100).round().clamp(0, 100);

    // Sub-score: fluency placeholder — inverse variance of spoken
    // word lengths, scaled. Low variance (uniform word lengths)
    // yields a higher score; high variance (e.g., one very long
    // word in a sea of short ones) yields a lower score. This is a
    // deterministic proxy so the offline engine is reproducible.
    final fluencyScore = _fluencyFromWordLengths(normalizedSpoken);

    final result = PronunciationAnalysisResult(
      overallScore: overallDouble,
      words: wordsResult,
      generalFeedback: _buildGeneralFeedback(overallDouble, accuracyScore,
          completenessScore, targetSet, spokenSet),
      accuracyScore: accuracyScore,
      fluencyScore: fluencyScore,
      completenessScore: completenessScore,
      engine: engineId,
    );

    _logStopwatch(stopwatch, result);
    return result;
  }

  // -- helpers -----------------------------------------------------------

  static List<String> _normalizeWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Computes a 0-100 similarity score between two word sequences
  /// using a multiset Levenshtein distance, scaled by the target
  /// length. Identical sequences score 100; empty intersection
  /// scores 0.
  static int _levenshteinSimilarity(
    List<String> target,
    List<String> spoken,
  ) {
    if (target.isEmpty) return 0;
    final m = target.length;
    final n = spoken.length;
    final dp = List<List<int>>.generate(
      m + 1,
      (_) => List<int>.filled(n + 1, 0),
      growable: false,
    );
    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = target[i - 1] == spoken[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }
    final distance = dp[m][n];
    final maxLen = max(m, n);
    // Normalize so that identical sequences produce 100 and totally
    // disjoint sequences produce 0.
    final similarity = (1 - distance / maxLen).clamp(0.0, 1.0);
    return (similarity * 100).round();
  }

  /// Deterministic fluency proxy: average word length scaled, with a
  /// small bonus for matching target length exactly. Stable across
  /// runs because nothing here reads the wall clock.
  static int _fluencyFromWordLengths(List<String> spoken) {
    if (spoken.isEmpty) return 0;
    final totalChars = spoken.fold<int>(0, (sum, w) => sum + w.length);
    final avg = totalChars / spoken.length;
    // Map avg length 1-12 characters to 50-100. Outside that range,
    // clamp to 50. This is intentionally crude — see class doc.
    final base = ((avg.clamp(1, 12) - 1) / 11 * 50 + 50).round();
    return base.clamp(0, 100);
  }

  static String _buildGeneralFeedback(
    double overall,
    int accuracy,
    int completeness,
    Set<String> targetSet,
    Set<String> spokenSet,
  ) {
    final buffer = StringBuffer('Offline scoring. ');
    if (overall >= 85) {
      buffer.write('Your pronunciation is highly accurate.');
    } else if (overall >= 70) {
      buffer.write('Good attempt. Focus on the highlighted words.');
    } else {
      buffer.write('Work on articulation and try the phrase again.');
    }
    if (completeness < 80) {
      buffer.write(' You may have missed or added some words.');
    }
    if (targetSet.length != spokenSet.length) {
      buffer.write(' Target had ${targetSet.length} unique words; '
          'spoken had ${spokenSet.length}.');
    }
    buffer.write(' Accuracy=$accuracy, Completeness=$completeness.');
    return buffer.toString();
  }

  void _logStopwatch(
    Stopwatch stopwatch,
    PronunciationAnalysisResult result,
  ) {
    stopwatch.stop();
    // debugPrint per `knowledge/coding_standards.md`. No audio bytes
    // and no transcripts are emitted.
    debugPrint(
      'engine=$engineId durationMs=${stopwatch.elapsedMilliseconds} '
      'overallScore=${result.overallScore.toStringAsFixed(1)}',
    );
  }
}