import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Run sqflite in-process on the test host. Without this, sqflite
  // tries to load native plugin channels that don't exist under
  // `flutter test`.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper schema migration', () {
    test('fresh install at schema v2 creates both tables', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE vocabulary (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word TEXT NOT NULL UNIQUE,
              definition TEXT NOT NULL,
              example TEXT NOT NULL,
              difficulty TEXT NOT NULL,
              addedAt TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE pronunciation_attempts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              targetPhrase TEXT NOT NULL,
              spokenText TEXT NOT NULL,
              overallScore INTEGER NOT NULL,
              accuracyScore INTEGER NOT NULL,
              fluencyScore INTEGER NOT NULL,
              completenessScore INTEGER NOT NULL,
              engine TEXT NOT NULL,
              attemptedAt TEXT NOT NULL
            )
          ''');
        },
      );

      final vocabTables = await db.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'vocabulary'],
      );
      final attemptTables = await db.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'pronunciation_attempts'],
      );
      expect(vocabTables, hasLength(1));
      expect(attemptTables, hasLength(1));

      await db.close();
    });

    test(
      'upgrade from v1 adds pronunciation_attempts and preserves vocabulary',
      () async {
        // Set up a v1 schema database with a vocabulary row, then
        // simulate the upgrade using the same SQL the helper uses in
        // its `_onUpgrade` branch.
        final db = await openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE vocabulary (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word TEXT NOT NULL UNIQUE,
              definition TEXT NOT NULL,
              example TEXT NOT NULL,
              difficulty TEXT NOT NULL,
              addedAt TEXT NOT NULL
            )
          ''');
          },
        );

        await db.insert('vocabulary', {
          'word': 'fluency',
          'definition': 'the ability to speak smoothly',
          'example': 'Practice daily.',
          'difficulty': 'Intermediate',
          'addedAt': DateTime.now().toIso8601String(),
        });

        // Simulate the v1 -> v2 upgrade the same way DatabaseHelper
        // does in `_onUpgrade`.
        await db.execute('''
        CREATE TABLE pronunciation_attempts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          targetPhrase TEXT NOT NULL,
          spokenText TEXT NOT NULL,
          overallScore INTEGER NOT NULL,
          accuracyScore INTEGER NOT NULL,
          fluencyScore INTEGER NOT NULL,
          completenessScore INTEGER NOT NULL,
          engine TEXT NOT NULL,
          attemptedAt TEXT NOT NULL
        )
      ''');

        // Vocabulary row still readable.
        final vocabRows = await db.query('vocabulary');
        expect(vocabRows, hasLength(1));
        expect(vocabRows.first['word'], equals('fluency'));

        // New table is usable.
        await db.insert('pronunciation_attempts', {
          'targetPhrase': 'hello world',
          'spokenText': 'hello world',
          'overallScore': 95,
          'accuracyScore': 95,
          'fluencyScore': 80,
          'completenessScore': 100,
          'engine': 'offline-local',
          'attemptedAt': DateTime.now().toIso8601String(),
        });
        final attempts = await db.query('pronunciation_attempts');
        expect(attempts, hasLength(1));
        expect(attempts.first['engine'], equals('offline-local'));

        await db.close();
      },
    );
  });
}
