// core/services/sync_engine.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../features/records/domain/models/record_model.dart';
import '../../features/records/data/repositories/firestore_record_repository.dart';
import '../local_storage/hive_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/app_config.dart';

class SyncEngine {
  final FirestoreRecordRepository _firestoreRepo;
  Timer? _syncTimer;
  // ignore: cancel_subscriptions
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  
  // Exponential backoff state
  int _retryAttempt = 0;
  final int _maxRetries = 5;

  SyncEngine(this._firestoreRepo);

  void start() {
    if (!AppConfig.enableCloudSync) return;
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result.isNotEmpty && !result.contains(ConnectivityResult.none)) {
        // Reset backoff on network reconnect
        _retryAttempt = 0;
        syncPendingRecords();
      }
    });
    
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncPendingRecords();
    });
    
    syncPendingRecords();
  }

  void stop() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  Future<void> syncPendingRecords() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.isEmpty || connectivity.contains(ConnectivityResult.none)) {
        _isSyncing = false;
        return;
      }

      final box = HiveManager.getRecordsBox();
      // Deduplicate and batch limit (max 50 records per sync)
      final allPending = box.values.where((r) => !r.isSynced).toList();
      if (allPending.isEmpty) {
        _retryAttempt = 0; // Success/Nothing to do, reset backoff
        _isSyncing = false;
        return;
      }

      // Unique records only (queue deduplication based on ID)
      final Map<String, RecordModel> uniquePending = {};
      for (var r in allPending) {
        uniquePending[r.id] = r;
      }

      final pendingRecords = uniquePending.values.take(50).toList();
      debugPrint('Syncing ${pendingRecords.length} records to Firestore (Attempt $_retryAttempt)...');
      
      for (var record in pendingRecords) {
        await _firestoreRepo.saveRecord(record);
        
        final updatedRecord = record.copyWith(isSynced: true);
        await box.put(record.id, updatedRecord);
      }
      
      debugPrint('Sync completed successfully.');
      _retryAttempt = 0; // Reset backoff on success
      
      // If there are more pending, trigger next batch immediately
      if (uniquePending.length > 50) {
        _isSyncing = false;
        syncPendingRecords();
        return;
      }
      
    } catch (e) {
      debugPrint('Sync failed: $e');
      _retryAttempt++;
      if (_retryAttempt <= _maxRetries) {
        final backoffDelay = pow(2, _retryAttempt).toInt() * 1000; // Exponential backoff
        debugPrint('Retrying in ${backoffDelay}ms...');
        Future.delayed(Duration(milliseconds: backoffDelay), () {
          _isSyncing = false;
          syncPendingRecords();
        });
        return;
      }
    } finally {
      _isSyncing = false;
    }
  }
}
