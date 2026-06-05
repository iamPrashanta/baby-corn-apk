import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import '../../features/settings/domain/models/reminder_settings_model.dart';
import '../../features/auth/domain/services/auth_service.dart';
import '../local_storage/hive_manager.dart';
import 'reminder_service.dart';

import '../../features/records/domain/models/record_model.dart';
import '../../features/guide/domain/models/sanskar_model.dart';
import '../../features/development/domain/models/moment_model.dart';
import '../../features/medication/domain/models/medication_model.dart';
import '../../features/medication/domain/models/medication_log_model.dart';
import '../../features/settings/domain/models/family_member_model.dart';
import '../../features/guide/domain/models/food_intro_record.dart';

class UnsupportedBackupVersionException implements Exception {
  final int version;
  UnsupportedBackupVersionException(this.version);
  @override
  String toString() => 'Unsupported backup version: $version. Please update the app to restore this backup.';
}

class BackupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> backupNow() async {
    final user = AuthService.currentUser;
    debugPrint('[BACKUP USER] uid=${user?.uid}');
    debugPrint('[BACKUP USER] email=${user?.email}');
    
    if (user == null) {
      debugPrint('[BACKUP ERROR] User not logged in.');
      throw Exception('User not logged in');
    }

    try {
      debugPrint('[BACKUP STARTED] Starting single-document backup for user: ${user.uid}');
      final latestBackupRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backup')
          .doc('latest');

      // 1. Check Rate Limit (6 hours)
      final existingDoc = await latestBackupRef.get();
      if (existingDoc.exists) {
        final data = existingDoc.data()!;
        final lastBackupTimestamp = data['createdAt'] as Timestamp?;
        if (lastBackupTimestamp != null) {
          final lastBackup = lastBackupTimestamp.toDate();
          final diff = DateTime.now().difference(lastBackup);
          if (diff.inHours < 6) {
             throw Exception('Backup already performed recently. Please wait 6 hours.');
          }
        }
      }

      int totalRecords = 0;

      // 2. Extract Data
      final profileBox = HiveManager.getProfileBox();
      final profileData = profileBox.toMap().cast<String, dynamic>();

      final settingsBox = HiveManager.getSettingsBox();
      final settingsData = settingsBox.toMap().cast<String, dynamic>();
      settingsData.remove('engagement_start_date'); // Do not backup transient states

      final recordsBox = HiveManager.getRecordsBox();
      final records = recordsBox.values.map((e) => e.toJson()).toList();
      totalRecords += records.length;

      final sanskarsBox = HiveManager.getSanskarsBox();
      final sanskars = sanskarsBox.values.map((e) => e.toJson()).toList();
      totalRecords += sanskars.length;

      final momentsBox = HiveManager.getMomentsBox();
      final moments = <Map<String, dynamic>>[];
      for (final m in momentsBox.values) {
        final json = m.toJson();
        final imagePath = m.imagePath;
        if (!imagePath.startsWith('http') && imagePath.isNotEmpty) {
          final file = File(imagePath);
          if (await file.exists()) {
            try {
              debugPrint('[BACKUP STORAGE UPLOAD] Uploading moment photo: ${m.id}.jpg');
              final ref = FirebaseStorage.instance
                  .ref()
                  .child('users/${user.uid}/moments/${m.id}.jpg');
              await ref.putFile(file);
              json['imagePath'] = await ref.getDownloadURL();
            } catch (e) {
              debugPrint('[BACKUP ERROR] Failed to upload moment image: $e');
            }
          }
        }
        moments.add(json);
      }
      totalRecords += moments.length;

      final medicationsBox = HiveManager.getMedicationsBox();
      final medications = medicationsBox.values.map((e) => e.toJson()).toList();
      totalRecords += medications.length;

      final medicationLogsBox = HiveManager.getMedicationLogsBox();
      final medicationLogs = medicationLogsBox.values.map((e) => e.toJson()).toList();
      totalRecords += medicationLogs.length;

      final familyMembersBox = HiveManager.getFamilyMembersBox();
      final familyMembers = familyMembersBox.values.map((e) => e.toJson()).toList();
      totalRecords += familyMembers.length;

      final foodTrackerBox = HiveManager.getFoodTrackerBox();
      final foodTracker = foodTrackerBox.values.map((e) => e.toJson()).toList();
      totalRecords += foodTracker.length;

      // 3. Compile Single Payload
      final Map<String, dynamic> backupPayload = {
        'backupVersion': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0',
        'recordCount': totalRecords,
        'profile': profileData,
        'settings': settingsData,
        'records': records,
        'sanskars': sanskars,
        'moments': moments,
        'medications': medications,
        'medicationLogs': medicationLogs,
        'familyMembers': familyMembers,
        'foodTracker': foodTracker,
      };

      // 4. Write to Firestore (1 Write Operation!)
      debugPrint('[BACKUP FIRESTORE WRITE] Writing to Firestore...');
      await latestBackupRef.set(backupPayload);

      debugPrint('[BACKUP SUCCESS] Single-document upload complete. Total records: $totalRecords');
    } catch (e) {
      debugPrint('[BACKUP ERROR] $e');
      throw Exception('Failed to upload backup: $e');
    }
  }

  static Future<void> restoreBackup() async {
    final user = AuthService.currentUser;
    if (user == null) {
      debugPrint('[RESTORE ERROR] User not logged in.');
      throw Exception('User not logged in');
    }

    try {
      debugPrint('[RESTORE] Starting restore for user: ${user.uid}');
      final latestBackupRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backup')
          .doc('latest');

      // 1. Fetch Single Document (1 Read Operation!)
      final snapshot = await latestBackupRef.get();
      debugPrint('[RESTORE DOWNLOAD COMPLETE] Downloaded from Firestore');
      if (!snapshot.exists) {
        throw Exception('No backup found for this account.');
      }

      final data = snapshot.data()!;
      final backupVersion = data['backupVersion'] as int? ?? 1;
      final supportedVersion = 1;
      
      if (backupVersion > supportedVersion) {
        throw UnsupportedBackupVersionException(backupVersion);
      }
      debugPrint('[RESTORE VALIDATION PASSED] Backup version valid');

      debugPrint('[RESTORE SNAPSHOT CREATED] Creating in-memory rollback snapshots...');
      final profileSnapshot = HiveManager.getProfileBox().toMap();
      final settingsSnapshot = HiveManager.getSettingsBox().toMap();
      final recordsSnapshot = HiveManager.getRecordsBox().toMap();
      final sanskarsSnapshot = HiveManager.getSanskarsBox().toMap();
      final momentsSnapshot = HiveManager.getMomentsBox().toMap();
      final medicationsSnapshot = HiveManager.getMedicationsBox().toMap();
      final medicationLogsSnapshot = HiveManager.getMedicationLogsBox().toMap();
      final familyMembersSnapshot = HiveManager.getFamilyMembersBox().toMap();
      final foodTrackerSnapshot = HiveManager.getFoodTrackerBox().toMap();

      try {
        debugPrint('[RESTORE WIPING HIVE] Wiping local Hive databases...');
        
        // 2. Clear all local boxes
        await HiveManager.getProfileBox().clear();
        await HiveManager.getSettingsBox().clear();
        await HiveManager.getRecordsBox().clear();
        await HiveManager.getSanskarsBox().clear();
        await HiveManager.getMomentsBox().clear();
        await HiveManager.getMedicationsBox().clear();
        await HiveManager.getMedicationLogsBox().clear();
        await HiveManager.getFamilyMembersBox().clear();
        await HiveManager.getFoodTrackerBox().clear();

        debugPrint('[RESTORE] Rebuilding Hive from single payload...');

      // 3. Restore Key-Value Stores
      final profileData = data['profile'] as Map<String, dynamic>? ?? {};
      for (final entry in profileData.entries) {
        await HiveManager.getProfileBox().put(entry.key, entry.value);
      }

      final settingsData = data['settings'] as Map<String, dynamic>? ?? {};
      for (final entry in settingsData.entries) {
        await HiveManager.getSettingsBox().put(entry.key, entry.value);
      }

      // 4. Restore List Stores
      Future<void> restoreList<T>(String key, dynamic box, T Function(Map<String, dynamic>) fromJson) async {
        final list = data[key] as List<dynamic>? ?? [];
        for (final item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          await box.put(map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(), fromJson(map));
        }
      }

      await restoreList('records', HiveManager.getRecordsBox(), RecordModel.fromJson);
      await restoreList('sanskars', HiveManager.getSanskarsBox(), SanskarModel.fromJson);
      await restoreList('moments', HiveManager.getMomentsBox(), MomentModel.fromJson);
      await restoreList('medications', HiveManager.getMedicationsBox(), MedicationModel.fromJson);
      await restoreList('medicationLogs', HiveManager.getMedicationLogsBox(), MedicationLogModel.fromJson);
      await restoreList('familyMembers', HiveManager.getFamilyMembersBox(), FamilyMemberModel.fromJson);
      await restoreList('foodTracker', HiveManager.getFoodTrackerBox(), FoodIntroRecord.fromJson);

      debugPrint('[RESTORE REBUILDING REMINDERS] Reminders recreating...');
      
      // 5. Let ReminderService handle updating schedules based on restored settings
      await ReminderService.init();
      final settingsJsonStr = HiveManager.getSettingsBox().get('reminder_settings_json') as String?;
      if (settingsJsonStr != null) {
        final settings = ReminderSettingsModel.fromJson(jsonDecode(settingsJsonStr));
        await ReminderService.updateSchedules(settings);
      }

      debugPrint('[RESTORE SUCCESS] Backup restored successfully.');
      } catch (restoreError) {
        debugPrint('[RESTORE FAILED] Restore failed. Reverting to Hive snapshots... Error: $restoreError');
        try {
          await HiveManager.getProfileBox().clear();
          await HiveManager.getProfileBox().putAll(profileSnapshot);
          await HiveManager.getSettingsBox().clear();
          await HiveManager.getSettingsBox().putAll(settingsSnapshot);
          await HiveManager.getRecordsBox().clear();
          await HiveManager.getRecordsBox().putAll(recordsSnapshot);
          await HiveManager.getSanskarsBox().clear();
          await HiveManager.getSanskarsBox().putAll(sanskarsSnapshot);
          await HiveManager.getMomentsBox().clear();
          await HiveManager.getMomentsBox().putAll(momentsSnapshot);
          await HiveManager.getMedicationsBox().clear();
          await HiveManager.getMedicationsBox().putAll(medicationsSnapshot);
          await HiveManager.getMedicationLogsBox().clear();
          await HiveManager.getMedicationLogsBox().putAll(medicationLogsSnapshot);
          await HiveManager.getFamilyMembersBox().clear();
          await HiveManager.getFamilyMembersBox().putAll(familyMembersSnapshot);
          await HiveManager.getFoodTrackerBox().clear();
          await HiveManager.getFoodTrackerBox().putAll(foodTrackerSnapshot);
          debugPrint('[ROLLBACK EXECUTED] Hive successfully restored to previous state.');
        } catch (rollbackError) {
          debugPrint('[CRITICAL] Rollback failed: $rollbackError');
        }
        throw Exception('Failed to restore backup data: $restoreError');
      }
    } catch (e) {
      debugPrint('[RESTORE ERROR] $e');
      throw Exception('Failed to restore backup: $e');
    }
  }

  static Future<bool> backupExists() async {
    final user = AuthService.currentUser;
    if (user == null) return false;

    try {
      final latestBackupRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backup')
          .doc('latest');
      final snapshot = await latestBackupRef.get();
      return snapshot.exists;
    } catch (e) {
      debugPrint('[BACKUP ERROR] Checking existence failed: $e');
      return false;
    }
  }

  static Future<DateTime?> getLastBackupDate() async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    try {
      final latestBackupRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backup')
          .doc('latest');
      final snapshot = await latestBackupRef.get();
      
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final timestamp = data['createdAt'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      debugPrint('[BACKUP ERROR] Fetching last backup date failed: $e');
      return null;
    }
  }

  static Future<void> deleteBackup() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      final latestBackupRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backup')
          .doc('latest');
      await latestBackupRef.delete();
      
      debugPrint('[BACKUP] Single-document backup deleted successfully.');
    } catch (e) {
      debugPrint('[BACKUP ERROR] Deleting backup failed: $e');
    }
  }
  static Future<void> mergeBackup() async {
    final user = AuthService.currentUser;
    if (user == null) {
      debugPrint('[MERGE ERROR] User not logged in.');
      throw Exception('User not logged in');
    }

    try {
      debugPrint('[MERGE] Starting merge for user: ${user.uid}');
      final latestBackupRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backup')
          .doc('latest');

      final snapshot = await latestBackupRef.get();
      if (!snapshot.exists) {
        throw Exception('No backup found for this account.');
      }

      final data = snapshot.data()!;
      final backupVersion = data['backupVersion'] as int? ?? 1;
      final supportedVersion = 1;
      
      if (backupVersion > supportedVersion) {
        throw UnsupportedBackupVersionException(backupVersion);
      }

      debugPrint('[MERGE] Merging Hive databases...');

      // Profile & Settings
      final profileData = data['profile'] as Map<String, dynamic>? ?? {};
      for (final entry in profileData.entries) {
        if (!HiveManager.getProfileBox().containsKey(entry.key)) {
          await HiveManager.getProfileBox().put(entry.key, entry.value);
        }
      }

      final settingsData = data['settings'] as Map<String, dynamic>? ?? {};
      for (final entry in settingsData.entries) {
        if (!HiveManager.getSettingsBox().containsKey(entry.key)) {
          await HiveManager.getSettingsBox().put(entry.key, entry.value);
        }
      }

      Future<void> mergeList<T>(String key, dynamic box, T Function(Map<String, dynamic>) fromJson) async {
        final list = data[key] as List<dynamic>? ?? [];
        for (final item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          final itemId = map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
          if (!box.containsKey(itemId)) {
            await box.put(itemId, fromJson(map));
          }
        }
      }

      await mergeList('records', HiveManager.getRecordsBox(), RecordModel.fromJson);
      await mergeList('sanskars', HiveManager.getSanskarsBox(), SanskarModel.fromJson);
      await mergeList('moments', HiveManager.getMomentsBox(), MomentModel.fromJson);
      await mergeList('medications', HiveManager.getMedicationsBox(), MedicationModel.fromJson);
      await mergeList('medicationLogs', HiveManager.getMedicationLogsBox(), MedicationLogModel.fromJson);
      await mergeList('familyMembers', HiveManager.getFamilyMembersBox(), FamilyMemberModel.fromJson);
      await mergeList('foodTracker', HiveManager.getFoodTrackerBox(), FoodIntroRecord.fromJson);

      debugPrint('[MERGE REBUILDING REMINDERS] Reminders recreating...');
      await ReminderService.init();
      final settingsJsonStr = HiveManager.getSettingsBox().get('reminder_settings_json') as String?;
      if (settingsJsonStr != null) {
        final settings = ReminderSettingsModel.fromJson(jsonDecode(settingsJsonStr));
        await ReminderService.updateSchedules(settings);
      }

      debugPrint('[MERGE SUCCESS] Backup merged successfully.');
    } catch (e) {
      debugPrint('[MERGE FAILED] Merge failed. Error: $e');
      throw Exception('Failed to merge backup: $e');
    }
  }
}
