// features/records/domain/models/active_session_model.dart

import 'package:hive/hive.dart';

part 'active_session_model.g.dart';

@HiveType(typeId: 1)
class ActiveSessionModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String type; // e.g., 'feeding', 'sleep', 'tummy_time'
  
  @HiveField(2)
  final DateTime startTime;
  
  @HiveField(3)
  final DateTime? pausedAt;
  
  @HiveField(4)
  final int totalPausedDurationSeconds;
  
  @HiveField(5)
  final bool isRunning;
  
  @HiveField(6)
  final Map<String, dynamic> metadata;

  @HiveField(7)
  final String? notes;

  ActiveSessionModel({
    required this.id,
    required this.type,
    required this.startTime,
    this.pausedAt,
    this.totalPausedDurationSeconds = 0,
    this.isRunning = true,
    this.metadata = const {},
    this.notes,
  });

  ActiveSessionModel copyWith({
    String? id,
    String? type,
    DateTime? startTime,
    DateTime? pausedAt,
    int? totalPausedDurationSeconds,
    bool? isRunning,
    Map<String, dynamic>? metadata,
    String? notes,
  }) {
    return ActiveSessionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      // We allow explicitly setting pausedAt to null if we pass a special value, but for simplicity:
      // if you want to clear pausedAt, you'll need to do it manually or pass it.
      // Here, let's just make it simple.
      pausedAt: pausedAt, // This might not clear pausedAt. Better to pass a bool clearPausedAt.
      totalPausedDurationSeconds: totalPausedDurationSeconds ?? this.totalPausedDurationSeconds,
      isRunning: isRunning ?? this.isRunning,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
    );
  }

  // Helper method to properly handle clearing pausedAt
  ActiveSessionModel copyWithClearPaused({
    String? id,
    String? type,
    DateTime? startTime,
    int? totalPausedDurationSeconds,
    bool? isRunning,
    Map<String, dynamic>? metadata,
    String? notes,
  }) {
     return ActiveSessionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      pausedAt: null,
      totalPausedDurationSeconds: totalPausedDurationSeconds ?? this.totalPausedDurationSeconds,
      isRunning: isRunning ?? this.isRunning,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
    );
  }

  Duration get currentDuration {
    if (!isRunning && pausedAt != null) {
      return pausedAt!.difference(startTime) - Duration(seconds: totalPausedDurationSeconds);
    }
    return DateTime.now().difference(startTime) - Duration(seconds: totalPausedDurationSeconds);
  }
}
