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
        .single();

    return UserModel.fromJson(response);
  }

  @override
  Future<ChildModel?> getCurrentChild() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    // Get current child from user preferences or a separate table
    final response = await _supabase
        .from('user_preferences')
        .select('current_child_id')
        .eq('user_id', user.id)
        .single();

    final childId = response['current_child_id'];
    if (childId == null) return null;

    final childResponse = await _supabase
        .from('children')
        .select()
        .eq('id', childId)
        .single();

    return ChildModel.fromJson(childResponse);
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
    await _supabase.from('users').upsert(user.toJson());
  }

  @override
  Future<void> saveChild(ChildModel child) async {
    await _supabase.from('children').upsert(child.toJson());
  }

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
    // For Supabase, seeding might be done via SQL scripts or migrations
    // For now, we'll assume the database is pre-seeded
    await SeedData.ensureSeeded();
  }
}
