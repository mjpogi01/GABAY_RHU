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

  factory ModuleProgressModel.fromJson(Map<String, dynamic> json) {
    // Accept both camelCase (app/SQLite) and snake_case (Supabase/Postgres)
    final id = json['id']?.toString() ?? '';
    final userId = json['userId']?.toString() ?? json['user_id']?.toString() ?? '';
    final moduleId = json['moduleId']?.toString() ?? json['module_id']?.toString() ?? '';
    final completed = json['completed'] == 1 ||
        json['completed'] == true ||
        (json['completed'] is bool && json['completed'] as bool);
    final timeSpentSeconds = json['timeSpentSeconds'] is int
        ? json['timeSpentSeconds'] as int
        : (json['time_spent_seconds'] is int
            ? json['time_spent_seconds'] as int
            : int.tryParse(json['timeSpentSeconds']?.toString() ?? json['time_spent_seconds']?.toString() ?? '') ?? 0);
    final completedAtRaw = json['completedAt'] ?? json['completed_at'];
    final completedAt = completedAtRaw != null
        ? DateTime.tryParse(completedAtRaw.toString())
        : null;
    return ModuleProgressModel(
      id: id.isEmpty && userId.isNotEmpty && moduleId.isNotEmpty
          ? '${userId}_$moduleId'
          : id,
      userId: userId,
      moduleId: moduleId,
      completed: completed,
      timeSpentSeconds: timeSpentSeconds,
      completedAt: completedAt,
    );
  }
}
