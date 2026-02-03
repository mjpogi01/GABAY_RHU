import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// Offline-first SQLite database
/// No data loss during interruptions
class DatabaseService {
  static Database? _db;
  static const String _dbName = 'gabay.db';
  static const int _version = 1;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    if (kIsWeb) {
      // For web, use in-memory database since file system is not available
      return openDatabase(
        inMemoryDatabasePath,
        version: _version,
        onCreate: _onCreate,
      );
    } else {
      // For mobile/desktop, use file-based database
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _dbName);
      return openDatabase(
        path,
        version: _version,
        onCreate: _onCreate,
      );
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        anonymizedId TEXT NOT NULL,
        role TEXT NOT NULL,
        rhuCode TEXT,
        barangayCode TEXT,
        createdAt TEXT NOT NULL,
        consentGiven INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE children (
        id TEXT PRIMARY KEY,
        caregiverId TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL,
        anonymizedChildId TEXT,
        FOREIGN KEY (caregiverId) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE modules (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        domain TEXT NOT NULL,
        ord INTEGER NOT NULL,
        cardsJson TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        pairedId TEXT NOT NULL,
        domain TEXT NOT NULL,
        text TEXT NOT NULL,
        optionsJson TEXT NOT NULL,
        correctIndex INTEGER NOT NULL,
        explanation TEXT,
        assessmentType TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE assessment_results (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        childId TEXT NOT NULL,
        type TEXT NOT NULL,
        domainScoresJson TEXT NOT NULL,
        domainTotalsJson TEXT NOT NULL,
        totalCorrect INTEGER NOT NULL,
        totalQuestions INTEGER NOT NULL,
        completedAt TEXT NOT NULL,
        responsesJson TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (childId) REFERENCES children(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE module_progress (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        childId TEXT NOT NULL,
        moduleId TEXT NOT NULL,
        completed INTEGER DEFAULT 0,
        timeSpentSeconds INTEGER DEFAULT 0,
        completedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (childId) REFERENCES children(id),
        FOREIGN KEY (moduleId) REFERENCES modules(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE assigned_modules (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        childId TEXT NOT NULL,
        moduleId TEXT NOT NULL,
        assignedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (childId) REFERENCES children(id),
        FOREIGN KEY (moduleId) REFERENCES modules(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        recordId TEXT NOT NULL,
        action TEXT NOT NULL,
        dataJson TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
