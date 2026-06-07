import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  static Future<void> checkAutoBackup() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      debugPrint('[AUTO BACKUP CHECK] Checking last backup date...');
      final lastBackup = await getLastBackupDate();
      
      if (lastBackup == null) {
        debugPrint('[AUTO BACKUP STARTED] No previous backup found. Starting backup...');
        await backupNow();
        return;
      }

      final diff = DateTime.now().difference(lastBackup);
      if (diff.inHours > 24) {
        debugPrint('[AUTO BACKUP STARTED] Last backup was > 24 hours ago. Starting backup...');
        await backupNow();
      } else {
        debugPrint('[AUTO BACKUP SKIPPED] Last backup is recent (${diff.inHours} hours ago).');
      }
    } catch (e) {
      debugPrint('[AUTO BACKUP ERROR] $e');
    }
  }

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

      int totalRecords = 0;

      // 2. Extract Data
      final profileBox = HiveManager.getProfileBox();
      final profileData = profileBox.toMap().cast<String, dynamic>();

      final settingsBox = HiveManager.getSettingsBox();
      final settingsData = settingsBox.toMap().cast<String, dynamic>();
      settingsData.remove('engagement_start_date'); // Do not backup transient states
      settingsData.remove('is_premium');

      final recordsBox = HiveManager.getRecordsBox();
      final records = recordsBox.values.map((e) => e.toJson()).toList();
      totalRecords += records.length;
      
      final vaccineCount = recordsBox.values.where((e) => e.type == 'vaccine').length;
      if (vaccineCount > 0) {
        debugPrint('[VACCINATION BACKUP] Including $vaccineCount vaccines in backup payload');
      }

      final sanskarsBox = HiveManager.getSanskarsBox();
      final sanskars = sanskarsBox.values.map((e) => e.toJson()).toList();
      totalRecords += sanskars.length;

      final momentsBox = HiveManager.getMomentsBox();
      final moments = <Map<String, dynamic>>[];
      for (final m in momentsBox.values) {
        final json = m.toJson();
        json['photoBackedUp'] = false;
        moments.add(json);
      }
      totalRecords += moments.length;

      final medicationsBox = HiveManager.getMedicationsBox();
      final medications = medicationsBox.values.map((e) => e.toJson()).toList();
      totalRecords += medications.length;
      if (medications.isNotEmpty) {
        debugPrint('[MEDICATION BACKUP] Including ${medications.length} medications in backup payload');
      }

      final familyMembersBox = HiveManager.getFamilyMembersBox();
      final familyMembers = familyMembersBox.values.map((e) => e.toJson()).toList();
      totalRecords += familyMembers.length;

      final foodTrackerBox = HiveManager.getFoodTrackerBox();
      final foodTracker = foodTrackerBox.values.map((e) => e.toJson()).toList();
      totalRecords += foodTracker.length;

      // Parse babies list from profile
      List<dynamic> babiesList = [];
      if (profileData.containsKey('babies_list')) {
        final babiesStr = profileData['babies_list'];
        if (babiesStr is String) {
          babiesList = jsonDecode(babiesStr);
        }
      }

      // 3. Compile Single Payload (Flattened v2)
      final Map<String, dynamic> backupPayload = {
        'v': 2,
        'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'app': '1.0.0',
        'babies': _compressJson(babiesList),
        'settings': _compressJson(settingsData),
        'records': _compressJson(records),
        'meds': _compressJson(medications),
        'moments': _compressJson(moments),
        'sanskars': _compressJson(sanskars),
        'family': _compressJson(familyMembers),
        'foodTracker': _compressJson(foodTracker),
        'meta': {
          'recordCount': totalRecords,
          'device': Platform.operatingSystem,
        }
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
      final version = data['v'] as int? ?? data['backupVersion'] as int? ?? 1;
      final supportedVersion = 2;
      
      if (version > supportedVersion) {
        throw UnsupportedBackupVersionException(version);
      }
      debugPrint('[RESTORE VALIDATION PASSED] Backup version valid ($version)');

      debugPrint('[RESTORE SNAPSHOT CREATED] Creating in-memory rollback snapshots...');
      final profileSnapshot = HiveManager.getProfileBox().toMap();
      final settingsSnapshot = HiveManager.getSettingsBox().toMap();
      final recordsSnapshot = HiveManager.getRecordsBox().toMap();
      final sanskarsSnapshot = HiveManager.getSanskarsBox().toMap();
      final momentsSnapshot = HiveManager.getMomentsBox().toMap();
      final medicationsSnapshot = HiveManager.getMedicationsBox().toMap();
      final familyMembersSnapshot = HiveManager.getFamilyMembersBox().toMap();
      final foodTrackerSnapshot = HiveManager.getFoodTrackerBox().toMap();

      try {
        debugPrint('[RESTORE WIPING HIVE] Wiping local Hive databases...');
        
        // Preserve locally logged vaccines to prevent them from being wiped by the restore
        final localRecords = HiveManager.getRecordsBox().values.toList();
        final localVaccines = localRecords.where((r) => r.type == 'vaccine').toList();

        // 2. Clear all local boxes
        await HiveManager.getProfileBox().clear();
        await HiveManager.getSettingsBox().clear();
        await HiveManager.getRecordsBox().clear();
        await HiveManager.getSanskarsBox().clear();
        await HiveManager.getMomentsBox().clear();
        await HiveManager.getMedicationsBox().clear();
        await HiveManager.getFamilyMembersBox().clear();
        await HiveManager.getFoodTrackerBox().clear();

        debugPrint('[RESTORE] Rebuilding Hive from single payload...');

      // 3. Restore Key-Value Stores
      if (version >= 2 && data.containsKey('babies')) {
        final babiesList = _decompressJson(data['babies']) as List<dynamic>? ?? [];
        await HiveManager.getProfileBox().put('babies_list', jsonEncode(babiesList));
      } else {
        final profileDataRaw = data['profile'] as Map<String, dynamic>? ?? {};
        final profileData = _decompressJson(profileDataRaw) as Map<String, dynamic>;
        for (final entry in profileData.entries) {
          await HiveManager.getProfileBox().put(entry.key, entry.value);
        }
      }

      final settingsDataRaw = data['settings'] as Map<String, dynamic>? ?? {};
      final settingsData = _decompressJson(settingsDataRaw) as Map<String, dynamic>;
      settingsData.remove('is_premium');
      for (final entry in settingsData.entries) {
        await HiveManager.getSettingsBox().put(entry.key, entry.value);
      }

      // 4. Restore List Stores
      Future<void> restoreList<T>(String key, String v2Key, dynamic box, T Function(Map<String, dynamic>) fromJson) async {
        final rawList = data.containsKey(v2Key) ? data[v2Key] : data[key];
        final list = (rawList != null) ? _decompressJson(rawList) as List<dynamic> : [];
        for (final item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          await box.put(map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(), fromJson(map));
        }
      }

      await restoreList('records', 'records', HiveManager.getRecordsBox(), RecordModel.fromJson);
      await restoreList('sanskars', 'sanskars', HiveManager.getSanskarsBox(), SanskarModel.fromJson);
      await restoreList('moments', 'moments', HiveManager.getMomentsBox(), MomentModel.fromJson);
      await restoreList('medications', 'meds', HiveManager.getMedicationsBox(), MedicationModel.fromJson);
      await restoreList('familyMembers', 'family', HiveManager.getFamilyMembersBox(), FamilyMemberModel.fromJson);
      await restoreList('foodTracker', 'foodTracker', HiveManager.getFoodTrackerBox(), FoodIntroRecord.fromJson);
      
      // Re-insert preserved vaccines if they are not already present
      final recordsBox = HiveManager.getRecordsBox();
      for (final v in localVaccines) {
         final vaccineName = v.metadata['vaccineName'];
         final babyId = v.metadata['babyId'];
         final isCustom = v.metadata['isCustom'] == true;
         final dueDate = v.metadata['dueDate'];
         
         final existsInCloud = recordsBox.values.any((r) {
           if (r.type != 'vaccine') return false;
           final sameName = r.metadata['vaccineName'] == vaccineName;
           final sameBaby = r.metadata['babyId'] == babyId;
           
           if (isCustom) {
             final sameDate = r.metadata['dueDate'] == dueDate;
             return sameName && sameBaby && sameDate;
           }
           return sameName && sameBaby;
         });
         if (!existsInCloud) {
           await recordsBox.put(v.id, v);
           debugPrint('[VACCINE PRESERVED] Kept local completed vaccine: $vaccineName');
         }
      }
      final totalVaccines = recordsBox.values.where((r) => r.type == 'vaccine').length;
      debugPrint('[VACCINATION RESTORE] Total vaccines after restore/merge: $totalVaccines');

      final medicationsBox = HiveManager.getMedicationsBox();
      final totalMedications = medicationsBox.values.length;
      debugPrint('[MEDICATION RESTORE] Total medications after restore/merge: $totalMedications');

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
      final version = data['v'] as int? ?? data['backupVersion'] as int? ?? 1;
      final supportedVersion = 2;
      
      if (version > supportedVersion) {
        throw UnsupportedBackupVersionException(version);
      }

      debugPrint('[MERGE] Merging Hive databases (version $version)...');

      // Profile & Settings
      if (version >= 2 && data.containsKey('babies')) {
        final babiesList = _decompressJson(data['babies']) as List<dynamic>? ?? [];
        // Only merge if not exists
        final existingBabiesStr = HiveManager.getProfileBox().get('babies_list') as String?;
        if (existingBabiesStr == null) {
           await HiveManager.getProfileBox().put('babies_list', jsonEncode(babiesList));
        } else {
           // We could merge babies here, but for simplicity we'll just keep local babies if they exist.
        }
      } else {
        final profileDataRaw = data['profile'] as Map<String, dynamic>? ?? {};
        final profileData = _decompressJson(profileDataRaw) as Map<String, dynamic>;
        for (final entry in profileData.entries) {
          if (!HiveManager.getProfileBox().containsKey(entry.key)) {
            await HiveManager.getProfileBox().put(entry.key, entry.value);
          }
        }
      }

      final settingsDataRaw = data['settings'] as Map<String, dynamic>? ?? {};
      final settingsData = _decompressJson(settingsDataRaw) as Map<String, dynamic>;
      settingsData.remove('is_premium');
      for (final entry in settingsData.entries) {
        if (!HiveManager.getSettingsBox().containsKey(entry.key)) {
          await HiveManager.getSettingsBox().put(entry.key, entry.value);
        }
      }

      Future<void> mergeList<T>(String key, String v2Key, dynamic box, T Function(Map<String, dynamic>) fromJson) async {
        final rawList = data.containsKey(v2Key) ? data[v2Key] : data[key];
        final list = (rawList != null) ? _decompressJson(rawList) as List<dynamic> : [];
        for (final item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          final itemId = map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
          if (!box.containsKey(itemId)) {
            await box.put(itemId, fromJson(map));
          }
        }
      }

      await mergeList('records', 'records', HiveManager.getRecordsBox(), RecordModel.fromJson);
      await mergeList('sanskars', 'sanskars', HiveManager.getSanskarsBox(), SanskarModel.fromJson);
      await mergeList('moments', 'moments', HiveManager.getMomentsBox(), MomentModel.fromJson);
      await mergeList('medications', 'meds', HiveManager.getMedicationsBox(), MedicationModel.fromJson);
      await mergeList('familyMembers', 'family', HiveManager.getFamilyMembersBox(), FamilyMemberModel.fromJson);
      await mergeList('foodTracker', 'foodTracker', HiveManager.getFoodTrackerBox(), FoodIntroRecord.fromJson);

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

  static const Map<String, String> _shortKeys = {
    'type': 'ty',
    'timestamp': 'ts',
    'metadata': 'md',
    'babyId': 'bid',
    'medicationId': 'mid',
    'scheduledTime': 'sct',
    'takenTime': 'tkt',
    'status': 'st',
    'amount': 'amt',
    'unit': 'u',
    'name': 'n',
    'description': 'd',
    'category': 'c',
    'isCompleted': 'ic',
    'notes': 'nt',
    'vaccineName': 'vn',
    'dueDate': 'dd',
    'notificationSettings': 'notif',
    'birthDate': 'bd',
    'birthTime': 'bt',
  };

  static Map<String, String>? _longKeysCache;
  static Map<String, String> get _longKeys {
    if (_longKeysCache == null) {
      _longKeysCache = _shortKeys.map((k, v) => MapEntry(v, k));
    }
    return _longKeysCache!;
  }

  static dynamic _compressJson(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      // Check if it's an ISO8601 string starting with year-month-day
      final regExp = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}');
      if (regExp.hasMatch(value)) {
        try {
          final parsed = DateTime.parse(value);
          return parsed.millisecondsSinceEpoch ~/ 1000;
        } catch (_) {
          return value;
        }
      }
      return value;
    }

    if (value is List) {
      final compressedList = value
          .map((e) => _compressJson(e))
          .where((e) => e != null)
          .toList();
      if (compressedList.isEmpty) return null;
      return compressedList;
    }

    if (value is Map) {
      final compressedMap = <String, dynamic>{};
      for (final entry in value.entries) {
        if (entry.value == null) continue;
        final compressedValue = _compressJson(entry.value);
        if (compressedValue == null) continue;
        if (compressedValue is List && compressedValue.isEmpty) continue;
        if (compressedValue is Map && compressedValue.isEmpty) continue;

        final keyStr = entry.key.toString();
        if (keyStr == 'createdBy' || keyStr == 'updatedBy' || keyStr == 'isPremium') continue;

        final shortenedKey = _shortKeys[keyStr] ?? keyStr;
        compressedMap[shortenedKey] = compressedValue;
      }
      if (compressedMap.isEmpty) return null;
      return compressedMap;
    }

    return value;
  }

  static dynamic _decompressJson(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      // If it's a large int (e.g. seconds since epoch from 2020 to 2050)
      if (value > 1500000000 && value < 3000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000).toIso8601String();
      }
      return value;
    }

    if (value is List) {
      return value.map((e) => _decompressJson(e)).toList();
    }

    if (value is Map) {
      final decompressedMap = <String, dynamic>{};
      for (final entry in value.entries) {
        final keyStr = entry.key.toString();
        final originalKey = _longKeys[keyStr] ?? keyStr;
        decompressedMap[originalKey] = _decompressJson(entry.value);
      }
      return decompressedMap;
    }

    return value;
  }
}
