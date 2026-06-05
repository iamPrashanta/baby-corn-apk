// lib/core/services/cloud_sync_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_service.dart';
import '../local_storage/hive_manager.dart';
import '../design/components/dialogs/app_dialog.dart';

class CloudSyncService {
  static Future<void> performAutoRestoreCheck(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    debugPrint('[AUTO RESTORE CHECK] Checking for existing backup...');
    try {
      final latestBackupRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('backup')
          .doc('latest');

      final snapshot = await latestBackupRef.get();
      if (!snapshot.exists) {
        debugPrint('[AUTO RESTORE SKIPPED] No cloud backup found.');
        return;
      }

      final data = snapshot.data()!;
      final cloudDate = (data['createdAt'] as Timestamp?)?.toDate();
      if (cloudDate == null) return;

      final profileBox = HiveManager.getProfileBox();
      final recordsBox = HiveManager.getRecordsBox();

      final bool hasLocalData = profileBox.isNotEmpty || recordsBox.isNotEmpty;

      if (!hasLocalData) {
        // Scenario A & C: Fresh Install / No Data
        debugPrint('[AUTO RESTORE START] Fresh install detected. Restoring automatically.');
        _showLoadingDialog(context, 'Restoring Backup...');
        await BackupService.restoreBackup();
        if (context.mounted) Navigator.pop(context); // pop loading
        debugPrint('[AUTO RESTORE SUCCESS]');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored successfully!')),
          );
        }
      } else {
        // Scenario B: Existing Data
        debugPrint('[AUTO RESTORE SKIPPED] Local data exists. Keeping local data implicitly.');
      }
    } catch (e) {
      debugPrint('[AUTO RESTORE ERROR] $e');
    }
  }

  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(message),
          ],
        ),
      ),
    );
  }
}
