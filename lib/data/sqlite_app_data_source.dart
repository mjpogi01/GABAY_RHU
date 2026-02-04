import '../models/user_model.dart';
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

/// SQLite-backed data source (users only; no children or preferences).
class SqliteAppDataSource implements AppDataSource {
  @override
  Future<UserModel?> getCurrentUser() => AuthService.getCurrentUser();

  @override
  Future<void> setCurrentUser(String userId) => AuthService.setCurrentUser(userId);

  @override
  Future<void> saveUser(UserModel user) => AuthService.saveUser(user);

  @override
  Future<void> logout() => AuthService.logout();

  @override
  Future<AssessmentResultModel?> getPreTestResult(String userId) =>
      AssessmentRepository.getPreTestResult(userId);

  @override
  Future<AssessmentResultModel?> getPostTestResult(String userId) =>
      AssessmentRepository.getPostTestResult(userId);

  @override
  Future<void> saveAssessmentResult(AssessmentResultModel result) =>
      AssessmentRepository.saveAssessmentResult(result);

  @override
  Future<List<ModuleModel>> getAllModules() => ModuleRepository.getAllModules();

  @override
  Future<ModuleModel?> getModuleById(String id) => ModuleRepository.getModuleById(id);

  @override
  Future<void> saveModule(ModuleModel module, {String? localCoverImagePath, List<int>? coverImageBytes, String? coverImageExtension}) =>
      ModuleRepository.saveModule(module);

  @override
  Future<void> deleteModule(String id) => ModuleRepository.deleteModule(id);

  @override
  Future<List<String>> getAssignedModuleIds(String userId) =>
      ProgressRepository.getAssignedModuleIds(userId);

  @override
  Future<void> assignModules(String userId, List<String> moduleIds) =>
      ProgressRepository.assignModules(userId, moduleIds);

  @override
  Future<List<ModuleProgressModel>> getModuleProgress(String userId) =>
      ProgressRepository.getModuleProgress(userId);

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
