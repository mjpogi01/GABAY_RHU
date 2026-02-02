/// Assessment question - pre-test and post-test
/// Post-test uses paraphrased questions with same intent
class QuestionModel {
  final String id;
  final String pairedId; // Links pre-test Q to post-test Q (same intent)
  final String domain;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String? explanation; // Shown after assessment for feedback

  const QuestionModel({
    required this.id,
    required this.pairedId,
    required this.domain,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pairedId': pairedId,
        'domain': domain,
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };

  factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
        id: json['id'] as String,
        pairedId: json['pairedId'] as String,
        domain: json['domain'] as String,
        text: json['text'] as String,
        options: List<String>.from(json['options'] as List),
        correctIndex: json['correctIndex'] as int,
        explanation: json['explanation'] as String?,
      );
}
