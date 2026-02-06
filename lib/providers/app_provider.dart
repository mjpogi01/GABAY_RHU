import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/module_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';
import '../core/app_data_source.dart';
import '../core/greeting_type.dart';
import '../services/adaptive_learning_service.dart';

/// App-wide state (users only; no children or preferences).
class AppProvider extends ChangeNotifier {
  AppProvider(this._dataSource);

  final AppDataSource _dataSource;

  UserModel? _user;
  AssessmentResultModel? _preTestResult;
  AssessmentResultModel? _postTestResult;
  List<ModuleModel> _allModules = [];
  List<ModuleModel> _assignedModules = [];
  List<String> _completedModuleIds = [];
  bool _loading = true;
  /// In-progress timer seconds per module (persists when user goes back to dashboard and returns).
  final Map<String, int> _moduleSecondsInProgress = {};
  /// Greeting to show on dashboard (e.g. after completing a module or unlocking post-test).
  GreetingType? _pendingGreeting;

  UserModel? get user => _user;
  GreetingType? get pendingGreeting => _pendingGreeting;
  AssessmentResultModel? get preTestResult => _preTestResult;
  AssessmentResultModel? get postTestResult => _postTestResult;
  List<ModuleModel> get assignedModules => _assignedModules;
  List<ModuleModel> get allModules => _allModules;
  List<String> get completedModuleIds => _completedModuleIds;
  bool get loading => _loading;

  /// First assigned module not yet completed (for Continue Learning / next module).
  ModuleModel? get nextAssignedModule {
    for (final m in _assignedModules) {
      if (!_completedModuleIds.contains(m.id)) return m;
    }
    return null;
  }

  AppDataSource get dataSource => _dataSource;

  /// Seconds already spent in this module (for timer continuity when returning from dashboard).
  int getInProgressSeconds(String moduleId) => _moduleSecondsInProgress[moduleId] ?? 0;

  /// Save timer when leaving module without completing (so it continues on re-open).
  void setInProgressSeconds(String moduleId, int seconds) {
    _moduleSecondsInProgress[moduleId] = seconds;
  }

  void setPendingGreeting(GreetingType? type) {
    _pendingGreeting = type;
    notifyListeners();
  }

  void clearPendingGreeting() {
    if (_pendingGreeting == null) return;
    _pendingGreeting = null;
    notifyListeners();
  }

  bool get hasCompletedPreTest => _preTestResult != null;
  bool get hasCompletedPostTest => _postTestResult != null;

