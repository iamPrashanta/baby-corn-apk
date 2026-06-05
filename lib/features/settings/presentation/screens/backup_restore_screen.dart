// lib/features/settings/presentation/screens/backup_restore_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/components/cards/app_card.dart';
import '../../../../core/design/components/buttons/app_button.dart';
import '../../../../core/design/components/dialogs/app_dialog.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isLoading = false;
  DateTime? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _fetchBackupInfo();
  }

  Future<void> _fetchBackupInfo() async {
    final date = await BackupService.getLastBackupDate();
    if (mounted) {
      setState(() {
        _lastBackupDate = date;
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    final user = await AuthService.signInWithGoogle();
    if (user != null) {
      await _fetchBackupInfo();
      // Auto Restore Prompt logic
      if (_lastBackupDate != null && mounted) {
        final shouldRestore = await AppDialog.show(
          context: context,
          title: 'Backup Found',
          contentText:
              'We found an existing Baby Corn backup associated with your Google account.\n\nWould you like to restore it now?',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        );
        if (shouldRestore == true) {
          await _handleRestore();
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    await AuthService.signOut();
    setState(() {
      _lastBackupDate = null;
      _isLoading = false;
    });
  }

  Future<void> _handleBackup() async {
    setState(() => _isLoading = true);
    try {
      await BackupService.backupNow();
      await _fetchBackupInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup completed successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    final confirm = await AppDialog.show(
      context: context,
      title: 'Restore Backup',
      contentText:
          'This will replace all current data on this device with the data from your backup. This action cannot be undone. Continue?',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Restore'),
        ),
      ],
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await BackupService.restoreBackup();
      if (mounted) {
        AppDialog.show(
          context: context,
          title: 'Restore Successful',
          contentText:
              'Your backup has been restored. Please restart the app for all changes to take effect.',
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          context: context,
          title: 'Restore Failed',
          contentText: 'Could not restore backup: $e',
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAccountCard(user),
                  const SizedBox(height: 16),
                  if (user != null) _buildBackupCard(),
                  const SizedBox(height: 16),
                  _buildSafetyCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountCard(User? user) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Google Account',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (user != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child:
                        user.photoURL == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName ?? 'Google User',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(user.email ?? '',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Sign Out',
                type: AppButtonType.outline,
                onPressed: _handleSignOut,
              ),
            ] else ...[
              const Text(
                  'Sign in with Google to backup your baby\'s records securely to the cloud.'),
              const SizedBox(height: 24),
              AppButton(
                text: 'Sign In with Google',
                type: AppButtonType.primary,
                onPressed: _handleSignIn,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cloud Backup', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Last Backup:'),
                Text(
                  _lastBackupDate != null
                      ? DateFormat('MMMM d, yyyy  h:mm a')
                          .format(_lastBackupDate!)
                      : 'Never',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Backup Size:'),
                Text('Unknown (Dynamic)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Backup Now',
                    type: AppButtonType.primary,
                    onPressed: _handleBackup,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    text: 'Restore Backup',
                    type: AppButtonType.secondary,
                    onPressed: _lastBackupDate != null ? _handleRestore : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.security, color: AppColors.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Safety & Privacy',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Backups are stored securely in your Google account and are only accessible by you. '
                    'We never share or analyze your personal records.',
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
