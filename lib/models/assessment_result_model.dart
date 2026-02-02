/// Pre-test or post-test result
class AssessmentResultModel {
  final String id;
  final String userId;
  final String childId;
  final String type; // 'pre' or 'post'
  final Map<String, int> domainScores; // domain -> correct count
  final Map<String, int> domainTotals; // domain -> total questions
  final int totalCorrect;
  final int totalQuestions;
  final DateTime completedAt;
  final List<QuestionResponse> responses;

  const AssessmentResultModel({
    required this.id,
    required this.userId,
    required this.childId,
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
        'childId': childId,
        'type': type,
        'domainScores': domainScores,
        'domainTotals': domainTotals,
        'totalCorrect': totalCorrect,
        'totalQuestions': totalQuestions,
        'completedAt': completedAt.toIso8601String(),
        'responses': responses.map((r) => r.toJson()).toList(),
      };

  factory AssessmentResultModel.fromJson(Map<String, dynamic> json) =>
      AssessmentResultModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        childId: json['childId'] as String,
        type: json['type'] as String,
        domainScores: Map<String, int>.from(json['domainScores'] as Map),
        domainTotals: Map<String, int>.from(json['domainTotals'] as Map),
        totalCorrect: json['totalCorrect'] as int,
        totalQuestions: json['totalQuestions'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
        responses: (json['responses'] as List<dynamic>)
            .map((r) => QuestionResponse.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
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
        questionId: json['questionId'] as String,
        selectedIndex: json['selectedIndex'] as int,
        isCorrect: (json['isCorrect'] as int?) == 1,
      );
}
