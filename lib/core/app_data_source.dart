import '../models/user_model.dart';
import '../models/module_model.dart';
import '../models/question_model.dart';
import '../models/assessment_result_model.dart';
import '../models/progress_model.dart';

/// Abstract data source - users table only for auth; no children or preferences.
abstract class AppDataSource {
  Future<UserModel?> getCurrentUser();
  Future<void> setCurrentUser(String userId);
  Future<void> saveUser(UserModel user);
  Future<void> logout();

  Future<AssessmentResultModel?> getPreTestResult(String userId);
  Future<AssessmentResultModel?> getPostTestResult(String userId);
  Future<void> saveAssessmentResult(AssessmentResultModel result);

  Future<List<ModuleModel>> getAllModules();
  Future<ModuleModel?> getModuleById(String id);
  /// Saves or updates a module. For remote (Supabase), pass [coverImageBytes] to upload cover image.
  /// Set [clearCover] true when user removed the cover (e.g. clicked X) so DB cover_image_url is cleared.
  Future<void> saveModule(ModuleModel module, {String? localCoverImagePath, List<int>? coverImageBytes, String? coverImageExtension, bool clearCover = false});
  Future<void> deleteModule(String id);
  Future<List<String>> getAssignedModuleIds(String userId);
  Future<void> assignModules(String userId, List<String> moduleIds);
  Future<List<ModuleProgressModel>> getModuleProgress(String userId);
  Future<void> saveModuleProgress(ModuleProgressModel progress);

  Future<List<QuestionModel>> getPreTestQuestions();
  Future<List<QuestionModel>> getPostTestQuestions();
  Future<void> savePreTestQuestion(QuestionModel question);

  Future<void> ensureSeeded();
}
