/// User progress - module completion, time spent, certificate
class ModuleProgressModel {
  final String id;
  final String userId;
  final String childId;
  final String moduleId;
  final bool completed;
  final int timeSpentSeconds;
  final DateTime? completedAt;

  const ModuleProgressModel({
    required this.id,
    required this.userId,
    required this.childId,
    required this.moduleId,
    required this.completed,
    this.timeSpentSeconds = 0,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'childId': childId,
        'moduleId': moduleId,
        'completed': completed ? 1 : 0,
        'timeSpentSeconds': timeSpentSeconds,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory ModuleProgressModel.fromJson(Map<String, dynamic> json) =>
      ModuleProgressModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        childId: json['childId'] as String,
        moduleId: json['moduleId'] as String,
        completed: (json['completed'] as int?) == 1,
        timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}
