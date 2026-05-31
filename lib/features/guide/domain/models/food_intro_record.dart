import 'package:hive/hive.dart';

part 'food_intro_record.g.dart';

@HiveType(typeId: 50)
enum FoodIntroStatus {
  @HiveField(0)
  observing,
  @HiveField(1)
  safe,
  @HiveField(2)
  reaction,
}

@HiveType(typeId: 51)
class FoodIntroRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String babyId;

  @HiveField(2)
  final String foodName;

  @HiveField(3)
  final DateTime dateIntroduced;

  @HiveField(4)
  FoodIntroStatus status;

  @HiveField(5)
  List<String> symptoms;

  @HiveField(6)
  String notes;

  @HiveField(7)
  final int ageInMonthsAtIntroduction;

  FoodIntroRecord({
    required this.id,
    required this.babyId,
    required this.foodName,
    required this.dateIntroduced,
    this.status = FoodIntroStatus.observing,
    this.symptoms = const [],
    this.notes = '',
    this.ageInMonthsAtIntroduction = 0,
  });

  FoodIntroRecord copyWith({
    String? id,
    String? babyId,
    String? foodName,
    DateTime? dateIntroduced,
    FoodIntroStatus? status,
    List<String>? symptoms,
    String? notes,
    int? ageInMonthsAtIntroduction,
  }) {
    return FoodIntroRecord(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      foodName: foodName ?? this.foodName,
      dateIntroduced: dateIntroduced ?? this.dateIntroduced,
      status: status ?? this.status,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      ageInMonthsAtIntroduction: ageInMonthsAtIntroduction ?? this.ageInMonthsAtIntroduction,
    );
  }
}