  bool get canAccessPostTest {
    if (_user == null || _preTestResult == null) return false;
    return AdaptiveLearningService.canAccessPostTest(
      preTestCompletedAt: _preTestResult!.completedAt,
      assignedModuleIds: _assignedModules.map((m) => m.id).toList(),
      completedModuleIds: _completedModuleIds,
    );
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    try {
      await _dataSource.ensureSeeded();
      final current = await _dataSource.getCurrentUser();
      if (current != null && current.id.isNotEmpty) {
        _user = current;
        try {
          _preTestResult = await _dataSource.getPreTestResult(_user!.id);
          _postTestResult = await _dataSource.getPostTestResult(_user!.id);
          _allModules = await _dataSource.getAllModules();
          final assignedIds = await _dataSource.getAssignedModuleIds(_user!.id);
          _assignedModules = _allModules.where((m) => assignedIds.contains(m.id)).toList();
          final progress = await _dataSource.getModuleProgress(_user!.id);
          _completedModuleIds = progress
              .where((p) => p.completed)
              .map((p) => p.moduleId)
              .toList();
        } catch (_) {
          // Keep user; leave preTest/postTest/modules as-is or empty
        }
      } else {
        _user = current;
      }
    } catch (_) {
      // Don't clear _user on error (e.g. getCurrentUser fails right after OTP)
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setUser(UserModel u) async {
    await _dataSource.saveUser(u);
    await _dataSource.setCurrentUser(u.id);
    _user = u;
    try {
      await init();
      _user ??= u;
    } catch (_) {
      _user = u;
      _loading = false;
    }
    notifyListeners();
  }

  Future<void> completePreTest(AssessmentResultModel result) async {
    await _dataSource.saveAssessmentResult(result);
    _preTestResult = result;
    setPendingGreeting(GreetingType.preTestComplete);

    final preQuestions = await _dataSource.getPreTestQuestions();
    final refIds = AdaptiveLearningService.getReferenceModuleIdsFromWrongAnswers(
      preQuestions,
      result.responses,
    );
    final refModules = _allModules.where((m) => refIds.contains(m.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    _assignedModules = refModules;
    await _dataSource.assignModules(
      _user!.id,
      _assignedModules.map((m) => m.id).toList(),
    );

    notifyListeners();
  }

  /// Refetch pre-test result from the data source (e.g. after app restart so post-test screen can unlock).
  /// Uses current user from data source so we match auth.uid() for Supabase RLS.
  Future<void> refreshPreTestResult() async {
    final current = await _dataSource.getCurrentUser();
    if (current == null || current.id.isEmpty) return;
    try {
      final result = await _dataSource.getPreTestResult(current.id);
      if (result != null) {
        _preTestResult = result;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Full refresh from DB before showing post-test screen (pre-test result, progress, assignments).
  /// Use this when opening the post-test so we never show "Complete the pre-test first" due to stale state.
  Future<void> refreshForPostTest() async {
    final current = await _dataSource.getCurrentUser();
    if (current == null || current.id.isEmpty) {
      debugPrint('[PostTest] refreshForPostTest: no current user');
      return;
    }
    try {
      _user = current;
      debugPrint('[PostTest] refreshForPostTest: user.id=${current.id}');
      _preTestResult = await _dataSource.getPreTestResult(current.id);
      debugPrint('[PostTest] refreshForPostTest: preTestResult=${_preTestResult != null ? "loaded (id=${_preTestResult!.id})" : "null"}');
      _postTestResult = await _dataSource.getPostTestResult(current.id);
      debugPrint('[PostTest] refreshForPostTest: postTestResult=${_postTestResult != null ? "loaded" : "null"}');
      final assignedIds = await _dataSource.getAssignedModuleIds(current.id);
      _assignedModules = _allModules.isNotEmpty
          ? _allModules.where((m) => assignedIds.contains(m.id)).toList()
          : [];
      if (_allModules.isEmpty) {
        _allModules = await _dataSource.getAllModules();
        _assignedModules = _allModules.where((m) => assignedIds.contains(m.id)).toList();
      }
      debugPrint('[PostTest] refreshForPostTest: assignedModules=${_assignedModules.length} ids=${_assignedModules.map((m) => m.id).toList()}');
      final progress = await _dataSource.getModuleProgress(current.id);
      _completedModuleIds = progress
          .where((p) => p.completed)
          .map((p) => p.moduleId)
          .toList();
      debugPrint('[PostTest] refreshForPostTest: completedModuleIds=${_completedModuleIds}');
      notifyListeners();
    } catch (e, st) {
      debugPrint('[PostTest] refreshForPostTest: ERROR $e');
      debugPrint('[PostTest] $st');
    }
  }

  Future<void> completePostTest(AssessmentResultModel result) async {
    await _dataSource.saveAssessmentResult(result);
    _postTestResult = result;
    setPendingGreeting(GreetingType.postTestComplete);
    notifyListeners();
  }

  Future<void> completeModule(String moduleId, int timeSpentSeconds) async {
    _moduleSecondsInProgress.remove(moduleId); // clear so next open starts at 0
    final p = ModuleProgressModel(
      id: '${_user!.id}_$moduleId',
      userId: _user!.id,
      moduleId: moduleId,
      completed: true,
      timeSpentSeconds: timeSpentSeconds,
      completedAt: DateTime.now(),
    );
    // Update in-memory first so "Next Module" and Continue Learning see the correct next module
    // even if the DB save fails (e.g. offline, RLS, missing table).
    _completedModuleIds = [..._completedModuleIds, moduleId];
    notifyListeners();
    try {
      await _dataSource.saveModuleProgress(p);
    } catch (_) {
      // Progress still marked complete in memory; may retry or sync later
    }
  }

  Future<void> logout() async {
    await _dataSource.logout();
    _user = null;
    _preTestResult = null;
    _postTestResult = null;
    _assignedModules = [];
    _completedModuleIds = [];
    notifyListeners();
  }
}
