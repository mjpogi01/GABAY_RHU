/// User progress - module completion (user only, no child)
class ModuleProgressModel {
  final String id;
  final String userId;
  final String moduleId;
  final bool completed;
  final int timeSpentSeconds;
  final DateTime? completedAt;

  const ModuleProgressModel({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.completed,
    this.timeSpentSeconds = 0,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'moduleId': moduleId,
        'completed': completed ? 1 : 0,
        'timeSpentSeconds': timeSpentSeconds,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory ModuleProgressModel.fromJson(Map<String, dynamic> json) =>
      ModuleProgressModel(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        moduleId: json['moduleId']?.toString() ?? '',
        completed: (json['completed'] == 1 || json['completed'] == true),
        timeSpentSeconds: json['timeSpentSeconds'] is int
            ? json['timeSpentSeconds'] as int
            : int.tryParse(json['timeSpentSeconds']?.toString() ?? '') ?? 0,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'].toString())
            : null,
      );
}
