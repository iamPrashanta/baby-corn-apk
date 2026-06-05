import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class BackupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> backupNow() async {
    final user = AuthService.currentUser;
    if (user == null) {
      debugPrint('[BACKUP ERROR] User not logged in.');
      throw Exception('User not logged in');
    }

    try {
      debugPrint('[BACKUP] Starting single-document backup for user: ${user.uid}');
      final latestBackupRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backup')
          .doc('latest');

      // 1. Check Rate Limit (12 hours)
      final existingDoc = await latestBackupRef.get();
      if (existingDoc.exists) {
        final data = existingDoc.data()!;
        final lastBackupTimestamp = data['createdAt'] as Timestamp?;
        if (lastBackupTimestamp != null) {
          final lastBackup = lastBackupTimestamp.toDate();
          final diff = DateTime.now().difference(lastBackup);
          if (diff.inHours < 12) {
             throw Exception('Backup already performed recently. Please wait 12 hours.');
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
      final moments = momentsBox.values.map((e) => e.toJson()).toList();
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
      await latestBackupRef.set(backupPayload);

      debugPrint('[BACKUP] Single-document upload complete. Total records: $totalRecords');
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
      if (!snapshot.exists) {
        throw Exception('No backup found for this account.');
      }

      final data = snapshot.data()!;

      debugPrint('[RESTORE] Wiping local Hive databases...');
      
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

      debugPrint('[RESTORE] Reminder schedules recreating...');
      
      // 5. Let ReminderService handle updating schedules based on restored settings
      await ReminderService.init();

      debugPrint('[RESTORE] Backup restored successfully.');
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
}
