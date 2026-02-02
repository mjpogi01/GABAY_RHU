import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/assessment_result_model.dart';
import '../models/question_model.dart';
import '../services/database_service.dart';

class AssessmentRepository {
  static Future<void> saveAssessmentResult(AssessmentResultModel result) async {
    final db = await DatabaseService.database;
    await db.insert(
      'assessment_results',
      {
        'id': result.id,
        'userId': result.userId,
        'childId': result.childId,
        'type': result.type,
        'domainScoresJson': jsonEncode(result.domainScores),
        'domainTotalsJson': jsonEncode(result.domainTotals),
        'totalCorrect': result.totalCorrect,
        'totalQuestions': result.totalQuestions,
        'completedAt': result.completedAt.toIso8601String(),
        'responsesJson': jsonEncode(
            result.responses.map((r) => r.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<AssessmentResultModel?> getPreTestResult(
    String userId,
    String childId,
  ) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'assessment_results',
      where: 'userId = ? AND childId = ? AND type = ?',
      whereArgs: [userId, childId, 'pre'],
    );
    if (rows.isEmpty) return null;
    return _rowToResult(rows.first);
  }

  static Future<AssessmentResultModel?> getPostTestResult(
    String userId,
    String childId,
  ) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'assessment_results',
      where: 'userId = ? AND childId = ? AND type = ?',
      whereArgs: [userId, childId, 'post'],
    );
    if (rows.isEmpty) return null;
    return _rowToResult(rows.first);
  }

  static AssessmentResultModel _rowToResult(Map<String, dynamic> r) {
    return AssessmentResultModel(
      id: r['id'] as String,
      userId: r['userId'] as String,
      childId: r['childId'] as String,
      type: r['type'] as String,
      domainScores: Map<String, int>.from(
        jsonDecode(r['domainScoresJson'] as String) as Map,
      ),
      domainTotals: Map<String, int>.from(
        jsonDecode(r['domainTotalsJson'] as String) as Map,
      ),
      totalCorrect: r['totalCorrect'] as int,
      totalQuestions: r['totalQuestions'] as int,
      completedAt: DateTime.parse(r['completedAt'] as String),
      responses: (jsonDecode(r['responsesJson'] as String) as List<dynamic>)
          .map((x) => QuestionResponse.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<List<QuestionModel>> getPreTestQuestions() async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'questions',
      where: 'assessmentType = ?',
      whereArgs: ['pre'],
    );
    return rows.map((r) => _rowToQuestion(r)).toList();
  }

  static Future<List<QuestionModel>> getPostTestQuestions() async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'questions',
      where: 'assessmentType = ?',
      whereArgs: ['post'],
    );
    return rows.map((r) => _rowToQuestion(r)).toList();
  }

  static QuestionModel _rowToQuestion(Map<String, dynamic> r) {
    return QuestionModel(
      id: r['id'] as String,
      pairedId: r['pairedId'] as String,
      domain: r['domain'] as String,
      text: r['text'] as String,
      options: List<String>.from(jsonDecode(r['optionsJson'] as String)),
      correctIndex: r['correctIndex'] as int,
      explanation: r['explanation'] as String?,
    );
  }

  static Future<void> seedQuestions(List<QuestionModel> questions) async {
    final db = await DatabaseService.database;
    for (final q in questions) {
      await db.insert(
        'questions',
        {
          'id': q.id,
          'pairedId': q.pairedId,
          'domain': q.domain,
          'text': q.text,
          'optionsJson': jsonEncode(q.options),
          'correctIndex': q.correctIndex,
          'explanation': q.explanation,
          'assessmentType': q.id.startsWith('pre_') ? 'pre' : 'post',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
