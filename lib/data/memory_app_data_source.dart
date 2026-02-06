import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/module_model.dart';
import '../models/question_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';
import '../core/app_data_source.dart';
import 'seed_data.dart';

/// In-memory data source (users only; no children or preferences).
class MemoryAppDataSource implements AppDataSource {
  final List<ModuleModel> _modules = [];
  final List<QuestionModel> _preQuestions = [];
  final List<QuestionModel> _postQuestions = [];
  final Map<String, UserModel> _users = {};
  final List<AssessmentResultModel> _assessmentResults = [];
  final List<ModuleProgressModel> _progress = [];
  final Map<String, List<String>> _assignedModules = {};

  static const _keyUserId = 'gabay_web_user_id';
  static const _keyModuleProgress = 'gabay_module_progress';
  static const _keyAssessmentResults = 'gabay_assessment_results';

  SharedPreferences? _prefs;
  bool _progressLoaded = false;
  bool _assessmentResultsLoaded = false;

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
  Future<void> setCurrentUser(String userId) async {
    await (await _preferences).setString(_keyUserId, userId);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> logout() async {
    final prefs = await _preferences;
    await prefs.remove(_keyUserId);
  }

  Future<void> _loadAssessmentResultsFromPrefs() async {
    if (_assessmentResultsLoaded) return;
    _assessmentResultsLoaded = true;
    try {
      final prefs = await _preferences;
      final json = prefs.getString(_keyAssessmentResults);
      if (json == null || json.isEmpty) return;
      final list = (jsonDecode(json) as List<dynamic>?)
          ?.map((e) => AssessmentResultModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (list != null) {
        _assessmentResults.clear();
        _assessmentResults.addAll(list);
      }
    } catch (_) {}
  }

  Future<void> _saveAssessmentResultsToPrefs() async {
    try {
      final prefs = await _preferences;
      final json = jsonEncode(_assessmentResults.map((r) => r.toJson()).toList());
      await prefs.setString(_keyAssessmentResults, json);
    } catch (_) {}
  }

  @override
  Future<AssessmentResultModel?> getPreTestResult(String userId) async {
    await _loadAssessmentResultsFromPrefs();
    try {
      return _assessmentResults.lastWhere((r) =>
          r.userId == userId && r.type == 'pre_test');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AssessmentResultModel?> getPostTestResult(String userId) async {
    await _loadAssessmentResultsFromPrefs();
    try {
      return _assessmentResults.lastWhere((r) =>
          r.userId == userId && r.type == 'post_test');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveAssessmentResult(AssessmentResultModel result) async {
    await _loadAssessmentResultsFromPrefs();
    _assessmentResults.removeWhere((r) =>
        r.userId == result.userId && r.type == result.type);
    _assessmentResults.add(result);
    await _saveAssessmentResultsToPrefs();
  }

  @override
  Future<List<ModuleModel>> getAllModules() async {
    final list = List<ModuleModel>.from(_modules);
    ModuleModel.sortByOrderAndNumber(list);
    return list;
  }

  @override
  Future<ModuleModel?> getModuleById(String id) async {
    try {
      return _modules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveModule(ModuleModel module, {String? localCoverImagePath, List<int>? coverImageBytes, String? coverImageExtension, bool clearCover = false}) async {
    _modules.removeWhere((m) => m.id == module.id);
    _modules.add(module);
  }

  @override
  Future<void> deleteModule(String id) async {
    _modules.removeWhere((m) => m.id == id);
  }

  @override
  Future<List<String>> getAssignedModuleIds(String userId) async {
    return _assignedModules[userId] ?? [];
  }

  @override
  Future<void> assignModules(String userId, List<String> moduleIds) async {
    _assignedModules[userId] = moduleIds;
  }

  Future<void> _loadProgressFromPrefs() async {
    if (_progressLoaded) return;
    _progressLoaded = true;
    try {
      final prefs = await _preferences;
      final json = prefs.getString(_keyModuleProgress);
      if (json == null || json.isEmpty) return;
      final list = (jsonDecode(json) as List<dynamic>?)
          ?.map((e) => ModuleProgressModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (list != null) {
        _progress.clear();
        _progress.addAll(list);
      }
    } catch (_) {}
  }

  Future<void> _saveProgressToPrefs() async {
    try {
      final prefs = await _preferences;
      final json = jsonEncode(_progress.map((p) => p.toJson()).toList());
      await prefs.setString(_keyModuleProgress, json);
    } catch (_) {}
  }

  @override
  Future<List<ModuleProgressModel>> getModuleProgress(String userId) async {
    await _loadProgressFromPrefs();
    return _progress.where((p) => p.userId == userId).toList();
  }

  @override
  Future<void> saveModuleProgress(ModuleProgressModel progress) async {
    await _loadProgressFromPrefs();
    _progress.removeWhere((p) => p.id == progress.id || (p.userId == progress.userId && p.moduleId == progress.moduleId));
    _progress.add(progress);
    await _saveProgressToPrefs();
  }

  @override
  Future<List<QuestionModel>> getPreTestQuestions() async {
    final list = List<QuestionModel>.from(_preQuestions);
    list.sort((a, b) {
      final o = a.orderIndex.compareTo(b.orderIndex);
      return o != 0 ? o : a.id.compareTo(b.id);
    });
    return list;
  }

  @override
  Future<List<QuestionModel>> getPostTestQuestions() async {
    final list = List<QuestionModel>.from(_postQuestions);
    list.sort((a, b) {
      final o = a.orderIndex.compareTo(b.orderIndex);
      return o != 0 ? o : a.id.compareTo(b.id);
    });
    return list;
  }

  @override
  Future<void> savePreTestQuestion(QuestionModel question) async {
    _preQuestions.removeWhere((q) => q.id == question.id);
    _preQuestions.add(question);
  }
}
