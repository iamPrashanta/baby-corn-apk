// core/services/backup_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../local_storage/hive_manager.dart';
import '../../features/records/domain/models/record_model.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class BackupService {
  static const String _backupFileName = 'baby_corn_backup.json';

  static Future<drive.DriveApi?> _getDriveApi() async {
    final googleSignIn = GoogleSignIn(scopes: [
      drive.DriveApi.driveAppdataScope,
    ]);
    
    // Try silent sign-in first, fallback to interactive
    var account = await googleSignIn.signInSilently();
    account ??= await googleSignIn.signIn();

    if (account == null) return null;

    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) return null;

    final authenticateClient = GoogleAuthClient({
      'Authorization': 'Bearer $token',
    });

    return drive.DriveApi(authenticateClient);
  }

  static String _generateBackupJson() {
    final recordsBox = HiveManager.getRecordsBox();
    final settingsBox = HiveManager.getSettingsBox();
    final profileBox = HiveManager.getProfileBox();

    final recordsList = recordsBox.values.map((e) => e.toJson()).toList();

    final profileData = {
      'baby_name': settingsBox.get('baby_name'),
      'baby_birthdate': settingsBox.get('baby_birthdate'),
      'baby_feeding_type': settingsBox.get('baby_feeding_type'),
      'baby_gender': settingsBox.get('baby_gender'),
      'baby_birth_weight': settingsBox.get('baby_birth_weight'),
      'babies_list': profileBox.get('babies_list'),
      'active_baby_id': profileBox.get('active_baby_id'),
      'onboarding_complete': profileBox.get('onboarding_complete'),
    };

    final backupData = {
      'backupVersion': 1,
      'schemaVersion': 1,
      'appVersion': '1.0.0',
      'createdAt': DateTime.now().toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(), // kept for backward compatibility if any
      'version': 2, // legacy field
      'profile': profileData,
      'records': recordsList,
    };

    return jsonEncode(backupData);
  }

  static Future<void> _restoreFromJson(String jsonString) async {
    final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

    if (backupData['version'] == null || backupData['records'] == null) {
      throw const FormatException('Invalid backup file format');
    }

    final recordsBox = HiveManager.getRecordsBox();
    final settingsBox = HiveManager.getSettingsBox();
    final profileBox = HiveManager.getProfileBox();

    if (backupData['profile'] != null) {
      final profile = backupData['profile'] as Map<String, dynamic>;
      for (final entry in profile.entries) {
        if (entry.value != null) {
          if (['babies_list', 'active_baby_id', 'onboarding_complete']
              .contains(entry.key)) {
            await profileBox.put(entry.key, entry.value);
          } else {
            await settingsBox.put(entry.key, entry.value);
          }
        }
      }
    }

    await recordsBox.clear();
    final recordsList = backupData['records'] as List;
    for (final r in recordsList) {
      final record = RecordModel.fromJson(r as Map<String, dynamic>);
      await recordsBox.put(record.id, record);
    }
  }

  /// Backs up to Google Drive's hidden AppData folder
  static Future<bool> backupToGoogleDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final jsonString = _generateBackupJson();
      final content = utf8.encode(jsonString);
      final media = drive.Media(Stream.value(content), content.length);

      // Check if file already exists in appDataFolder
      final query = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id, name)',
      );

      final files = query.files;
      if (files != null && files.isNotEmpty) {
        // Update existing file
        final fileId = files.first.id!;
        await driveApi.files.update(
          drive.File(),
          fileId,
          uploadMedia: media,
        );
      } else {
        // Create new file
        final file = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];
        await driveApi.files.create(
          file,
          uploadMedia: media,
        );
      }

      debugPrint('[BACKUP] Successfully backed up to Google Drive AppData');
      return true;
    } catch (e) {
      debugPrint('[BACKUP ERROR] $e');
      return false;
    }
  }

  /// Restores from Google Drive's hidden AppData folder
  static Future<bool> restoreFromGoogleDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final query = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id, name)',
      );

      final files = query.files;
      if (files == null || files.isEmpty) {
        debugPrint('[RESTORE] No backup file found in Google Drive');
        return false;
      }

      final fileId = files.first.id!;
      final drive.Media media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await media.stream.listen((data) {
        dataStore.insertAll(dataStore.length, data);
      }).asFuture();

      final jsonString = utf8.decode(dataStore);
      await _restoreFromJson(jsonString);

      debugPrint('[RESTORE] Successfully restored from Google Drive');
      return true;
    } catch (e) {
      debugPrint('[RESTORE ERROR] $e');
      return false;
    }
  }
}
