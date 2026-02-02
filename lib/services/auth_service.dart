import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/child_model.dart';
import 'database_service.dart';

/// Secure registration and login
/// User identity verified against RHU/BHW master lists (to be implemented)
class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _keyUserId = 'current_user_id';
  static const _keyChildId = 'current_child_id';

  static Future<UserModel?> getCurrentUser() async {
    final userId = await _storage.read(key: _keyUserId);
    if (userId == null) return null;

    final db = await DatabaseService.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;

    return UserModel.fromJson(Map<String, dynamic>.from(rows.first));
  }

  static Future<ChildModel?> getCurrentChild() async {
    final childId = await _storage.read(key: _keyChildId);
    if (childId == null) return null;

    final db = await DatabaseService.database;
    final rows =
        await db.query('children', where: 'id = ?', whereArgs: [childId]);
    if (rows.isEmpty) return null;

    return ChildModel.fromJson(Map<String, dynamic>.from(rows.first));
  }

  static Future<void> setCurrentUser(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  static Future<void> setCurrentChild(String childId) async {
    await _storage.write(key: _keyChildId, value: childId);
  }

  static Future<void> logout() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyChildId);
  }

  static Future<void> saveUser(UserModel user) async {
    final db = await DatabaseService.database;
    await db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> saveChild(ChildModel child) async {
    final db = await DatabaseService.database;
    await db.insert(
      'children',
      child.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
