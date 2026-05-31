import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/food_tracker_repository.dart';
import '../../domain/models/food_intro_record.dart';
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
    final records = _repository.getRecords(_babyId!);
    final now = DateTime.now();
    bool needsUpdate = false;
    
    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      if (r.status == FoodIntroStatus.observing) {
        final diff = now.difference(r.dateIntroduced).inDays;
        if (diff >= 3) {
          records[i] = r.copyWith(status: FoodIntroStatus.safe);
          _repository.updateRecord(records[i]);
          needsUpdate = true;
        }
      }
    }
    
    state = records..sort((a, b) => b.dateIntroduced.compareTo(a.dateIntroduced));
  }

  Future<void> addRecord(FoodIntroRecord record) async {
    await _repository.addRecord(record);
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
