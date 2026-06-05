import 'package:hive/hive.dart';

part 'medication_model.g.dart';

@HiveType(typeId: 30)
class MedicationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String babyId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String type; // Tablet, Capsule, Syrup, Drops, Injection, Powder, Supplement

  @HiveField(4)
  final String prescribedFor; // Baby, Mother

  @HiveField(5)
  final String scheduleType; // OD, BD, TDS, QDS, SOS, Custom

  @HiveField(6)
  final List<String> times; // e.g., ["08:00 AM", "08:00 PM"]

  @HiveField(7)
  final double doseAmount;

  @HiveField(8)
  final String doseUnit; // Capsule(s), Tablet(s), ml, Drop(s)

  @HiveField(9)
  final double totalQuantity; // Stock amount

  @HiveField(10)
  final double remainingQuantity;

  @HiveField(11)
  final double lowStockThreshold;

  @HiveField(12)
  final DateTime startDate;

  @HiveField(13)
  final DateTime? endDate;

  @HiveField(14)
  final String notes;

  @HiveField(15)
  final bool isActive;
  
  @HiveField(16)
  final String? doctorName;

  @HiveField(17)
  final String? reason;

  MedicationModel({
    required this.id,
    required this.babyId,
    required this.name,
    required this.type,
    required this.prescribedFor,
    required this.scheduleType,
    required this.times,
    required this.doseAmount,
    required this.doseUnit,
    required this.totalQuantity,
    required this.remainingQuantity,
    required this.lowStockThreshold,
    required this.startDate,
    this.endDate,
    this.notes = '',
    this.isActive = true,
    this.doctorName,
    this.reason,
  });

  MedicationModel copyWith({
    String? id,
    String? babyId,
    String? name,
    String? type,
    String? prescribedFor,
    String? scheduleType,
    List<String>? times,
    double? doseAmount,
    String? doseUnit,
    double? totalQuantity,
    double? remainingQuantity,
    double? lowStockThreshold,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    bool? isActive,
    String? doctorName,
    String? reason,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      name: name ?? this.name,
      type: type ?? this.type,
      prescribedFor: prescribedFor ?? this.prescribedFor,
      scheduleType: scheduleType ?? this.scheduleType,
      times: times ?? this.times,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      doctorName: doctorName ?? this.doctorName,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'babyId': babyId,
      'name': name,
      'type': type,
      'prescribedFor': prescribedFor,
      'scheduleType': scheduleType,
      'times': times,
      'doseAmount': doseAmount,
      'doseUnit': doseUnit,
      'totalQuantity': totalQuantity,
      'remainingQuantity': remainingQuantity,
      'lowStockThreshold': lowStockThreshold,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'isActive': isActive,
      'doctorName': doctorName,
      'reason': reason,
    };
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as String,
      babyId: json['babyId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      prescribedFor: json['prescribedFor'] as String,
      scheduleType: json['scheduleType'] as String,
      times: List<String>.from(json['times'] ?? []),
      doseAmount: (json['doseAmount'] as num).toDouble(),
      doseUnit: json['doseUnit'] as String,
      totalQuantity: (json['totalQuantity'] as num).toDouble(),
      remainingQuantity: (json['remainingQuantity'] as num).toDouble(),
      lowStockThreshold: (json['lowStockThreshold'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      notes: json['notes'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      doctorName: json['doctorName'] as String?,
      reason: json['reason'] as String?,
    );
  }
}
