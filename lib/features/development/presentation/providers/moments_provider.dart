import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../../core/local_storage/hive_manager.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../domain/models/moment_model.dart';

final momentsProvider = StateNotifierProvider<MomentsNotifier, AsyncValue<List<MomentModel>>>((ref) {
  final activeBaby = ref.watch(activeBabyProvider);
  return MomentsNotifier(activeBaby?.id);
});

class MomentsNotifier extends StateNotifier<AsyncValue<List<MomentModel>>> {
  final String? _activeBabyId;
  final _box = HiveManager.getMomentsBox();

  MomentsNotifier(this._activeBabyId) : super(const AsyncValue.loading()) {
    _loadMoments();
  }

  void _loadMoments() {
    if (_activeBabyId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final allMoments = _box.values
          .where((m) => m.babyId == _activeBabyId)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
      state = AsyncValue.data(allMoments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMoment({
    required String title,
    required String description,
    required String tempImagePath,
  }) async {
    if (_activeBabyId == null) return;

    try {
      // 1. Copy image from temp path to persistent app storage
      final appDir = await getApplicationDocumentsDirectory();
      final momentsDir = Directory(path.join(appDir.path, 'moments'));
      if (!await momentsDir.exists()) {
        await momentsDir.create(recursive: true);
      }
      
      final fileName = '${const Uuid().v4()}${path.extension(tempImagePath)}';
      final savedImage = await File(tempImagePath).copy(path.join(momentsDir.path, fileName));
      
      // 2. Create MomentModel
      final moment = MomentModel(
        id: const Uuid().v4(),
        babyId: _activeBabyId!,
        timestamp: DateTime.now(),
        title: title,
        description: description,
        imagePath: savedImage.path,
      );

      // 3. Save to Hive
      await _box.put(moment.id, moment);
      
      // 4. Reload state
      _loadMoments();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMoment(String id) async {
    try {
      final moment = _box.get(id);
      if (moment != null) {
        // Delete the image file
        final file = File(moment.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
        // Delete from DB
        await _box.delete(id);
        _loadMoments();
      }
    } catch (e) {
      // Log or handle error silently
    }
  }
}
