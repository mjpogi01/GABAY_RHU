import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import 'database_service.dart';

/// Secure storage for user (no children or preferences).
class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _keyUserId = 'current_user_id';

  static Future<UserModel?> getCurrentUser() async {
    final userId = await _storage.read(key: _keyUserId);
    if (userId == null) return null;

    final db = await DatabaseService.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;

    return UserModel.fromJson(Map<String, dynamic>.from(rows.first));
  }

  static Future<void> setCurrentUser(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  static Future<void> logout() async {
    await _storage.delete(key: _keyUserId);
  }

  static Future<void> saveUser(UserModel user) async {
    final db = await DatabaseService.database;
    await db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
