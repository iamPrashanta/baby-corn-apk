// lib/features/auth/domain/models/baby_model.dart

class BabyModel {
  final String id;
  final String name;
  final DateTime birthDate;
  final String? birthTime; // In format "HH:MM"
  final String feedingType;
  final String gender;
  final double birthWeight;
  final double? birthHeight;

  /// Optional emoji avatar for visual identity across multiple baby profiles.
  /// Defaults to '👶' when not set (backward-compatible).
  final String avatarEmoji;
  final String? profileImagePath;

  BabyModel({
    required this.id,
    required this.name,
    required this.birthDate,
    this.birthTime,
    required this.feedingType,
    required this.gender,
    required this.birthWeight,
    this.birthHeight,
    this.avatarEmoji = '👶',
    this.profileImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'birthTime': birthTime,
      'feedingType': feedingType,
      'gender': gender,
      'birthWeight': birthWeight,
      'birthHeight': birthHeight,
      'avatarEmoji': avatarEmoji,
      'profileImagePath': profileImagePath,
    };
  }

  factory BabyModel.fromJson(Map<dynamic, dynamic> json) {
    return BabyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      birthTime: json['birthTime'] as String?,
      feedingType: json['feedingType'] as String? ?? 'Mixed',
      gender: json['gender'] as String? ?? 'Prefer not to say',
      birthWeight: (json['birthWeight'] as num?)?.toDouble() ?? 3.2,
      birthHeight: (json['birthHeight'] as num?)?.toDouble(),
      avatarEmoji: json['avatarEmoji'] as String? ?? '👶',
      profileImagePath: json['profileImagePath'] as String?,
    );
  }

  BabyModel copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    String? birthTime,
    String? feedingType,
    String? gender,
    double? birthWeight,
    double? birthHeight,
    String? avatarEmoji,
    String? profileImagePath,
    bool clearProfileImage = false,
  }) {
    return BabyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      feedingType: feedingType ?? this.feedingType,
      gender: gender ?? this.gender,
      birthWeight: birthWeight ?? this.birthWeight,
      birthHeight: birthHeight ?? this.birthHeight,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      profileImagePath: clearProfileImage ? null : (profileImagePath ?? this.profileImagePath),
    );
  }
}
