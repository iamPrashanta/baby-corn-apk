import 'package:hive/hive.dart';

part 'medication_log_model.g.dart';

@HiveType(typeId: 31)
class MedicationLogModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String medicationId;

  @HiveField(2)
  final DateTime scheduledTime;

  @HiveField(3)
  final DateTime? actualTime;

  @HiveField(4)
  final String status; // 'pending', 'taken', 'skipped'

  @HiveField(5)
  final String note;

  @HiveField(6)
  final String takenBy; // For Family Sharing tracking

  MedicationLogModel({
    required this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.actualTime,
    this.status = 'pending',
    this.note = '',
    this.takenBy = '',
  });

  MedicationLogModel copyWith({
    String? id,
    String? medicationId,
    DateTime? scheduledTime,
    DateTime? actualTime,
    String? status,
    String? note,
    String? takenBy,
  }) {
    return MedicationLogModel(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
      note: note ?? this.note,
      takenBy: takenBy ?? this.takenBy,
    );
  }
}
