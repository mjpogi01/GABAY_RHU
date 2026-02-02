import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/module_model.dart';
import '../services/database_service.dart';

class ModuleRepository {
  static Future<List<ModuleModel>> getAllModules() async {
    final db = await DatabaseService.database;
    final rows = await db.query('modules', orderBy: 'ord ASC');
    return rows.map((r) {
      final cards = jsonDecode(r['cardsJson'] as String) as List<dynamic>;
      return ModuleModel(
        id: r['id'] as String,
        title: r['title'] as String,
        domain: r['domain'] as String,
        order: r['ord'] as int,
        cards: cards
            .map((c) => ModuleCard.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
    }).toList();
  }

  static Future<ModuleModel?> getModuleById(String id) async {
    final all = await getAllModules();
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> seedModules(List<ModuleModel> modules) async {
    final db = await DatabaseService.database;
    for (final m in modules) {
      await db.insert(
        'modules',
        {
          'id': m.id,
          'title': m.title,
          'domain': m.domain,
          'ord': m.order,
          'cardsJson': jsonEncode(m.cards.map((c) => c.toJson()).toList()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
