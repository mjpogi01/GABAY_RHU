/// User model - Parent/Caregiver, BHW, or Admin
/// Non-sensitive data only (Philippine Data Privacy Act compliant)
class UserModel {
  final String id;
  final String anonymizedId; // For research analysis
  final String role; // parent, bhw, admin
  final String? rhuCode;
  final String? barangayCode;
  final DateTime createdAt;
  final bool consentGiven;
  // Profile fields (from design)
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? address;
  final String? status; // New Mother, Expecting Mother, Caregiver/Guardian
  final int? numberOfChildren;
  final bool? hasInfant;

  const UserModel({
    required this.id,
    required this.anonymizedId,
    required this.role,
    this.rhuCode,
    this.barangayCode,
    required this.createdAt,
    this.consentGiven = true,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.address,
    this.status,
    this.numberOfChildren,
    this.hasInfant,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    if (firstName != null) return firstName!;
    return 'User';
  }

  bool get isParent => role == 'parent';
  bool get isBHW => role == 'bhw';
  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
        'id': id,
        'anonymizedId': anonymizedId,
        'role': role,
        'rhuCode': rhuCode,
        'barangayCode': barangayCode,
        'createdAt': createdAt.toIso8601String(),
        'consentGiven': consentGiven ? 1 : 0,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'address': address,
        'status': status,
        'numberOfChildren': numberOfChildren,
        'hasInfant': hasInfant,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        anonymizedId: json['anonymizedId'] as String,
        role: json['role'] as String,
        rhuCode: json['rhuCode'] as String?,
        barangayCode: json['barangayCode'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        consentGiven: (json['consentGiven'] as int?) == 1,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        address: json['address'] as String?,
        status: json['status'] as String?,
        numberOfChildren: json['numberOfChildren'] as int?,
        hasInfant: json['hasInfant'] as bool?,
      );

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? status,
    int? numberOfChildren,
    bool? hasInfant,
  }) =>
      UserModel(
        id: id,
        anonymizedId: anonymizedId,
        role: role,
        rhuCode: rhuCode,
        barangayCode: barangayCode,
        createdAt: createdAt,
        consentGiven: consentGiven,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        address: address ?? this.address,
        status: status ?? this.status,
        numberOfChildren: numberOfChildren ?? this.numberOfChildren,
        hasInfant: hasInfant ?? this.hasInfant,
      );
}
