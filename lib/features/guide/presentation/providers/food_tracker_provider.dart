import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../../development/domain/models/moment_model.dart';
import '../../data/repositories/food_tracker_repository.dart';
import '../../domain/models/food_intro_record.dart';
import '../../domain/models/food_library_item.dart';
import '../../../auth/presentation/providers/baby_provider.dart';

final foodTrackerProvider = StateNotifierProvider<FoodTrackerNotifier, List<FoodIntroRecord>>((ref) {
  final repository = ref.watch(foodTrackerRepositoryProvider);
  final activeBaby = ref.watch(activeBabyProvider);
  
  return FoodTrackerNotifier(repository, activeBaby?.id);
});

class FoodTrackerNotifier extends StateNotifier<List<FoodIntroRecord>> {
  final FoodTrackerRepository _repository;
  final String? _babyId;

  FoodTrackerNotifier(this._repository, this._babyId) : super([]) {
    _loadRecords();
  }

  void _loadRecords() {
    if (_babyId == null) {
      state = [];
      return;
    }
    
    // Auto-update statuses based on time elapsed
    final records = _repository.getRecords(_babyId);
    final now = DateTime.now();
    
    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      if (r.status == FoodIntroStatus.observing) {
        final diff = now.difference(r.dateIntroduced).inDays;
        if (diff >= 3) {
          records[i] = r.copyWith(status: FoodIntroStatus.safe);
          _repository.updateRecord(records[i]);
        }
      }
    }
    
    state = records..sort((a, b) => b.dateIntroduced.compareTo(a.dateIntroduced));
  }

  Future<void> addRecord(FoodIntroRecord record) async {
    await _repository.addRecord(record);
    
    try {
      final libraryItem = standardFirstFoods.firstWhere(
        (item) => item.name.toLowerCase() == record.foodName.toLowerCase(),
        orElse: () => const FoodLibraryItem(name: '', category: '', emoji: ''),
      );
      
      final imagePath = libraryItem.imageAssetPath;
      if (imagePath != null) {
        final momentsBox = HiveManager.getMomentsBox();
        final moment = MomentModel(
          id: const Uuid().v4(),
          babyId: record.babyId,
          timestamp: record.dateIntroduced,
          title: 'First ${record.foodName}',
          description: 'Started observing ${record.foodName}.',
          imagePath: imagePath,
        );
        await momentsBox.put(moment.id, moment);
      }
    } catch (e) {
      // Ignore
    }

    _loadRecords();
  }

  Future<void> updateRecord(FoodIntroRecord record) async {
    await _repository.updateRecord(record);
    _loadRecords();
  }

  Future<void> deleteRecord(String id) async {
    await _repository.deleteRecord(id);
    _loadRecords();
  }
}
