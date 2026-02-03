import 'dart:convert';

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

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Map database fields to model fields
    // Database has: id, type, question, options (JSONB), correct_answer, order_index
    final id = json['id'] as String? ?? '';
    
    // Handle question text (database uses 'question', model uses 'text')
    final questionText = json['question'] as String? ?? json['text'] as String? ?? '';
    
    // Handle options (can be List or JSONB string)
    final optionsJson = json['options'];
    List<String> options = [];
    if (optionsJson != null) {
      if (optionsJson is List) {
        options = List<String>.from(optionsJson.map((e) => e.toString()));
      } else if (optionsJson is String) {
        try {
          final decoded = jsonDecode(optionsJson) as List;
          options = decoded.map((e) => e.toString()).toList();
        } catch (e) {
          options = [];
        }
      }
    }
    
    // Find correct index from correct_answer
    final correctAnswer = json['correct_answer'] as String? ?? '';
    final correctIndex = options.isNotEmpty && correctAnswer.isNotEmpty
        ? options.indexOf(correctAnswer)
        : 0;
    
    // Handle optional fields with defaults (not in database schema)
    final pairedId = json['pairedId'] as String? ?? id; // Default to same as id if not provided
    final domain = json['domain'] as String? ?? 'general'; // Default domain
    final explanation = json['explanation'] as String?; // Optional field
    
    return QuestionModel(
      id: id,
      pairedId: pairedId,
      domain: domain,
      text: questionText,
      options: options,
      correctIndex: correctIndex >= 0 ? correctIndex : 0,
      explanation: explanation,
    );
  }
}
