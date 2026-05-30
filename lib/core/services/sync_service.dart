import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../local_storage/hive_manager.dart';
import '../../features/records/domain/models/record_model.dart';
import '../../features/auth/domain/models/baby_model.dart';

class SyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Syncs all local offline data to Firestore when a user signs in.
  static Future<void> syncOfflineDataToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final recordsBox = HiveManager.getRecordsBox();
      final settingsBox = HiveManager.getSettingsBox();
      final babiesJson = settingsBox.get('babies_list');
      List<BabyModel> babies = [];
      if (babiesJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(babiesJson);
          babies = decoded.map((e) => BabyModel.fromJson(e)).toList();
        } catch (_) {}
      }

      final batch = _db.batch();

      // Sync Babies
      for (final baby in babies) {
        final docRef = _db.collection('users').doc(user.uid).collection('babies').doc(baby.id);
        batch.set(docRef, {
          'id': baby.id,
          'name': baby.name,
          'gender': baby.gender,
          'feedingType': baby.feedingType,
          'birthDate': baby.birthDate.toIso8601String(),
          'birthWeight': baby.birthWeight,
          'birthHeight': baby.birthHeight,
          'avatarEmoji': baby.avatarEmoji,
        }, SetOptions(merge: true));
      }

      // Sync Records
      for (final record in recordsBox.values) {
        final docRef = _db.collection('users').doc(user.uid).collection('records').doc(record.id);
        batch.set(docRef, {
          'id': record.id,
          'type': record.type,
          'timestamp': record.timestamp.toIso8601String(),
          'metadata': record.metadata,
        }, SetOptions(merge: true));
      }

      await batch.commit();
      settingsBox.put('last_sync_time', DateTime.now().toIso8601String());
      debugPrint('Sync: Offline data successfully merged to Cloud');
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  /// Downloads cloud data and merges it into local storage.
  static Future<void> syncCloudDataToLocal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Sync Babies
      final babiesSnapshot = await _db.collection('users').doc(user.uid).collection('babies').get();
      final settingsBox = HiveManager.getSettingsBox();
      final babiesJson = settingsBox.get('babies_list');
      List<BabyModel> localBabies = [];
      if (babiesJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(babiesJson);
          localBabies = decoded.map((e) => BabyModel.fromJson(e)).toList();
        } catch (_) {}
      }
      
      bool babiesChanged = false;
      for (final doc in babiesSnapshot.docs) {
        final data = doc.data();
        if (!localBabies.any((b) => b.id == data['id'])) {
          final baby = BabyModel(
            id: data['id'],
            name: data['name'],
            gender: data['gender'] ?? 'Prefer not to say',
            feedingType: data['feedingType'] ?? 'Mixed',
            birthDate: DateTime.parse(data['birthDate']),
            birthWeight: (data['birthWeight'] as num?)?.toDouble() ?? 3.2,
            birthHeight: (data['birthHeight'] as num?)?.toDouble(),
            avatarEmoji: data['avatarEmoji'] ?? '👶',
          );
          localBabies.add(baby);
          babiesChanged = true;
        }
      }

      if (babiesChanged) {
        final encoded = jsonEncode(localBabies.map((b) => b.toJson()).toList());
        await settingsBox.put('babies_list', encoded);
      }

      // Sync Records
      final recordsSnapshot = await _db.collection('users').doc(user.uid).collection('records').get();
      final recordsBox = HiveManager.getRecordsBox();
      
      for (final doc in recordsSnapshot.docs) {
        final data = doc.data();
        if (!recordsBox.containsKey(data['id'])) {
          final record = RecordModel(
            id: data['id'],
            type: data['type'],
            timestamp: DateTime.parse(data['timestamp']),
            metadata: data['metadata'] ?? {},
          );
          await recordsBox.put(record.id, record);
        }
      }

      settingsBox.put('last_sync_time', DateTime.now().toIso8601String());
      debugPrint('Sync: Cloud data successfully merged to Local');
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  /// Push a single record to Firestore (used when a new record is created)
  static Future<void> pushRecord(RecordModel record) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db.collection('users').doc(user.uid).collection('records').doc(record.id).set({
        'id': record.id,
        'type': record.type,
        'timestamp': record.timestamp.toIso8601String(),
        'metadata': record.metadata,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sync Error pushing record: $e');
    }
  }
}
