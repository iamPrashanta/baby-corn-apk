// features/auth/domain/models/baby_model.dart

class BabyModel {
  final String id;
  final String name;
  final DateTime birthDate;
  final String feedingType;
  final String gender;
  final double birthWeight;

  BabyModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.feedingType,
    required this.gender,
    required this.birthWeight,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'feedingType': feedingType,
      'gender': gender,
      'birthWeight': birthWeight,
    };
  }

  factory BabyModel.fromJson(Map<dynamic, dynamic> json) {
    return BabyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      feedingType: json['feedingType'] as String? ?? 'Mixed',
      gender: json['gender'] as String? ?? 'Prefer not to say',
      birthWeight: (json['birthWeight'] as num?)?.toDouble() ?? 3.2,
    );
  }

  BabyModel copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    String? feedingType,
    String? gender,
    double? birthWeight,
  }) {
    return BabyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      feedingType: feedingType ?? this.feedingType,
      gender: gender ?? this.gender,
      birthWeight: birthWeight ?? this.birthWeight,
    );
  }
}
