import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// Offline-first SQLite (users only; no children or preferences).
class DatabaseService {
  static Database? _db;
  static const String _dbName = 'gabay.db';
  static const int _version = 6;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    if (kIsWeb) {
      return openDatabase(
        inMemoryDatabasePath,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _dbName);
      return openDatabase(
        path,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN firstName TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN lastName TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN phoneNumber TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN address TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN status TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN numberOfChildren INTEGER');
      await db.execute('ALTER TABLE users ADD COLUMN idNumber TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN hasInfant INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('CREATE TABLE children_new (id TEXT PRIMARY KEY, caregiverId TEXT NOT NULL, dateOfBirth TEXT, anonymizedChildId TEXT, FOREIGN KEY (caregiverId) REFERENCES users(id))');
      await db.execute('INSERT INTO children_new SELECT id, caregiverId, dateOfBirth, anonymizedChildId FROM children');
      await db.execute('DROP TABLE children');
      await db.execute('ALTER TABLE children_new RENAME TO children');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE questions ADD COLUMN referenceModuleId TEXT');
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN domain TEXT');
      } catch (_) {
        // Column may already exist
      }
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN order_index INTEGER NOT NULL DEFAULT 0');
      } catch (_) {
        // Column may already exist (e.g. from fresh create at v6)
      }
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS assigned_modules');
      await db.execute('DROP TABLE IF EXISTS module_progress');
      await db.execute('DROP TABLE IF EXISTS assessment_results');
      await db.execute('DROP TABLE IF EXISTS children');
      await db.execute('''
        CREATE TABLE assessment_results (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          type TEXT NOT NULL,
          domainScoresJson TEXT NOT NULL,
          domainTotalsJson TEXT NOT NULL,
          totalCorrect INTEGER NOT NULL,
          totalQuestions INTEGER NOT NULL,
          completedAt TEXT NOT NULL,
          responsesJson TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE module_progress (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          moduleId TEXT NOT NULL,
          completed INTEGER DEFAULT 0,
          timeSpentSeconds INTEGER DEFAULT 0,
          completedAt TEXT,
          FOREIGN KEY (userId) REFERENCES users(id),
          FOREIGN KEY (moduleId) REFERENCES modules(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE assigned_modules (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          moduleId TEXT NOT NULL,
          assignedAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users(id),
          FOREIGN KEY (moduleId) REFERENCES modules(id)
        )
      ''');
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
        consentGiven INTEGER DEFAULT 1,
        firstName TEXT,
        lastName TEXT,
        phoneNumber TEXT,
        address TEXT,
        status TEXT,
        numberOfChildren INTEGER,
        idNumber TEXT,
        hasInfant INTEGER
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
        assessmentType TEXT NOT NULL,
        referenceModuleId TEXT,
        order_index INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE assessment_results (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        type TEXT NOT NULL,
        domainScoresJson TEXT NOT NULL,
        domainTotalsJson TEXT NOT NULL,
        totalCorrect INTEGER NOT NULL,
        totalQuestions INTEGER NOT NULL,
        completedAt TEXT NOT NULL,
        responsesJson TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE module_progress (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        moduleId TEXT NOT NULL,
        completed INTEGER DEFAULT 0,
        timeSpentSeconds INTEGER DEFAULT 0,
        completedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (moduleId) REFERENCES modules(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE assigned_modules (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        moduleId TEXT NOT NULL,
        assignedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id),
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
