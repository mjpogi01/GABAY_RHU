import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/child_model.dart';
import '../models/module_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';
import '../core/app_data_source.dart';
import '../services/adaptive_learning_service.dart';

/// App-wide state provider
class AppProvider extends ChangeNotifier {
  AppProvider(this._dataSource);

  final AppDataSource _dataSource;

  UserModel? _user;
  ChildModel? _child;
  AssessmentResultModel? _preTestResult;
  AssessmentResultModel? _postTestResult;
  List<ModuleModel> _allModules = [];
  List<ModuleModel> _assignedModules = [];
  List<String> _completedModuleIds = [];
  bool _loading = true;

  UserModel? get user => _user;
  ChildModel? get child => _child;
  AssessmentResultModel? get preTestResult => _preTestResult;
  AssessmentResultModel? get postTestResult => _postTestResult;
  List<ModuleModel> get assignedModules => _assignedModules;
  List<String> get completedModuleIds => _completedModuleIds;
  bool get loading => _loading;

  AppDataSource get dataSource => _dataSource;

  bool get hasCompletedPreTest => _preTestResult != null;
  bool get hasCompletedPostTest => _postTestResult != null;

  bool get canAccessPostTest {
    if (_user == null || _child == null || _preTestResult == null) return false;
    return AdaptiveLearningService.canAccessPostTest(
      preTestCompletedAt: _preTestResult!.completedAt,
      assignedModuleIds: _assignedModules.map((m) => m.id).toList(),
      completedModuleIds: _completedModuleIds,
    );
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    await _dataSource.ensureSeeded();

    _user = await _dataSource.getCurrentUser();
    _child = await _dataSource.getCurrentChild();

    if (_user != null && _child != null) {
      _preTestResult = await _dataSource.getPreTestResult(_user!.id, _child!.id);
      _postTestResult = await _dataSource.getPostTestResult(_user!.id, _child!.id);
      _allModules = await _dataSource.getAllModules();
      final assignedIds =
          await _dataSource.getAssignedModuleIds(_user!.id, _child!.id);
      _assignedModules = _allModules.where((m) => assignedIds.contains(m.id)).toList();
      final progress =
          await _dataSource.getModuleProgress(_user!.id, _child!.id);
      _completedModuleIds = progress
          .where((p) => p.completed)
          .map((p) => p.moduleId)
          .toList();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> setUserAndChild(UserModel u, ChildModel c) async {
    await _dataSource.saveUser(u);
    await _dataSource.saveChild(c);
    await _dataSource.setCurrentUser(u.id);
    await _dataSource.setCurrentChild(c.id);
    _user = u;
    _child = c;
    await init();
  }

  Future<void> completePreTest(AssessmentResultModel result) async {
    await _dataSource.saveAssessmentResult(result);
    _preTestResult = result;

    final gaps = AdaptiveLearningService.getKnowledgeGaps(result);
    _assignedModules =
        AdaptiveLearningService.getAssignedModules(_allModules, gaps);
    await _dataSource.assignModules(
      _user!.id,
      _child!.id,
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
        id: '${_user!.id}_${_child!.id}_$moduleId',
        userId: _user!.id,
        childId: _child!.id,
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
    _child = null;
    _preTestResult = null;
    _postTestResult = null;
    _assignedModules = [];
    _completedModuleIds = [];
    notifyListeners();
  }
}
