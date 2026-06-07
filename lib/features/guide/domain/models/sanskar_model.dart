// lib/features/guide/domain/models/sanskar_model.dart

import 'package:hive/hive.dart';

part 'sanskar_model.g.dart';

@HiveType(typeId: 4)
enum SanskarOffsetUnit {
  @HiveField(0)
  days,
  @HiveField(1)
  months,
  @HiveField(2)
  years,
  @HiveField(3)
  beforeBirth,
}

@HiveType(typeId: 3)
class SanskarRule extends HiveObject {
  @HiveField(0)
  final int offset;

  @HiveField(1)
  final SanskarOffsetUnit unit;

  @HiveField(2)
  final String traditionalTimingText;

  SanskarRule({
    required this.offset,
    required this.unit,
    required this.traditionalTimingText,
  });

  factory SanskarRule.fromJson(Map<String, dynamic> json) {
    return SanskarRule(
      offset: json['offset'] as int,
      unit: SanskarOffsetUnit.values.firstWhere(
        (e) => e.toString().split('.').last == json['unit'],
        orElse: () => SanskarOffsetUnit.days,
      ),
      traditionalTimingText: json['traditionalTimingText'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'unit': unit.toString().split('.').last,
      'traditionalTimingText': traditionalTimingText,
    };
  }
}

@HiveType(typeId: 2)
class SanskarModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String sanskritName;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String emojiIcon;

  @HiveField(6)
  final SanskarRule defaultRule;

  @HiveField(7)
  DateTime? customDate;

  @HiveField(8)
  bool isCompleted;

  @HiveField(9)
  String notes;

  @HiveField(10)
  bool reminderEnabled;

  @HiveField(11)
  final String babyId;

  SanskarModel({
    required this.id,
    required this.name,
    required this.sanskritName,
    required this.description,
    required this.category,
    required this.emojiIcon,
    required this.defaultRule,
    this.customDate,
    this.isCompleted = false,
    this.notes = '',
    this.reminderEnabled = true,
    this.babyId = '', // Default for backward compatibility
  });

  SanskarModel copyWith({
    String? id,
    String? name,
    String? sanskritName,
    String? description,
    String? category,
    String? emojiIcon,
    SanskarRule? defaultRule,
    DateTime? customDate,
    bool? isCompleted,
    String? notes,
    bool? reminderEnabled,
    String? babyId,
  }) {
    return SanskarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sanskritName: sanskritName ?? this.sanskritName,
      description: description ?? this.description,
      category: category ?? this.category,
      emojiIcon: emojiIcon ?? this.emojiIcon,
      defaultRule: defaultRule ?? this.defaultRule,
      customDate: customDate ?? this.customDate,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      babyId: babyId ?? this.babyId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sanskritName': sanskritName,
      'description': description,
      'category': category,
      'emojiIcon': emojiIcon,
      'defaultRule': defaultRule.toJson(),
      'customDate': customDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
      'babyId': babyId,
    };
  }

  factory SanskarModel.fromJson(Map<String, dynamic> json) {
    return SanskarModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sanskritName: json['sanskritName'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      emojiIcon: json['emojiIcon'] as String,
      defaultRule: SanskarRule.fromJson(Map<String, dynamic>.from(json['defaultRule'])),
      customDate: json['customDate'] != null ? DateTime.parse(json['customDate'] as String) : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      babyId: json['babyId'] as String? ?? '',
    );
  }
}
