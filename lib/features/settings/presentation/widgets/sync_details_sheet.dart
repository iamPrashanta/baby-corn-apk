// features/settings/presentation/widgets/sync_details_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SyncDetailsSheet extends ConsumerStatefulWidget {
  const SyncDetailsSheet({super.key});

  @override
  ConsumerState<SyncDetailsSheet> createState() => _SyncDetailsSheetState();
}

class _SyncDetailsSheetState extends ConsumerState<SyncDetailsSheet> {
  bool _isSyncing = false;
  String? _lastSyncTime;
  int _totalRecords = 0;
  int _totalBabies = 0;

  @override
  void initState() {
    super.initState();
    _loadSyncDetails();
  }

  void _loadSyncDetails() {
    final settingsBox = HiveManager.getSettingsBox();
    final recordsBox = HiveManager.getRecordsBox();
    
    _lastSyncTime = settingsBox.get('last_sync_time');
    _totalRecords = recordsBox.length;
    
    final babiesJson = settingsBox.get('babies_list');
    if (babiesJson != null && babiesJson.toString().isNotEmpty) {
      // Just a rough count of occurrences of '"id":'
      _totalBabies = '"id"'.allMatches(babiesJson.toString()).length;
    }

    if (mounted) setState(() {});
  }

  String _formatLastSync() {
    if (_lastSyncTime == null) return 'Never';
    try {
      final date = DateTime.parse(_lastSyncTime!);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
      if (difference.inDays < 1) return '${difference.inHours} hours ago';
      
      return DateFormat('MMM d, yyyy - h:mm a').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _forceSync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to sync data.')),
      );
      return;
    }

    setState(() => _isSyncing = true);
    
    await SyncService.syncOfflineDataToCloud();
    await SyncService.syncCloudDataToLocal();
    
    if (mounted) {
      _loadSyncDetails();
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync complete!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final isConnected = user != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C20) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.cloud_sync, size: 28, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Sync Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.cloud_done : Icons.cloud_off,
                        size: 14,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConnected ? 'Connected' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            _buildDetailRow(
              icon: Icons.access_time,
              title: 'Last Synced',
              value: _formatLastSync(),
              isDark: isDark,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.list_alt,
              title: 'Local Records',
              value: '$_totalRecords saved',
              isDark: isDark,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.family_restroom,
              title: 'Baby Profiles',
              value: '$_totalBabies profiles',
              isDark: isDark,
            ),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSyncing || !isConnected ? null : _forceSync,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.blue.withOpacity(0.5),
              ),
              child: _isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Force Sync Now',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
