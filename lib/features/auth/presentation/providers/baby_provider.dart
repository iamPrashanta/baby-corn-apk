// features/auth/presentation/providers/baby_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/baby_model.dart';
import '../../data/repositories/baby_repository.dart';

final activeBabyProvider = StateNotifierProvider<ActiveBabyNotifier, BabyModel?>((ref) {
  final repository = ref.watch(babyRepositoryProvider);
  return ActiveBabyNotifier(repository);
});

final allBabiesProvider = Provider<List<BabyModel>>((ref) {
  // We watch the activeBabyProvider to trigger a rebuild whenever the baby data is modified,
  // since ActiveBabyNotifier also handles adding/updating babies and updating its state.
  ref.watch(activeBabyProvider);
  final repository = ref.read(babyRepositoryProvider);
  return repository.getBabies();
});

class ActiveBabyNotifier extends StateNotifier<BabyModel?> {
  final BabyRepository _repository;

  ActiveBabyNotifier(this._repository) : super(null) {
    _loadActiveBaby();
  }

  void _loadActiveBaby() {
    final activeId = _repository.getActiveBabyId();
    final babies = _repository.getBabies();
    
    if (babies.isNotEmpty) {
      if (activeId != null) {
        state = babies.firstWhere((b) => b.id == activeId, orElse: () => babies.first);
      } else {
        state = babies.first;
        _repository.setActiveBabyId(state!.id);
      }
    } else {
      state = null;
    }
  }

  Future<void> setActiveBaby(String id) async {
    await _repository.setActiveBabyId(id);
    _loadActiveBaby();
  }

  Future<void> addBaby(BabyModel baby) async {
    await _repository.addBaby(baby);
    _loadActiveBaby(); // Will automatically select if it's the first one
  }

  Future<void> updateBaby(BabyModel baby) async {
    await _repository.updateBaby(baby);
    _loadActiveBaby();
  }
}
