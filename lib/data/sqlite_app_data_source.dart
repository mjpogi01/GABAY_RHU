import '../models/user_model.dart';
import '../models/child_model.dart';
import '../models/module_model.dart';
import '../models/question_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';
import '../core/app_data_source.dart';
import '../services/auth_service.dart';
import '../repositories/module_repository.dart';
import '../repositories/assessment_repository.dart';
import '../repositories/progress_repository.dart';
import 'seed_data.dart';

/// SQLite-backed data source for mobile (Android, iOS)
class SqliteAppDataSource implements AppDataSource {
  @override
  Future<UserModel?> getCurrentUser() => AuthService.getCurrentUser();

  @override
  Future<ChildModel?> getCurrentChild() => AuthService.getCurrentChild();

  @override
  Future<void> setCurrentUser(String userId) => AuthService.setCurrentUser(userId);

  @override
  Future<void> setCurrentChild(String childId) => AuthService.setCurrentChild(childId);

  @override
  Future<void> saveUser(UserModel user) => AuthService.saveUser(user);

  @override
  Future<void> saveChild(ChildModel child) => AuthService.saveChild(child);

  @override
  Future<void> logout() => AuthService.logout();

  @override
  Future<AssessmentResultModel?> getPreTestResult(String userId, String childId) =>
      AssessmentRepository.getPreTestResult(userId, childId);

  @override
  Future<AssessmentResultModel?> getPostTestResult(String userId, String childId) =>
      AssessmentRepository.getPostTestResult(userId, childId);

  @override
  Future<void> saveAssessmentResult(AssessmentResultModel result) =>
      AssessmentRepository.saveAssessmentResult(result);

  @override
  Future<List<ModuleModel>> getAllModules() => ModuleRepository.getAllModules();

  @override
  Future<ModuleModel?> getModuleById(String id) => ModuleRepository.getModuleById(id);

  @override
  Future<List<String>> getAssignedModuleIds(String userId, String childId) =>
      ProgressRepository.getAssignedModuleIds(userId, childId);

  @override
  Future<void> assignModules(String userId, String childId, List<String> moduleIds) =>
      ProgressRepository.assignModules(userId, childId, moduleIds);

  @override
  Future<List<ModuleProgressModel>> getModuleProgress(String userId, String childId) =>
      ProgressRepository.getModuleProgress(userId, childId);

  @override
  Future<void> saveModuleProgress(ModuleProgressModel progress) =>
      ProgressRepository.saveModuleProgress(progress);

  @override
  Future<List<QuestionModel>> getPreTestQuestions() =>
      AssessmentRepository.getPreTestQuestions();

  @override
  Future<List<QuestionModel>> getPostTestQuestions() =>
      AssessmentRepository.getPostTestQuestions();

  @override
  Future<void> ensureSeeded() => SeedData.ensureSeeded();
}
