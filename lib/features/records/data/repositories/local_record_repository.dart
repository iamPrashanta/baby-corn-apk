// features/records/data/repositories/local_record_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/record_model.dart';
import '../../../../core/local_storage/hive_manager.dart';

final localRecordRepositoryProvider = Provider<LocalRecordRepository>((ref) {
  return LocalRecordRepository();
});

class LocalRecordRepository {
  Future<void> saveRecord(RecordModel record) async {
    final box = HiveManager.getRecordsBox();
    await box.put(record.id, record);
  }

  Future<void> updateRecord(RecordModel record) async {
    final box = HiveManager.getRecordsBox();
    await box.put(record.id, record);
  }

  Future<void> deleteRecord(String id) async {
    final box = HiveManager.getRecordsBox();
    await box.delete(id);
  }

  List<RecordModel> getAllRecords() {
    final box = HiveManager.getRecordsBox();
    final records = box.values.toList();
    // Sort newest first
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }
}
