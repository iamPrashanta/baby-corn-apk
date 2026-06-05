// lib/features/development/domain/models/moment_model.dart

import 'package:hive/hive.dart';

part 'moment_model.g.dart';

@HiveType(typeId: 20)
class MomentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String babyId;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String imagePath;

  MomentModel({
    required this.id,
    required this.babyId,
    required this.timestamp,
    required this.title,
    this.description = '',
    required this.imagePath,
  });

  MomentModel copyWith({
    String? id,
    String? babyId,
    DateTime? timestamp,
    String? title,
    String? description,
    String? imagePath,
  }) {
    return MomentModel(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      timestamp: timestamp ?? this.timestamp,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'babyId': babyId,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'description': description,
      'imagePath': imagePath,
    };
  }

  factory MomentModel.fromJson(Map<String, dynamic> json) {
    return MomentModel(
      id: json['id'] as String,
      babyId: json['babyId'] as String? ?? 'default',
      timestamp: DateTime.parse(json['timestamp'] as String),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imagePath: json['imagePath'] as String,
    );
  }
}
