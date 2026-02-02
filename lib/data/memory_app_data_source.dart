import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/child_model.dart';
import '../models/module_model.dart';
import '../models/question_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';
import '../core/app_data_source.dart';
import 'seed_data.dart';

/// In-memory data source for web demo (no SQLite)
class MemoryAppDataSource implements AppDataSource {
  final List<ModuleModel> _modules = [];
  final List<QuestionModel> _preQuestions = [];
  final List<QuestionModel> _postQuestions = [];
  final Map<String, UserModel> _users = {};
  final Map<String, ChildModel> _children = {};
  final List<AssessmentResultModel> _assessmentResults = [];
  final List<ModuleProgressModel> _progress = [];
  final Map<String, List<String>> _assignedModules = {};

  static const _keyUserId = 'gabay_web_user_id';
  static const _keyChildId = 'gabay_web_child_id';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<void> ensureSeeded() async {
    if (_modules.isNotEmpty) return;
    _modules.addAll(SeedData.getSampleModules());
    _preQuestions.addAll(SeedData.getPreTestQuestions());
    _postQuestions.addAll(SeedData.getPostTestQuestions());
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final userId = (await _preferences).getString(_keyUserId);
    return userId != null ? _users[userId] : null;
  }

  @override
  Future<ChildModel?> getCurrentChild() async {
    final childId = (await _preferences).getString(_keyChildId);
    return childId != null ? _children[childId] : null;
  }

  @override
  Future<void> setCurrentUser(String userId) async {
    await (await _preferences).setString(_keyUserId, userId);
  }

  @override
  Future<void> setCurrentChild(String childId) async {
    await (await _preferences).setString(_keyChildId, childId);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> saveChild(ChildModel child) async {
    _children[child.id] = child;
  }

  @override
  Future<void> logout() async {
    final prefs = await _preferences;
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyChildId);
  }

  @override
  Future<AssessmentResultModel?> getPreTestResult(String userId, String childId) async {
    try {
      return _assessmentResults.lastWhere((r) =>
          r.userId == userId && r.childId == childId && r.type == 'pre');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AssessmentResultModel?> getPostTestResult(String userId, String childId) async {
    try {
      return _assessmentResults.lastWhere((r) =>
          r.userId == userId && r.childId == childId && r.type == 'post');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveAssessmentResult(AssessmentResultModel result) async {
    _assessmentResults.removeWhere((r) =>
        r.userId == result.userId &&
        r.childId == result.childId &&
        r.type == result.type);
    _assessmentResults.add(result);
  }

  @override
  Future<List<ModuleModel>> getAllModules() async => _modules;

  @override
  Future<ModuleModel?> getModuleById(String id) async {
    try {
      return _modules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> getAssignedModuleIds(String userId, String childId) async {
    return _assignedModules['${userId}_$childId'] ?? [];
  }

  @override
  Future<void> assignModules(String userId, String childId, List<String> moduleIds) async {
    _assignedModules['${userId}_$childId'] = moduleIds;
  }

  @override
  Future<List<ModuleProgressModel>> getModuleProgress(String userId, String childId) async {
    return _progress
        .where((p) => p.userId == userId && p.childId == childId)
        .toList();
  }

  @override
  Future<void> saveModuleProgress(ModuleProgressModel progress) async {
    _progress.removeWhere((p) => p.id == progress.id);
    _progress.add(progress);
  }

  @override
  Future<List<QuestionModel>> getPreTestQuestions() async => _preQuestions;

  @override
  Future<List<QuestionModel>> getPostTestQuestions() async => _postQuestions;
}
