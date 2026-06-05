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
        final prefs = await SharedPreferences.getInstance();
        final localModifiedStr = prefs.getString('last_local_modified');
        DateTime localDate = DateTime.now().subtract(const Duration(days: 365));
        if (localModifiedStr != null) {
          localDate = DateTime.parse(localModifiedStr);
        } else {
           // fallback heuristic
           if (recordsBox.isNotEmpty) {
             localDate = DateTime.now(); // Assume local is dirty if no pref
           }
        }

        if (localDate.isAfter(cloudDate)) {
          debugPrint('[AUTO RESTORE SKIPPED] Local data is newer. Keeping local.');
          // Offer Backup Now? We can just do nothing or show a snackbar.
        } else {
          debugPrint('[AUTO RESTORE MERGE REQUIRED] Cloud backup is newer.');
          if (context.mounted) {
            final result = await AppDialog.show(
              context: context,
              title: 'Cloud Backup Found',
              contentText: 'A newer backup was found in the cloud. Would you like to merge it with your local data or keep your local data?',
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'keep'),
                  child: const Text('Keep Local'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'merge'),
                  child: const Text('Merge Data'),
                ),
              ],
            );

            if (result == 'merge') {
              _showLoadingDialog(context, 'Merging Data...');
              await BackupService.mergeBackup();
              if (context.mounted) Navigator.pop(context); // pop loading
              debugPrint('[AUTO RESTORE SUCCESS]');
            } else {
              debugPrint('[AUTO RESTORE SKIPPED] User chose to keep local data.');
            }
          }
        }
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
