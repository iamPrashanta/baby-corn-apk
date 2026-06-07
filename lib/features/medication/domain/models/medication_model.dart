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

  @HiveField(15, defaultValue: true)
  final bool isActive;
  
  @HiveField(16)
  final String? doctorName;

  @HiveField(17)
  final String? reason;

  @HiveField(18, defaultValue: 5)
  final int notifyBeforeMinutes;

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
    this.notifyBeforeMinutes = 5,
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
    int? notifyBeforeMinutes,
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
      notifyBeforeMinutes: notifyBeforeMinutes ?? this.notifyBeforeMinutes,
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
      'notifyBeforeMinutes': notifyBeforeMinutes,
    };
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id']?.toString() ?? '',
      babyId: json['babyId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      prescribedFor: json['prescribedFor']?.toString() ?? '',
      scheduleType: json['scheduleType']?.toString() ?? '',
      times: List<String>.from(json['times'] ?? []),
      doseAmount: (json['doseAmount'] as num?)?.toDouble() ?? 0.0,
      doseUnit: json['doseUnit']?.toString() ?? '',
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0.0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      notes: json['notes']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
      doctorName: json['doctorName']?.toString(),
      reason: json['reason']?.toString(),
      notifyBeforeMinutes: json['notifyBeforeMinutes'] as int? ?? 5,
    );
  }
}
