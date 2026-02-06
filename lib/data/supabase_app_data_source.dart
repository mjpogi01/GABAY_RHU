import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/module_model.dart';
import '../models/question_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';
import '../core/app_data_source.dart';
import '../services/cloudinary_upload_service.dart';

/// Supabase-backed data source for auth and database
class SupabaseAppDataSource implements AppDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return _userFromSupabase(response);
  }

  @override
  Future<void> setCurrentUser(String userId) async {
    // User is managed by Supabase auth, no need to set manually
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await _supabase.from('users').upsert(_userToSupabase(user));
  }

  static Map<String, dynamic> _userToSupabase(UserModel user) => {
    'id': user.id,
    'anonymized_id': user.anonymizedId,
    'role': user.role,
    'created_at': user.createdAt.toIso8601String(),
    'first_name': user.firstName,
    'last_name': user.lastName,
    'phone_number': user.phoneNumber,
    'address': user.address,
    'status': user.status,
    'number_of_children': user.numberOfChildren,
    'has_infant': user.hasInfant,
  };

  static UserModel _userFromSupabase(Map<String, dynamic> r) => UserModel(
    id: r['id'] as String,
    anonymizedId: r['anonymized_id'] as String,
    role: r['role'] as String,
    createdAt: DateTime.parse(r['created_at'] as String),
    firstName: r['first_name'] as String?,
    lastName: r['last_name'] as String?,
    phoneNumber: r['phone_number'] as String?,
    address: r['address'] as String?,
    status: r['status'] as String?,
    numberOfChildren: r['number_of_children'] as int?,
    hasInfant: r['has_infant'] as bool?,
  );

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<AssessmentResultModel?> getPreTestResult(String userId) async {
    final response = await _supabase
        .from('assessment_results')
        .select()
        .eq('user_id', userId)
        .eq('type', 'pre_test')
        .order('completed_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return _assessmentResultFromSupabase(response);
  }

  @override
  Future<AssessmentResultModel?> getPostTestResult(String userId) async {
    final response = await _supabase
        .from('assessment_results')
        .select()
        .eq('user_id', userId)
        .eq('type', 'post_test')
        .order('completed_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return _assessmentResultFromSupabase(response);
  }

  @override
  Future<void> saveAssessmentResult(AssessmentResultModel result) async {
    await _supabase.from('assessment_results').upsert(_assessmentResultToSupabase(result));
  }

  /// Map app model to Supabase row (snake_case columns).
  static Map<String, dynamic> _assessmentResultToSupabase(AssessmentResultModel result) {
    return {
      'id': result.id,
      'user_id': result.userId,
      'type': result.type,
      'score': result.totalCorrect,
      'total_questions': result.totalQuestions,
      'answers': result.responses.map((r) => r.toJson()).toList(),
      'created_at': result.completedAt.toIso8601String(),
      'domain_scores': result.domainScores,
      'domain_totals': result.domainTotals,
      'total_correct': result.totalCorrect,
      'completed_at': result.completedAt.toIso8601String(),
      'responses': result.responses.map((r) => r.toJson()).toList(),
    };
  }

  /// Map Supabase row (snake_case) to app model (fromJson expects camelCase).
  static AssessmentResultModel _assessmentResultFromSupabase(Map<String, dynamic> r) {
    final id = r['id']?.toString() ?? '';
    final userId = r['user_id']?.toString() ?? '';
    final type = r['type']?.toString() ?? '';
    final totalCorrect = r['total_correct'] is int
        ? r['total_correct'] as int
        : int.tryParse(r['score']?.toString() ?? '') ?? 0;
    final totalQuestions = r['total_questions'] is int
        ? r['total_questions'] as int
        : int.tryParse(r['total_questions']?.toString() ?? '') ?? 0;
    final completedAtStr = r['completed_at']?.toString() ?? r['created_at']?.toString();
    final completedAt = completedAtStr != null && completedAtStr.isNotEmpty
        ? DateTime.tryParse(completedAtStr) ?? DateTime.now()
        : DateTime.now();
    final domainScoresRaw = r['domain_scores'];
    final domainScores = domainScoresRaw is Map
        ? Map<String, int>.from(domainScoresRaw.map((k, v) => MapEntry(k.toString(), v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0)))
        : <String, int>{};
    final domainTotalsRaw = r['domain_totals'];
    final domainTotals = domainTotalsRaw is Map
        ? Map<String, int>.from(domainTotalsRaw.map((k, v) => MapEntry(k.toString(), v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0)))
        : <String, int>{};
    final responsesRaw = r['responses'] ?? r['answers'];
    final responses = responsesRaw is List
        ? (responsesRaw)
            .map<QuestionResponse>((e) => QuestionResponse.fromJson(Map<String, dynamic>.from(e is Map ? e : <String, dynamic>{})))
            .toList()
        : <QuestionResponse>[];
    return AssessmentResultModel(
      id: id,
      userId: userId,
      type: type,
      domainScores: domainScores,
      domainTotals: domainTotals,
      totalCorrect: totalCorrect,
      totalQuestions: totalQuestions,
      completedAt: completedAt,
      responses: responses,
    );
  }

  /// Maps Supabase row (id, title, domain, order_index, cards_json, cover_image_url, content) to ModuleModel
  static ModuleModel _moduleFromSupabase(Map<String, dynamic> r) {
    final id = r['id'] as String;
    final title = r['title'] as String;
    final domain = r['domain'] as String? ?? 'general';
    final order = (r['order_index'] as num?)?.toInt() ?? 0;
    final coverUrl = r['cover_image_url'] as String?;
    List<ModuleCard> cards;
    final cardsJson = r['cards_json'] as String?;
    if (cardsJson != null && cardsJson.isNotEmpty) {
      try {
        final list = jsonDecode(cardsJson) as List<dynamic>;
        cards = list
            .map((c) => ModuleCard.fromJson(c as Map<String, dynamic>))
            .toList();
        if (coverUrl != null && cards.isNotEmpty) {
          cards = [
            ModuleCard(
              id: cards[0].id,
              content: cards[0].content,
              imagePath: coverUrl,
              order: cards[0].order,
            ),
            ...cards.skip(1),
          ];
        }
      } catch (_) {
        cards = [
          ModuleCard(
            id: 'card_1',
            content: r['content']?.toString() ?? '',
            imagePath: coverUrl,
            order: 0,
          ),
        ];
      }
    } else {
      cards = [
        ModuleCard(
          id: 'card_1',
          content: r['content']?.toString() ?? '',
          imagePath: coverUrl,
          order: 0,
        ),
      ];
    }
    final moduleNumber = r['module_number'] as String?;
    return ModuleModel(id: id, title: title, domain: domain, order: order, cards: cards, moduleNumber: moduleNumber);
  }

  static Map<String, dynamic> _moduleToSupabase(ModuleModel m, {String? coverImageUrl}) {
    final cardsJson = jsonEncode(m.cards.map((c) => c.toJson()).toList());
    return {
      'id': m.id,
      'title': m.title,
      'domain': m.domain,
      'order_index': m.order,
      'cards_json': cardsJson,
      'cover_image_url': coverImageUrl,
      'module_number': m.moduleNumber,
    };
  }

  @override
  Future<List<ModuleModel>> getAllModules() async {
    final response = await _supabase.from('modules').select().order('order_index');
    final list = (response as List<dynamic>).map((r) => _moduleFromSupabase(r as Map<String, dynamic>)).toList();
    ModuleModel.sortByOrderAndNumber(list);
    return list;
  }

  @override
  Future<ModuleModel?> getModuleById(String id) async {
    final response = await _supabase
        .from('modules')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return _moduleFromSupabase(response);
  }

  @override
  Future<void> saveModule(ModuleModel module, {String? localCoverImagePath, List<int>? coverImageBytes, String? coverImageExtension, bool clearCover = false}) async {
    String? coverImageUrl;

    if (coverImageBytes != null && coverImageBytes.isNotEmpty) {
      // Unique public_id per upload so each module gets its own image (no cache/cross-module mix-up)
      final uniquePublicId = '${module.id}/cover_${DateTime.now().millisecondsSinceEpoch}';
      coverImageUrl = await CloudinaryUploadService.uploadImage(
        bytes: coverImageBytes,
        publicId: uniquePublicId,
        folder: 'gabay/modules',
      );
      if (coverImageUrl == null) {
        final existingCover = module.cards.isNotEmpty && module.cards.first.imagePath != null && module.cards.first.imagePath!.startsWith('http')
            ? module.cards.first.imagePath
            : null;
        if (!clearCover && existingCover != null) coverImageUrl = existingCover;
      }
    } else if (clearCover) {
      // User clicked X: explicitly clear cover in DB
      coverImageUrl = null;
    } else {
      final existingCover = module.cards.isNotEmpty && module.cards.first.imagePath != null && module.cards.first.imagePath!.startsWith('http')
          ? module.cards.first.imagePath
          : null;
      coverImageUrl = existingCover;
    }

    final row = _moduleToSupabase(module, coverImageUrl: coverImageUrl);
    await _supabase.from('modules').upsert(row, onConflict: 'id');
  }

  @override
  Future<void> deleteModule(String id) async {
    await _supabase.from('modules').delete().eq('id', id);
  }

  @override
  Future<List<String>> getAssignedModuleIds(String userId) async {
    final response = await _supabase
        .from('module_assignments')
        .select('module_id')
        .eq('user_id', userId);

    return response.map((row) => row['module_id'] as String).toList();
  }

  @override
  Future<void> assignModules(String userId, List<String> moduleIds) async {
    // First, remove existing assignments
    await _supabase
        .from('module_assignments')
        .delete()
        .eq('user_id', userId);

    // Then, insert new assignments
    final assignments = moduleIds.map((moduleId) => {
      'user_id': userId,
      'module_id': moduleId,
    }).toList();

    await _supabase.from('module_assignments').insert(assignments);
  }

  @override
  Future<List<ModuleProgressModel>> getModuleProgress(String userId) async {
    final response = await _supabase
        .from('module_progress')
        .select()
        .eq('user_id', userId);

    return response.map((json) => ModuleProgressModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  @override
  Future<void> saveModuleProgress(ModuleProgressModel progress) async {
    // Postgres uses snake_case; upsert on (user_id, module_id) so completed state persists across restarts
    final row = <String, dynamic>{
      'user_id': progress.userId,
      'module_id': progress.moduleId,
      'completed': progress.completed,
    };
    await _supabase.from('module_progress').upsert(
          row,
          onConflict: 'user_id,module_id',
        );
  }

  @override
  Future<List<QuestionModel>> getPreTestQuestions() async {
    final response = await _supabase
        .from('questions')
        .select()
        .eq('type', 'pre_test')
        .order('order_index')
        .order('id');

    return response.map((json) => QuestionModel.fromJson(json)).toList();
  }

  @override
  Future<List<QuestionModel>> getPostTestQuestions() async {
    final response = await _supabase
        .from('questions')
        .select()
        .eq('type', 'post_test')
        .order('order_index')
        .order('id');

    return response.map((json) => QuestionModel.fromJson(json)).toList();
  }

  @override
  Future<void> savePreTestQuestion(QuestionModel question) async {
    final correctAnswer = question.options.isNotEmpty && question.correctIndex < question.options.length
        ? question.options[question.correctIndex]
        : '';
    await _supabase.from('questions').upsert({
      'id': question.id,
      'type': 'pre_test',
      'question': question.text,
      'options': question.options,
      'correct_answer': correctAnswer,
      'domain': question.domain,
      'pairedId': question.pairedId,
      'explanation': question.explanation,
      'referenceModuleId': question.referenceModuleId,
      'order_index': question.orderIndex,
    });
  }

  @override
  Future<void> ensureSeeded() async {
    // For Supabase, seeding is done via SQL scripts or migrations
    // Data is pre-seeded in the Supabase database
  }
}
