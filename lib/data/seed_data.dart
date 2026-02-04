import '../models/module_model.dart';
import '../models/question_model.dart';
import '../repositories/module_repository.dart';
import '../repositories/assessment_repository.dart';

/// No seed data: modules and questions are added by admins (Supabase) or in-app.
/// ensureSeeded() only ensures DB is ready (empty modules/questions for SQLite).
class SeedData {
  static bool _seeded = false;

  static Future<void> ensureSeeded() async {
    if (_seeded) return;
    await ModuleRepository.seedModules([]);
    await AssessmentRepository.seedQuestions([]);
    _seeded = true;
  }

  static List<ModuleModel> getSampleModules() => [];
  static List<QuestionModel> getPreTestQuestions() => [];
  static List<QuestionModel> getPostTestQuestions() => [];
}
