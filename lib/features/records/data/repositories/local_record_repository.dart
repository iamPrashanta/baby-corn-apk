// features/records/data/repositories/local_record_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/record_model.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/config/app_config.dart';

final localRecordRepositoryProvider = Provider<LocalRecordRepository>((ref) {
  return LocalRecordRepository();
});

class LocalRecordRepository {
  Future<void> saveRecord(RecordModel record) async {
    final box = HiveManager.getRecordsBox();
    await box.put(record.id, record);
    if (AppConfig.enableCloudSync) SyncService.pushRecord(record);
  }

  Future<void> updateRecord(RecordModel record) async {
    final box = HiveManager.getRecordsBox();
    await box.put(record.id, record);
    if (AppConfig.enableCloudSync) SyncService.pushRecord(record);
  }

  Future<void> deleteRecord(String id) async {
    final box = HiveManager.getRecordsBox();
    await box.delete(id);
    // Note: Cloud delete not fully implemented in SyncService yet,
    // but local delete works.
  }

  List<RecordModel> getAllRecords() {
    final box = HiveManager.getRecordsBox();
    final records = box.values.toList();
    // Sort newest first
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }
}
