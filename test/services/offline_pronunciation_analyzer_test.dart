import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_arc/features/pronunciation/data/services/offline_pronunciation_analyzer.dart';

void main() {
  late OfflinePronunciationAnalyzer analyzer;

  setUp(() {
    analyzer = OfflinePronunciationAnalyzer();
  });

  group('OfflinePronunciationAnalyzer', () {
    test('engine id is offline-local', () async {
      final result =
          await analyzer.analyze('hello world', 'hello world');
      expect(result.engine, equals('offline-local'));
    });

    test('identical inputs produce identical scores (determinism / AC #6)',
        () async {
      final a = await analyzer.analyze(
        'I would like to acquire native fluency',
        'I would like to acquire native fluency',
      );
      final b = await analyzer.analyze(
        'I would like to acquire native fluency',
        'I would like to acquire native fluency',
      );
      expect(a.overallScore, equals(b.overallScore));
      expect(a.accuracyScore, equals(b.accuracyScore));
      expect(a.fluencyScore, equals(b.fluencyScore));
      expect(a.completenessScore, equals(b.completenessScore));
      expect(a.engine, equals(b.engine));
    });

    test('empty spoken text returns a zero-score result, not a throw (AC #3)',
        () async {
      final result = await analyzer.analyze('hello world', '');
      expect(result.overallScore, equals(0));
      expect(result.accuracyScore, equals(0));
      expect(result.completenessScore, equals(0));
      expect(result.engine, equals('offline-local'));
      expect(result.generalFeedback, contains('No speech'));
    });

    test('empty target text throws ArgumentError', () async {
      // Per the plan, an empty target text is a programmer error and
      // throws; empty spoken text is a runtime condition and is
      // returned as a zero-score result.
      expect(
        () => analyzer.analyze('', 'hello'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('populates all four sub-scores and engine', () async {
      final result =
          await analyzer.analyze('hello world', 'hello world');
      expect(result.accuracyScore, inInclusiveRange(0, 100));
      expect(result.fluencyScore, inInclusiveRange(0, 100));
      expect(result.completenessScore, inInclusiveRange(0, 100));
      expect(result.engine, equals('offline-local'));
    });

    test('perfect match scores 100 for completeness; overall is the per-word average',
        () async {
      final result =
          await analyzer.analyze('one two three', 'one two three');
      // Every word matched → completeness is exactly 100.
      expect(result.completenessScore, equals(100));
      // Per-word score is 95 in the offline heuristic, so overall
      // (mean of word scores) is 95, not 100. Documented behavior.
      expect(result.overallScore, equals(95));
    });

    test('partial match scores partial completeness', () async {
      // Three target words, only one spoken — completeness ≈ 33.
      final result =
          await analyzer.analyze('one two three', 'one');
      expect(result.completenessScore, lessThanOrEqualTo(50));
    });

    test('word-level scoring marks missing words with low score', () async {
      final result = await analyzer.analyze('apple banana cherry', 'apple');
      final banana = result.words.firstWhere((w) => w.word == 'banana');
      final cherry = result.words.firstWhere((w) => w.word == 'cherry');
      expect(banana.score, lessThanOrEqualTo(50));
      expect(cherry.score, lessThanOrEqualTo(50));
      expect(banana.feedback, contains('missing'));
    });
  });
}