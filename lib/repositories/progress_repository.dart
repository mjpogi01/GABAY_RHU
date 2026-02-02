import 'package:sqflite/sqflite.dart';
import '../models/progress_model.dart';
import '../services/database_service.dart';

class ProgressRepository {
  static Future<List<ModuleProgressModel>> getModuleProgress(
    String userId,
    String childId,
  ) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'module_progress',
      where: 'userId = ? AND childId = ?',
      whereArgs: [userId, childId],
    );
    return rows.map((r) => ModuleProgressModel.fromJson(Map.from(r))).toList();
  }

  static Future<void> saveModuleProgress(ModuleProgressModel progress) async {
    final db = await DatabaseService.database;
    await db.insert(
      'module_progress',
      progress.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<String>> getAssignedModuleIds(
    String userId,
    String childId,
  ) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'assigned_modules',
      where: 'userId = ? AND childId = ?',
      whereArgs: [userId, childId],
      columns: ['moduleId'],
    );
    return rows.map((r) => r['moduleId'] as String).toList();
  }

  static Future<void> assignModules(
    String userId,
    String childId,
    List<String> moduleIds,
  ) async {
    final db = await DatabaseService.database;
    final now = DateTime.now().toIso8601String();
    for (var i = 0; i < moduleIds.length; i++) {
      await db.insert(
        'assigned_modules',
        {
          'id': '${userId}_${childId}_${moduleIds[i]}',
          'userId': userId,
          'childId': childId,
          'moduleId': moduleIds[i],
          'assignedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
