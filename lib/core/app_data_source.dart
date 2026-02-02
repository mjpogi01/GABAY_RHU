import '../models/user_model.dart';
import '../models/child_model.dart';
import '../models/module_model.dart';
import '../models/question_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';

/// Abstract data source - SQLite on mobile, in-memory on web
abstract class AppDataSource {
  Future<UserModel?> getCurrentUser();
  Future<ChildModel?> getCurrentChild();
  Future<void> setCurrentUser(String userId);
  Future<void> setCurrentChild(String childId);
  Future<void> saveUser(UserModel user);
  Future<void> saveChild(ChildModel child);
  Future<void> logout();

  Future<AssessmentResultModel?> getPreTestResult(String userId, String childId);
  Future<AssessmentResultModel?> getPostTestResult(String userId, String childId);
  Future<void> saveAssessmentResult(AssessmentResultModel result);

  Future<List<ModuleModel>> getAllModules();
  Future<ModuleModel?> getModuleById(String id);
  Future<List<String>> getAssignedModuleIds(String userId, String childId);
  Future<void> assignModules(String userId, String childId, List<String> moduleIds);
  Future<List<ModuleProgressModel>> getModuleProgress(String userId, String childId);
  Future<void> saveModuleProgress(ModuleProgressModel progress);

  Future<List<QuestionModel>> getPreTestQuestions();
  Future<List<QuestionModel>> getPostTestQuestions();

  Future<void> ensureSeeded();
}
