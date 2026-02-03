import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/module_model.dart';
import '../models/question_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';
import '../core/app_data_source.dart';

/// Supabase-backed data source (users table only; no children or user_preferences).
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
    final userModel = _userFromSupabase(response);
    return userModel.id.isEmpty ? null : userModel;
  }

  @override
  Future<void> setCurrentUser(String userId) async {}

  @override
  Future<void> saveUser(UserModel user) async {
    await _supabase.from('users').upsert(_userToSupabase(user));
  }

  static Map<String, dynamic> _userToSupabase(UserModel user) => {
    'id': user.id,
    'anonymized_id': user.anonymizedId,
    'role': user.role,
    'created_at': user.createdAt.toIso8601String(),
    'consent_given': user.consentGiven ? 1 : 0,
    'first_name': user.firstName,
    'last_name': user.lastName,
    'phone_number': user.phoneNumber,
    'address': user.address,
    'status': user.status,
    'number_of_children': user.numberOfChildren,
    'id_number': user.idNumber,
    'has_infant': user.hasInfant,
  };

  static UserModel _userFromSupabase(Map<String, dynamic> r) {
    final rawId = r['id']?.toString();
    if (rawId == null || rawId.isEmpty) {
      return UserModel(
        id: '',
        anonymizedId: '',
        role: 'parent',
        createdAt: DateTime.now(),
      );
    }
    return UserModel(
      id: rawId,
      anonymizedId: r['anonymized_id']?.toString() ?? 'anon_${DateTime.now().millisecondsSinceEpoch}',
      role: r['role']?.toString() ?? 'parent',
      createdAt: r['created_at'] != null
          ? DateTime.tryParse(r['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      consentGiven: (r['consent_given'] == null || r['consent_given'] == 1),
      firstName: _emptyToNull(r['first_name']?.toString()),
      lastName: _emptyToNull(r['last_name']?.toString()),
      phoneNumber: _emptyToNull(r['phone_number']?.toString()),
      address: _emptyToNull(r['address']?.toString()),
      status: _emptyToNull(r['status']?.toString()),
      numberOfChildren: r['number_of_children'] != null
          ? (r['number_of_children'] is int
              ? r['number_of_children'] as int
              : int.tryParse(r['number_of_children'].toString()))
          : null,
      idNumber: _emptyToNull(r['id_number']?.toString()),
      hasInfant: r['has_infant'] == null ? null : (r['has_infant'] == true),
    );
  }

  static String? _emptyToNull(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s;

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
        .order('created_at', ascending: false)
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
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return _assessmentResultFromSupabase(response);
  }

  static AssessmentResultModel? _assessmentResultFromSupabase(Map<String, dynamic> r) {
    final id = r['id']?.toString();
    final userId = r['userId']?.toString() ?? r['user_id']?.toString();
    final type = r['type']?.toString();
    if (id == null || id.isEmpty || userId == null || userId.isEmpty || type == null) {
      return null;
    }
    final answers = r['answers'];
    final answersMap = answers is Map ? answers as Map<String, dynamic> : <String, dynamic>{};
    final domainScores = r['domainScores'] ?? answersMap['domainScores'];
    final domainTotals = r['domainTotals'] ?? answersMap['domainTotals'];
    final totalCorrect = r['totalCorrect'] ?? r['score'];
    final totalQuestions = r['totalQuestions'] ?? r['total_questions'];
    final completedAt = r['completedAt']?.toString() ?? r['created_at']?.toString();
    final responses = r['responses'] ?? answersMap['responses'] ?? r['answers'];
    return AssessmentResultModel(
      id: id,
      userId: userId,
      type: type,
      domainScores: domainScores is Map ? Map<String, int>.from(domainScores) : <String, int>{},
      domainTotals: domainTotals is Map ? Map<String, int>.from(domainTotals) : <String, int>{},
      totalCorrect: totalCorrect is int ? totalCorrect : (int.tryParse(totalCorrect?.toString() ?? '') ?? 0),
      totalQuestions: totalQuestions is int ? totalQuestions : (int.tryParse(totalQuestions?.toString() ?? '') ?? 0),
      completedAt: completedAt != null ? (DateTime.tryParse(completedAt) ?? DateTime.now()) : DateTime.now(),
      responses: responses is List
          ? (responses as Iterable).map((e) => QuestionResponse.fromJson(Map<String, dynamic>.from(e is Map ? e : <String, dynamic>{}))).toList()
          : <QuestionResponse>[],
    );
  }

  @override
  Future<void> saveAssessmentResult(AssessmentResultModel result) async {
    await _supabase.from('assessment_results').upsert(_assessmentResultToSupabase(result));
  }

  static Map<String, dynamic> _assessmentResultToSupabase(AssessmentResultModel r) {
    return {
      'id': r.id,
      'user_id': r.userId,
      'type': r.type,
      'score': r.totalCorrect,
      'total_questions': r.totalQuestions,
      'answers': {
        'domainScores': r.domainScores,
        'domainTotals': r.domainTotals,
        'responses': r.responses.map((x) => x.toJson()).toList(),
      },
      'created_at': r.completedAt.toIso8601String(),
    };
  }

  @override
  Future<List<ModuleModel>> getAllModules() async {
    final response = await _supabase.from('modules').select();
    return response.map((row) => _moduleFromSupabase(row)).toList();
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

  /// Map Supabase modules row (may have order_index, description, content) to ModuleModel.
  static ModuleModel _moduleFromSupabase(Map<String, dynamic> r) {
    final id = r['id']?.toString() ?? '';
    final title = r['title']?.toString() ?? '';
    final domain = r['domain']?.toString() ?? r['description']?.toString() ?? '';
    final order = r['order'] is int ? r['order'] as int : (int.tryParse(r['order_index']?.toString() ?? '') ?? 0);
    List<dynamic> cardsRaw = const [];
    if (r['cards'] is List) {
      cardsRaw = r['cards'] as List<dynamic>;
    } else if (r['content'] != null && r['content'].toString().trim().isNotEmpty) {
      cardsRaw = [{'id': id, 'content': r['content'], 'order': 0}];
    }
    final cards = cardsRaw
        .map((c) => ModuleCard.fromJson(Map<String, dynamic>.from(c is Map ? c : <String, dynamic>{})))
        .toList();
    return ModuleModel(id: id, title: title, domain: domain, order: order, cards: cards);
  }

  @override
  Future<List<String>> getAssignedModuleIds(String userId) async {
    final response = await _supabase
        .from('module_assignments')
        .select('module_id')
        .eq('user_id', userId);

    return response
        .map<String>((row) => (row['module_id'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  @override
  Future<void> assignModules(String userId, List<String> moduleIds) async {
    await _supabase
        .from('module_assignments')
        .delete()
        .eq('user_id', userId);

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
    return response.map((row) {
      final j = Map<String, dynamic>.from(row);
      j['userId'] = j['user_id'] ?? j['userId'];
      j['moduleId'] = j['module_id'] ?? j['moduleId'];
      j['completed'] = (j['completed'] == true || j['completed'] == 1) ? 1 : 0;
      j['timeSpentSeconds'] = j['timeSpentSeconds'] ?? 0;
      j['completedAt'] = j['last_accessed'] ?? j['completedAt'];
      return ModuleProgressModel.fromJson(j);
    }).toList();
  }

  @override
  Future<void> saveModuleProgress(ModuleProgressModel progress) async {
    await _supabase.from('module_progress').upsert({
      'id': progress.id,
      'user_id': progress.userId,
      'module_id': progress.moduleId,
      'progress_percentage': progress.completed ? 100 : 0,
      'completed': progress.completed,
      'last_accessed': progress.completedAt?.toIso8601String(),
    });
  }

  @override
  Future<List<QuestionModel>> getPreTestQuestions() async {
    final response = await _supabase
        .from('questions')
        .select()
        .eq('type', 'pre_test');
    return response.map((row) => _questionFromSupabase(row)).toList();
  }

  @override
  Future<List<QuestionModel>> getPostTestQuestions() async {
    final response = await _supabase
        .from('questions')
        .select()
        .eq('type', 'post_test');
    return response.map((row) => _questionFromSupabase(row)).toList();
  }

  /// Map Supabase questions row (question, correct_answer, options) to QuestionModel.
  static QuestionModel _questionFromSupabase(Map<String, dynamic> r) {
    final id = r['id']?.toString() ?? '';
    final text = r['text']?.toString() ?? r['question']?.toString() ?? '';
    final optionsList = r['options'];
    final options = optionsList is List
        ? optionsList.map((e) => e?.toString() ?? '').toList()
        : <String>[];
    final correctAnswer = r['correctIndex'] != null
        ? (r['correctIndex'] as int)
        : _indexOfCorrect(r['correct_answer'], options);
    return QuestionModel(
      id: id,
      pairedId: r['pairedId']?.toString() ?? id,
      domain: r['domain']?.toString() ?? '',
      text: text,
      options: options,
      correctIndex: correctAnswer >= 0 && correctAnswer < options.length ? correctAnswer : 0,
      explanation: r['explanation']?.toString(),
    );
  }

  static int _indexOfCorrect(dynamic correctAnswer, List<String> options) {
    if (correctAnswer == null || options.isEmpty) return 0;
    final s = correctAnswer.toString();
    final i = options.indexWhere((o) => o == s);
    return i >= 0 ? i : 0;
  }

  @override
  Future<void> ensureSeeded() async {}
}
