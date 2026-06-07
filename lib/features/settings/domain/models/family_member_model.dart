import 'package:hive/hive.dart';

part 'family_member_model.g.dart';

@HiveType(typeId: 40)
class FamilyMemberModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String babyId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String phoneNumber;

  @HiveField(4)
  final String email;

  @HiveField(5)
  final String role;

  @HiveField(6)
  final String status;

  @HiveField(7)
  final DateTime invitedAt;

  FamilyMemberModel({
    required this.id,
    required this.babyId,
    required this.name,
    required this.phoneNumber,
    this.email = '',
    this.role = 'Family Member',
    this.status = 'Pending',
    DateTime? invitedAt,
  }) : invitedAt = invitedAt ?? DateTime.now();

  FamilyMemberModel copyWith({
    String? id,
    String? babyId,
    String? name,
    String? phoneNumber,
    String? email,
    String? role,
    String? status,
    DateTime? invitedAt,
  }) {
    return FamilyMemberModel(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      invitedAt: invitedAt ?? this.invitedAt,
    );
  }

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id']?.toString() ?? '',
      babyId: json['babyId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Family Member',
      status: json['status']?.toString() ?? 'Pending',
      invitedAt: json['invitedAt'] != null ? DateTime.tryParse(json['invitedAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'babyId': babyId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role,
      'status': status,
      'invitedAt': invitedAt.toIso8601String(),
    };
  }
}
