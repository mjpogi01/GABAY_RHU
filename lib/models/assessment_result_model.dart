/// Pre-test or post-test result (user only, no child)
class AssessmentResultModel {
  final String id;
  final String userId;
  final String type; // 'pre_test' or 'post_test'
  final Map<String, int> domainScores;
  final Map<String, int> domainTotals;
  final int totalCorrect;
  final int totalQuestions;
  final DateTime completedAt;
  final List<QuestionResponse> responses;

  const AssessmentResultModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.domainScores,
    required this.domainTotals,
    required this.totalCorrect,
    required this.totalQuestions,
    required this.completedAt,
    required this.responses,
  });

  double get overallScore => totalQuestions > 0 ? totalCorrect / totalQuestions : 0;

  double domainScore(String domain) {
    final total = domainTotals[domain] ?? 0;
    if (total == 0) return 0;
    return (domainScores[domain] ?? 0) / total;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'domainScores': domainScores,
        'domainTotals': domainTotals,
        'totalCorrect': totalCorrect,
        'totalQuestions': totalQuestions,
        'completedAt': completedAt.toIso8601String(),
        'responses': responses.map((r) => r.toJson()).toList(),
      };

  factory AssessmentResultModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final userId = json['userId']?.toString() ?? '';
    final type = json['type']?.toString() ?? '';
    final domainScores = json['domainScores'] is Map
        ? Map<String, int>.from(json['domainScores'] as Map)
        : <String, int>{};
    final domainTotals = json['domainTotals'] is Map
        ? Map<String, int>.from(json['domainTotals'] as Map)
        : <String, int>{};
    final totalCorrect = json['totalCorrect'] is int
        ? json['totalCorrect'] as int
        : int.tryParse(json['totalCorrect']?.toString() ?? '') ?? 0;
    final totalQuestions = json['totalQuestions'] is int
        ? json['totalQuestions'] as int
        : int.tryParse(json['totalQuestions']?.toString() ?? '') ?? 0;
    final completedAt = json['completedAt'] != null
        ? DateTime.tryParse(json['completedAt'].toString()) ?? DateTime.now()
        : DateTime.now();
    final responsesRaw = json['responses'];
    final responses = responsesRaw is List
        ? (responsesRaw)
            .map<QuestionResponse>((r) => QuestionResponse.fromJson(Map<String, dynamic>.from(r is Map ? r : <String, dynamic>{})))
            .toList()
        : <QuestionResponse>[];
    return AssessmentResultModel(
      id: id,
      userId: userId,
      type: type,
      domainScores: domainScores,
      domainTotals: domainTotals,
      totalCorrect: totalCorrect,
      totalQuestions: totalQuestions,
      completedAt: completedAt,
      responses: responses,
    );
  }
}

class QuestionResponse {
  final String questionId;
  final int selectedIndex;
  final bool isCorrect;

  const QuestionResponse({
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'selectedIndex': selectedIndex,
        'isCorrect': isCorrect ? 1 : 0,
      };

  factory QuestionResponse.fromJson(Map<String, dynamic> json) =>
      QuestionResponse(
        questionId: json['questionId']?.toString() ?? '',
        selectedIndex: json['selectedIndex'] is int
            ? json['selectedIndex'] as int
            : int.tryParse(json['selectedIndex']?.toString() ?? '') ?? 0,
        isCorrect: (json['isCorrect'] == 1 || json['isCorrect'] == true),
      );
}
