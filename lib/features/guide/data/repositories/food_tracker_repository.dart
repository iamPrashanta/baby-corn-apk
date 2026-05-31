import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../domain/models/food_intro_record.dart';

final foodTrackerRepositoryProvider = Provider<FoodTrackerRepository>((ref) {
  return FoodTrackerRepository();
});

class FoodTrackerRepository {
  FoodTrackerRepository();

  List<FoodIntroRecord> getRecords(String babyId) {
    final box = HiveManager.getFoodTrackerBox();
    return box.values.where((r) => r.babyId == babyId).toList();
  }

  Future<void> addRecord(FoodIntroRecord record) async {
    final box = HiveManager.getFoodTrackerBox();
    await box.put(record.id, record);
  }

  Future<void> updateRecord(FoodIntroRecord record) async {
    final box = HiveManager.getFoodTrackerBox();
    await box.put(record.id, record);
  }

  Future<void> deleteRecord(String id) async {
    final box = HiveManager.getFoodTrackerBox();
    await box.delete(id);
  }
}
