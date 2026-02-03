import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/child_model.dart';
import '../models/module_model.dart';
import '../models/question_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';
import '../core/app_data_source.dart';
import '../data/seed_data.dart';

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
  Future<ChildModel?> getCurrentChild() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final prefs = await _supabase
        .from('user_preferences')
        .select('current_child_id')
        .eq('user_id', user.id)
        .maybeSingle();

    final childId = prefs?['current_child_id'];
    if (childId == null) return null;

    final childResponse = await _supabase
        .from('children')
        .select()
        .eq('id', childId)
        .maybeSingle();

    if (childResponse == null) return null;
    return _childFromSupabase(childResponse);
  }

  @override
  Future<void> setCurrentUser(String userId) async {
    // User is managed by Supabase auth, no need to set manually
  }

  @override
  Future<void> setCurrentChild(String childId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('user_preferences').upsert({
      'user_id': user.id,
      'current_child_id': childId,
    });
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
  Future<void> saveChild(ChildModel child) async {
    await _supabase.from('children').upsert(_childToSupabase(child));
  }

  static Map<String, dynamic> _childToSupabase(ChildModel c) => {
    'id': c.id,
    'caregiver_id': c.caregiverId,
    'date_of_birth': c.dateOfBirth.toIso8601String().substring(0, 10),
    'anonymized_child_id': c.anonymizedChildId,
  };

  static ChildModel _childFromSupabase(Map<String, dynamic> r) => ChildModel(
    id: r['id'] as String,
    caregiverId: r['caregiver_id'] as String,
    dateOfBirth: DateTime.parse(r['date_of_birth'] as String),
    anonymizedChildId: r['anonymized_child_id'] as String?,
  );

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<AssessmentResultModel?> getPreTestResult(String userId, String childId) async {
    final response = await _supabase
        .from('assessment_results')
        .select()
        .eq('user_id', userId)
        .eq('child_id', childId)
        .eq('type', 'pre_test')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return AssessmentResultModel.fromJson(response);
  }

  @override
  Future<AssessmentResultModel?> getPostTestResult(String userId, String childId) async {
    final response = await _supabase
        .from('assessment_results')
        .select()
        .eq('user_id', userId)
        .eq('child_id', childId)
        .eq('type', 'post_test')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return AssessmentResultModel.fromJson(response);
  }

  @override
  Future<void> saveAssessmentResult(AssessmentResultModel result) async {
    await _supabase.from('assessment_results').upsert(result.toJson());
  }

  @override
  Future<List<ModuleModel>> getAllModules() async {
    final response = await _supabase.from('modules').select();
    return response.map((json) => ModuleModel.fromJson(json)).toList();
  }

  @override
  Future<ModuleModel?> getModuleById(String id) async {
    final response = await _supabase
        .from('modules')
        .select()
        .eq('id', id)
        .single();

    return ModuleModel.fromJson(response);
  }

  @override
  Future<List<String>> getAssignedModuleIds(String userId, String childId) async {
    final response = await _supabase
        .from('module_assignments')
        .select('module_id')
        .eq('user_id', userId)
        .eq('child_id', childId);

    return response.map((row) => row['module_id'] as String).toList();
  }

  @override
  Future<void> assignModules(String userId, String childId, List<String> moduleIds) async {
    // First, remove existing assignments
    await _supabase
        .from('module_assignments')
        .delete()
        .eq('user_id', userId)
        .eq('child_id', childId);

    // Then, insert new assignments
    final assignments = moduleIds.map((moduleId) => {
      'user_id': userId,
      'child_id': childId,
      'module_id': moduleId,
    }).toList();

    await _supabase.from('module_assignments').insert(assignments);
  }

  @override
  Future<List<ModuleProgressModel>> getModuleProgress(String userId, String childId) async {
    final response = await _supabase
        .from('module_progress')
        .select()
        .eq('user_id', userId)
        .eq('child_id', childId);

    return response.map((json) => ModuleProgressModel.fromJson(json)).toList();
  }

  @override
  Future<void> saveModuleProgress(ModuleProgressModel progress) async {
    await _supabase.from('module_progress').upsert(progress.toJson());
  }

  @override
  Future<List<QuestionModel>> getPreTestQuestions() async {
    final response = await _supabase
        .from('questions')
        .select()
        .eq('type', 'pre_test');

    return response.map((json) => QuestionModel.fromJson(json)).toList();
  }

  @override
  Future<List<QuestionModel>> getPostTestQuestions() async {
    final response = await _supabase
        .from('questions')
        .select()
        .eq('type', 'post_test');

    return response.map((json) => QuestionModel.fromJson(json)).toList();
  }

  @override
  Future<void> ensureSeeded() async {
    // For Supabase, seeding is done via SQL scripts or migrations
    // Data is pre-seeded in the Supabase database
  }
}
