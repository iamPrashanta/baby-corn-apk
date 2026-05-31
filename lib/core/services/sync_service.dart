// lib/core/services/sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import '../local_storage/hive_manager.dart';
import '../../features/records/domain/models/record_model.dart';
import '../../features/auth/domain/models/baby_model.dart';
import '../../features/guide/domain/models/sanskar_model.dart';
import '../../features/development/domain/models/moment_model.dart';

class SyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Syncs all local offline data to Firestore when a user signs in.
  static Future<void> syncOfflineDataToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final recordsBox = HiveManager.getRecordsBox();
      final sanskarsBox = HiveManager.getSanskarsBox();
      final momentsBox = HiveManager.getMomentsBox();
      final profileBox = HiveManager.getProfileBox();
      final settingsBox = HiveManager.getSettingsBox();
      final babiesJson = profileBox.get('babies_list');
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
        final docRef = _db
            .collection('users')
            .doc(user.uid)
            .collection('babies')
            .doc(baby.id);
        batch.set(
            docRef,
            {
              'id': baby.id,
              'name': baby.name,
              'gender': baby.gender,
              'feedingType': baby.feedingType,
              'birthDate': baby.birthDate.toIso8601String(),
              'birthWeight': baby.birthWeight,
              'birthHeight': baby.birthHeight,
              'avatarEmoji': baby.avatarEmoji,
            },
            SetOptions(merge: true));
      }

      // Sync Sanskars
      for (final sanskar in sanskarsBox.values) {
        final docRef = _db
            .collection('users')
            .doc(user.uid)
            .collection('sanskars')
            .doc(sanskar.id);
        batch.set(
            docRef,
            {
              'id': sanskar.id,
              'name': sanskar.name,
              'sanskritName': sanskar.sanskritName,
              'description': sanskar.description,
              'category': sanskar.category,
              'emojiIcon': sanskar.emojiIcon,
              'defaultRule': sanskar.defaultRule.toJson(),
              'customDate': sanskar.customDate?.toIso8601String(),
              'isCompleted': sanskar.isCompleted,
              'notes': sanskar.notes,
              'reminderEnabled': sanskar.reminderEnabled,
            },
            SetOptions(merge: true));
      }

      // Sync Records
      for (final record in recordsBox.values) {
        final docRef = _db
            .collection('users')
            .doc(user.uid)
            .collection('records')
            .doc(record.id);
        batch.set(
            docRef,
            {
              'id': record.id,
              'type': record.type,
              'timestamp': record.timestamp.toIso8601String(),
              'metadata': record.metadata,
            },
            SetOptions(merge: true));
      }

      // Sync Moments (Photos)
      final cloudMomentsSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('moments')
          .get();
      final cloudMomentIds = cloudMomentsSnapshot.docs.map((d) => d.id).toSet();

      for (final moment in momentsBox.values) {
        String? downloadUrl;
        if (!cloudMomentIds.contains(moment.id)) {
          // Upload image if not already in cloud
          if (!moment.imagePath.startsWith('http')) {
            final file = File(moment.imagePath);
            if (await file.exists()) {
              try {
                final ref = FirebaseStorage.instance
                    .ref()
                    .child('users/${user.uid}/moments/${moment.id}.jpg');
                await ref.putFile(file);
                downloadUrl = await ref.getDownloadURL();
                debugPrint('✅ [Storage Audit] Upload successful for ${moment.id}');
              } on FirebaseException catch (e) {
                debugPrint('❌ [Storage Audit] Upload failed for ${moment.id} - Code: ${e.code}, Message: ${e.message}');
              } catch (e) {
                debugPrint('❌ [Storage Audit] Generic error for ${moment.id}: $e');
              }
            }
          } else {
            downloadUrl = moment.imagePath;
          }
        } else {
          // Keep the existing cloud URL
          final cloudDoc =
              cloudMomentsSnapshot.docs.firstWhere((d) => d.id == moment.id);
          downloadUrl = cloudDoc.data()['cloudImageUrl'];
        }

        if (downloadUrl != null) {
          final docRef = _db
              .collection('users')
              .doc(user.uid)
              .collection('moments')
              .doc(moment.id);
          batch.set(
              docRef,
              {
                'id': moment.id,
                'babyId': moment.babyId,
                'timestamp': moment.timestamp.toIso8601String(),
                'title': moment.title,
                'description': moment.description,
                'cloudImageUrl': downloadUrl,
              },
              SetOptions(merge: true));
        }
      }

      debugPrint('===== CLOUD SYNC AUDIT (OFFLINE TO CLOUD) =====');
      debugPrint('Google UID: ${user.uid}');
      debugPrint('Attempting to commit batch write to Firestore...');
      await batch.commit().timeout(const Duration(seconds: 15));
      debugPrint('✅ Firestore batch commit successful!');
      
      settingsBox.put('last_sync_time', DateTime.now().toIso8601String());
      debugPrint('Sync: Offline data successfully merged to Cloud');
      debugPrint('=============================================');
    } on FirebaseException catch (e) {
      debugPrint('❌ [Firestore Audit] FirebaseException during Sync:');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      if (e.code == 'permission-denied') {
        debugPrint('⚠️ POSSIBLE FIREBASE RULES FAILURE OR APP CHECK FAILURE!');
      }
      debugPrint('=============================================');
      rethrow;
    } catch (e) {
      debugPrint('❌ [Firestore Audit] Generic Sync Error: $e');
      debugPrint('=============================================');
      rethrow;
    }
  }

  /// Downloads cloud data and merges it into local storage.
  static Future<void> syncCloudDataToLocal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Sync Babies
      final babiesSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('babies')
          .get()
          .timeout(const Duration(seconds: 15));
      final settingsBox = HiveManager.getSettingsBox();
      final profileBox = HiveManager.getProfileBox();
      final babiesJson = profileBox.get('babies_list');
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
        await profileBox.put('babies_list', encoded);
      }

      if (localBabies.isNotEmpty) {
        await profileBox.put('onboarding_complete', true);
        if (profileBox.get('active_baby_id') == null) {
          await profileBox.put('active_baby_id', localBabies.first.id);
        }
      }

      // Sync Records
      final recordsSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('records')
          .get()
          .timeout(const Duration(seconds: 15));
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

      // Sync Sanskars
      final sanskarsSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('sanskars')
          .get()
          .timeout(const Duration(seconds: 15));
      final sanskarsBox = HiveManager.getSanskarsBox();

      for (final doc in sanskarsSnapshot.docs) {
        final data = doc.data();
        if (sanskarsBox.containsKey(data['id'])) {
          final localSanskar = sanskarsBox.get(data['id']);
          if (localSanskar != null) {
            localSanskar.isCompleted =
                data['isCompleted'] ?? localSanskar.isCompleted;
            localSanskar.customDate = data['customDate'] != null
                ? DateTime.parse(data['customDate'])
                : localSanskar.customDate;
            localSanskar.notes = data['notes'] ?? localSanskar.notes;
            localSanskar.reminderEnabled =
                data['reminderEnabled'] ?? localSanskar.reminderEnabled;
            await localSanskar.save();
          }
        } else {
          final sanskar = SanskarModel(
            id: data['id'],
            name: data['name'],
            sanskritName: data['sanskritName'],
            description: data['description'],
            category: data['category'],
            emojiIcon: data['emojiIcon'],
            defaultRule: SanskarRule.fromJson(data['defaultRule']),
            customDate: data['customDate'] != null
                ? DateTime.parse(data['customDate'])
                : null,
            isCompleted: data['isCompleted'] ?? false,
            notes: data['notes'] ?? '',
            reminderEnabled: data['reminderEnabled'] ?? true,
          );
          await sanskarsBox.put(sanskar.id, sanskar);
        }
      }

      // Sync Moments
      final momentsSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('moments')
          .get()
          .timeout(const Duration(seconds: 15));
      final momentsBox = HiveManager.getMomentsBox();

      for (final doc in momentsSnapshot.docs) {
        final data = doc.data();
        if (!momentsBox.containsKey(data['id'])) {
          final cloudUrl = data['cloudImageUrl'];
          if (cloudUrl != null) {
            final moment = MomentModel(
              id: data['id'],
              babyId: data['babyId'],
              timestamp: DateTime.parse(data['timestamp']),
              title: data['title'],
              description: data['description'] ?? '',
              imagePath: cloudUrl,
            );
            await momentsBox.put(moment.id, moment);
          }
        } else {
          final localMoment = momentsBox.get(data['id']);
          if (localMoment != null && data['title'] != null) {
            // Update text fields only
            final updated = localMoment.copyWith(
              title: data['title'],
              description: data['description'] ?? localMoment.description,
            );
            await momentsBox.put(localMoment.id, updated);
          }
        }
      }

      settingsBox.put('last_sync_time', DateTime.now().toIso8601String());
      debugPrint('Sync: Cloud data successfully merged to Local');
    } on FirebaseException catch (e) {
      debugPrint('❌ [Firestore Audit] FirebaseException during Sync (Cloud to Local):');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      if (e.code == 'permission-denied') {
        debugPrint('⚠️ POSSIBLE FIREBASE RULES FAILURE OR APP CHECK FAILURE!');
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ [Firestore Audit] Generic Sync Error (Cloud to Local): $e');
      rethrow;
    }
  }

  /// Push a single record to Firestore (used when a new record is created)
  static Future<void> pushRecord(RecordModel record) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('records')
          .doc(record.id)
          .set({
        'id': record.id,
        'type': record.type,
        'timestamp': record.timestamp.toIso8601String(),
        'metadata': record.metadata,
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Sync Error pushing record: $e');
    }
  }
}
