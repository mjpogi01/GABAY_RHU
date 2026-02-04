/// Learning module - data-driven, expert-validated content
class ModuleModel {
  final String id;
  final String title;
  final String domain; // Knowledge domain
  final int order;
  final List<ModuleCard> cards;
  /// Admin-defined display number (e.g. M01, 1). Shown on cards; separate from internal id.
  final String? moduleNumber;

  const ModuleModel({
    required this.id,
    required this.title,
    required this.domain,
    required this.order,
    required this.cards,
    this.moduleNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'domain': domain,
        'order': order,
        'cards': cards.map((c) => c.toJson()).toList(),
        'moduleNumber': moduleNumber,
      };

  factory ModuleModel.fromJson(Map<String, dynamic> json) => ModuleModel(
        id: json['id'] as String,
        title: json['title'] as String,
        domain: json['domain'] as String,
        order: json['order'] as int,
        cards: (json['cards'] as List<dynamic>)
            .map((c) => ModuleCard.fromJson(c as Map<String, dynamic>))
            .toList(),
        moduleNumber: json['moduleNumber'] as String?,
      );
}

/// Single card in a module (swipeable, sequential)
class ModuleCard {
  final String id;
  final String content;
  final String? imagePath;
  final int order;

  const ModuleCard({
    required this.id,
    required this.content,
    this.imagePath,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'imagePath': imagePath,
        'order': order,
      };

  factory ModuleCard.fromJson(Map<String, dynamic> json) => ModuleCard(
        id: json['id']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        imagePath: json['imagePath']?.toString(),
        order: json['order'] is int
            ? json['order'] as int
            : int.tryParse(json['order']?.toString() ?? '') ?? 0,
      );
}
