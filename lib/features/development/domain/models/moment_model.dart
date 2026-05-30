import 'package:hive/hive.dart';

part 'moment_model.g.dart';

@HiveType(typeId: 4)
class MomentModel {
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
}
