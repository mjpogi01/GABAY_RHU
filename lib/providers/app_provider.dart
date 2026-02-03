import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/module_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';
import '../core/app_data_source.dart';
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

  UserModel? get user => _user;
  AssessmentResultModel? get preTestResult => _preTestResult;
  AssessmentResultModel? get postTestResult => _postTestResult;
  List<ModuleModel> get assignedModules => _assignedModules;
  List<String> get completedModuleIds => _completedModuleIds;
  bool get loading => _loading;

  AppDataSource get dataSource => _dataSource;

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
      if (_user == null) _user = u;
    } catch (_) {
      _user = u;
      _loading = false;
    }
    notifyListeners();
  }

  Future<void> completePreTest(AssessmentResultModel result) async {
    await _dataSource.saveAssessmentResult(result);
    _preTestResult = result;

    final gaps = AdaptiveLearningService.getKnowledgeGaps(result);
    _assignedModules =
        AdaptiveLearningService.getAssignedModules(_allModules, gaps);
    await _dataSource.assignModules(
      _user!.id,
      _assignedModules.map((m) => m.id).toList(),
    );

    notifyListeners();
  }

  Future<void> completePostTest(AssessmentResultModel result) async {
    await _dataSource.saveAssessmentResult(result);
    _postTestResult = result;
    notifyListeners();
  }

  Future<void> completeModule(String moduleId, int timeSpentSeconds) async {
    final p = ModuleProgressModel(
      id: '${_user!.id}_$moduleId',
      userId: _user!.id,
      moduleId: moduleId,
      completed: true,
      timeSpentSeconds: timeSpentSeconds,
      completedAt: DateTime.now(),
    );
    await _dataSource.saveModuleProgress(p);
    _completedModuleIds = [..._completedModuleIds, moduleId];
    notifyListeners();
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
