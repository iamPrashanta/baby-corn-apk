// features/records/presentation/providers/records_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/record_model.dart';
import '../../data/repositories/local_record_repository.dart';
import '../../../auth/presentation/providers/baby_provider.dart';

final recordsProvider = StateNotifierProvider<RecordsNotifier, AsyncValue<List<RecordModel>>>((ref) {
  final repository = ref.watch(localRecordRepositoryProvider);
  final activeBaby = ref.watch(activeBabyProvider);
  
  return RecordsNotifier(repository, activeBaby?.id);
});

class RecordsNotifier extends StateNotifier<AsyncValue<List<RecordModel>>> {
  final LocalRecordRepository _repository;
  final String? _activeBabyId;
  DateTime? _startDate;

  RecordsNotifier(this._repository, this._activeBabyId) : super(const AsyncValue.loading()) {
    // Default to last 10 days
    _startDate = DateTime.now().subtract(const Duration(days: 10));
    loadRecords();
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    loadRecords();
  }

  void loadRecords() {
    try {
      final records = _repository.getAllRecords();
      
      // Filter records by active baby ID
      // If a record has no babyId (from older versions), it belongs to the first/default baby.
      final filtered = records.where((r) {
        // Apply date filter
        if (_startDate != null && r.timestamp.isBefore(_startDate!)) {
          return false;
        }

        final rBabyId = r.metadata['babyId'] as String?;
        if (rBabyId == _activeBabyId) return true;
        
        // Backward compatibility: if record has no babyId, assume it belongs to the currently active baby
        if (rBabyId == null) return true;
        
        return false;
      }).toList();
      
      // Sort in descending order (newest first)
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      state = AsyncValue.data(filtered);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecord(RecordModel record) async {
    try {
      // Ensure the record has the active baby ID before saving
      if (_activeBabyId != null && !record.metadata.containsKey('babyId')) {
        record.metadata['babyId'] = _activeBabyId;
      }
      
      await _repository.saveRecord(record);
      loadRecords(); // Refresh the list
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _repository.deleteRecord(id);
      loadRecords(); // Refresh the list
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
