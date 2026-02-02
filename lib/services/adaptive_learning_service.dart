import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/assessment_result_model.dart';
import '../models/module_model.dart';
import '../models/question_model.dart';

/// Rule-based adaptive logic
/// Incorrect pre-test answers determine which modules are assigned
class AdaptiveLearningService {
  /// Get domains where user scored below threshold (knowledge gaps)
  /// Threshold: e.g. 0.7 = 70% correct
  static List<String> getKnowledgeGaps(
    AssessmentResultModel preTestResult, {
    double threshold = 0.7,
  }) {
    final gaps = <String>[];
    for (final domain in preTestResult.domainTotals.keys) {
      final score = preTestResult.domainScore(domain);
      if (score < threshold) {
        gaps.add(domain);
      }
    }
    return gaps;
  }

  /// Assign modules based on knowledge gaps
  /// Only modules whose domain is in gaps are required
  static List<ModuleModel> getAssignedModules(
    List<ModuleModel> allModules,
    List<String> knowledgeGaps,
  ) {
    return allModules
        .where((m) => knowledgeGaps.contains(m.domain))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Check if user can access post-test
  /// Requires: all assigned modules completed, and within post-test window
  static bool canAccessPostTest({
    required DateTime preTestCompletedAt,
    required List<String> assignedModuleIds,
    required List<String> completedModuleIds,
  }) {
    final allAssignedCompleted = assignedModuleIds.every(
      (id) => completedModuleIds.contains(id),
    );
    if (!allAssignedCompleted) return false;

    // In debug mode, allow immediate post-test for testing
    if (kDebugMode) return true;

    final daysSincePreTest = DateTime.now().difference(preTestCompletedAt).inDays;
    return daysSincePreTest >= AppConstants.postTestMinDays &&
        daysSincePreTest <= AppConstants.postTestMaxDays;
  }

  /// Get post-test questions (paraphrased, same intent as pre-test)
  /// Maps pre-test question IDs to post-test question IDs via pairedId
  static List<QuestionModel> getPostTestQuestions(
    List<QuestionResponse> preTestResponses,
    List<QuestionModel> allPostTestQuestions,
  ) {
    final preQuestionIds = preTestResponses.map((r) => r.questionId).toSet();
    final postQuestions = <QuestionModel>[];
    for (final q in allPostTestQuestions) {
      if (preQuestionIds.contains(q.pairedId)) {
        postQuestions.add(q);
      }
    }
    return postQuestions;
  }

  /// Check if user meets certificate benchmark
  static bool meetsCertificateBenchmark(AssessmentResultModel postTestResult) {
    return postTestResult.overallScore >= AppConstants.certificateBenchmark;
  }
}
