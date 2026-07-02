import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Schema version. Bump when adding a new table or migrating an
  // existing one, AND add a corresponding `onUpgrade` branch.
  static const int _schemaVersion = 2;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fluent_arc.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Local vocabulary history (schema v1).
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
    // Per-attempt pronunciation scoring history (schema v2).
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Each branch is gated on the FROM version so incremental
    // upgrades from any prior version land in the right schema.
    if (oldVersion < 2) {
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
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}