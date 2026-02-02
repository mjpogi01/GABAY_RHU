/// Child profile - linked to caregiver (0-2 years)
class ChildModel {
  final String id;
  final String caregiverId;
  final DateTime dateOfBirth;
  final String? anonymizedChildId; // For research

  const ChildModel({
    required this.id,
    required this.caregiverId,
    required this.dateOfBirth,
    this.anonymizedChildId,
  });

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - dateOfBirth.year) * 12 +
        (now.month - dateOfBirth.month);
  }

  bool get isInAgeRange => ageInMonths >= 0 && ageInMonths <= 24;

  Map<String, dynamic> toJson() => {
        'id': id,
        'caregiverId': caregiverId,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'anonymizedChildId': anonymizedChildId,
      };

  factory ChildModel.fromJson(Map<String, dynamic> json) => ChildModel(
        id: json['id'] as String,
        caregiverId: json['caregiverId'] as String,
        dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
        anonymizedChildId: json['anonymizedChildId'] as String?,
      );
}
