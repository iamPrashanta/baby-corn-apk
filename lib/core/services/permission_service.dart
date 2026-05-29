import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized just-in-time permission service for Baby Corn.
///
/// RULE: Never call these at app startup. Call them immediately BEFORE
/// the feature that needs the permission (e.g., camera before taking a baby photo).
class PermissionService {
  
  // ---------------------------------------------------------------------------
  // Camera — for baby milestone photos
  // ---------------------------------------------------------------------------
  static Future<bool> requestCamera(BuildContext context) async {
    return _requestWithRationale(
      context,
      permission: Permission.camera,
      title: 'Camera Access Required',
      reason: 'We need camera access so you can take photos of your baby\'s milestones.',
      icon: Icons.camera_alt_rounded,
    );
  }

  // ---------------------------------------------------------------------------
  // Photos / Storage — for uploading baby photos
  // ---------------------------------------------------------------------------
  static Future<bool> requestPhotos(BuildContext context) async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkVersion();
      if (sdkInt >= 33) {
        return _requestWithRationale(
          context,
          permission: Permission.photos,
          title: 'Photo Library Access',
          reason: 'We need access to your photos so you can upload milestone pictures.',
          icon: Icons.photo_library_rounded,
        );
      } else {
        return _requestWithRationale(
          context,
          permission: Permission.storage,
          title: 'Storage Access',
          reason: 'We need storage access to save and upload baby milestone photos.',
          icon: Icons.folder_rounded,
        );
      }
    } else {
      return _requestWithRationale(
        context,
        permission: Permission.photos,
        title: 'Photo Library Access',
        reason: 'We need access to your photos so you can upload milestone pictures.',
        icon: Icons.photo_library_rounded,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Microphone — for recording baby sounds
  // ---------------------------------------------------------------------------
  static Future<bool> requestMicrophone(BuildContext context) async {
    return _requestWithRationale(
      context,
      permission: Permission.microphone,
      title: 'Microphone Access Required',
      reason: 'We need microphone access to record your baby\'s first words and sounds.',
      icon: Icons.mic_rounded,
    );
  }

  // ---------------------------------------------------------------------------
  // Location — for finding nearby pediatricians (Future Scope)
  // ---------------------------------------------------------------------------
  static Future<bool> requestLocation(BuildContext context) async {
    return _requestWithRationale(
      context,
      permission: Permission.locationWhenInUse,
      title: 'Location Access Required',
      reason: 'We need your location to find nearby pediatricians and geotag milestone photos.',
      icon: Icons.location_on_rounded,
    );
  }

  // ---------------------------------------------------------------------------
  // Notifications — for feeding/sleep reminders
  // ---------------------------------------------------------------------------
  static Future<bool> requestNotifications(BuildContext context) async {
    return _requestWithRationale(
      context,
      permission: Permission.notification,
      title: 'Enable Notifications',
      reason: 'Get timely reminders for baby feeding, sleep schedules, and vaccinations.',
      icon: Icons.notifications_active_rounded,
    );
  }

  // ---------------------------------------------------------------------------
  // Calendar — for syncing vaccination schedules (Future Scope)
  // ---------------------------------------------------------------------------
  static Future<bool> requestCalendar(BuildContext context) async {
    return _requestWithRationale(
      context,
      permission: Permission.calendarFullAccess, // Adjust if write-only is needed
      title: 'Calendar Access',
      reason: 'We need calendar access to sync vaccination schedules to your device.',
      icon: Icons.calendar_month_rounded,
    );
  }

  // ---------------------------------------------------------------------------
  // Contacts — for sharing milestones (Future Scope)
  // ---------------------------------------------------------------------------
  static Future<bool> requestContacts(BuildContext context) async {
    return _requestWithRationale(
      context,
      permission: Permission.contacts,
      title: 'Contacts Access',
      reason: 'We need contacts access to easily share baby milestones with your family.',
      icon: Icons.contacts_rounded,
    );
  }

  // ---------------------------------------------------------------------------
  // Check current status without requesting
  // ---------------------------------------------------------------------------
  static Future<bool> isCameraGranted() async => await Permission.camera.isGranted;
  static Future<bool> isNotificationGranted() async => await Permission.notification.isGranted;
  static Future<bool> isLocationGranted() async => await Permission.locationWhenInUse.isGranted;

  // ---------------------------------------------------------------------------
  // Open OS Settings (when permanently denied)
  // ---------------------------------------------------------------------------
  static Future<void> openSettings() => openAppSettings();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------
  static Future<bool> _requestWithRationale(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String reason,
    required IconData icon,
  }) async {
    if (await permission.isGranted) return true;

    if (await permission.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(context, title: title, reason: reason, icon: icon);
      }
      return false;
    }

    if (context.mounted) {
      final proceed = await _showRationaleDialog(context, title: title, reason: reason, icon: icon);
      if (!proceed) return false;
    }

    final status = await permission.request();
    return status.isGranted;
  }

  static Future<bool> _showRationaleDialog(
    BuildContext context, {
    required String title,
    required String reason,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 17))),
              ],
            ),
            content: Text(reason, style: const TextStyle(height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Allow'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<void> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String reason,
    required IconData icon,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('Permission Denied', style: TextStyle(fontSize: 17))),
          ],
        ),
        content: Text(
          '$reason\n\nPlease enable this permission in your device Settings.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Future<int> _getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      return 33; // Defaulting to safe modern Android assumption without adding device_info_plus
    } catch (_) {
      return 33;
    }
  }
}
