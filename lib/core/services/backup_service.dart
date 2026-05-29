// core/services/backup_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../local_storage/hive_manager.dart';
import '../../features/records/domain/models/record_model.dart';

class BackupService {
  /// Exports all data (baby profile from settings box + records) to a JSON file and shares it.
  static Future<bool> exportBackup() async {
    try {
      final recordsBox = HiveManager.getRecordsBox();
      final settingsBox = HiveManager.getSettingsBox();

      final recordsList = recordsBox.values.map((e) => e.toJson()).toList();

      // Profile is stored as individual keys in the settings box
      final profileData = {
        'baby_name': settingsBox.get('baby_name'),
        'baby_birthdate': settingsBox.get('baby_birthdate'),
        'baby_feeding_type': settingsBox.get('baby_feeding_type'),
        'baby_gender': settingsBox.get('baby_gender'),
        'baby_birth_weight': settingsBox.get('baby_birth_weight'),
        'onboarding_complete': settingsBox.get('onboarding_complete'),
      };

      final backupData = {
        'version': 2,
        'timestamp': DateTime.now().toIso8601String(),
        'profile': profileData,
        'records': recordsList,
      };

      final jsonString = jsonEncode(backupData);

      final dir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      final file = File('${dir.path}/baby_corn_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      final result = await Share.shareXFiles([XFile(file.path)], text: 'Baby Corn Backup');
      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Export failed: $e');
      return false;
    }
  }

  /// Prompts user to pick a JSON backup and restores it.
  static Future<bool> importBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return false; // User canceled
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (backupData['version'] == null || backupData['records'] == null) {
        throw const FormatException('Invalid backup file format');
      }

      final recordsBox = HiveManager.getRecordsBox();
      final settingsBox = HiveManager.getSettingsBox();

      // Restore profile keys into settings box
      if (backupData['profile'] != null) {
        final profile = backupData['profile'] as Map<String, dynamic>;
        for (final entry in profile.entries) {
          if (entry.value != null) {
            await settingsBox.put(entry.key, entry.value);
          }
        }
      }

      // Clear existing records and restore
      await recordsBox.clear();
      final recordsList = backupData['records'] as List;
      for (final r in recordsList) {
        final record = RecordModel.fromJson(r as Map<String, dynamic>);
        await recordsBox.put(record.id, record);
      }

      return true;
    } catch (e) {
      debugPrint('Import failed: $e');
      return false;
    }
  }
}
