// features/settings/presentation/screens/account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/sync_details_sheet.dart';
import '../../../../core/local_storage/secure_storage_manager.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/premium_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen>
    with WidgetsBindingObserver {
  int _timeoutMinutes = 0;

  // Firebase user (null if offline)
  User? get _firebaseUser =>
      AppConfig.enableFirebaseAuth ? FirebaseAuth.instance.currentUser : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTimeout();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh state if needed
    }
  }

  Future<void> _loadTimeout() async {
    final timeout = await SecureStorageManager.getSessionTimeout();
    setState(() => _timeoutMinutes = timeout);
  }

  Future<void> _updateTimeout(int minutes) async {
    await SecureStorageManager.saveSessionTimeout(minutes);
    setState(() => _timeoutMinutes = minutes);
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        setState(() {}); // Refresh to show Google user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed in with Google!')),
        );
        // Sync local offline data to cloud and fetch cloud data
        await SyncService.syncOfflineDataToCloud();
        await SyncService.syncCloudDataToLocal();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Signed out. You are now in Offline Mode.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ─── Profile Card ───────────────────────────────────────────
          _buildProfileCard(isDark),
          const SizedBox(height: 24),

          _buildSettingsSection(
            context,
            AppLocalizations.of(context)?.appTitle ?? 'App Settings',
            [
              ListTile(
                leading: const Icon(Icons.language),
                title:
                    Text(AppLocalizations.of(context)?.language ?? 'Language'),
                trailing: DropdownButton<Locale>(
                  value: ref.watch(localeProvider),
                  onChanged: (newLocale) {
                    if (newLocale != null) {
                      ref.read(localeProvider.notifier).setLocale(newLocale);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                        value: Locale('en'), child: Text('English')),
                    DropdownMenuItem(
                        value: Locale('hi'), child: Text('हिन्दी')),
                    DropdownMenuItem(value: Locale('bn'), child: Text('বাংলা')),
                    DropdownMenuItem(
                        value: Locale('te'), child: Text('తెలుగు')),
                    DropdownMenuItem(value: Locale('ta'), child: Text('தமிழ்')),
                    DropdownMenuItem(value: Locale('kn'), child: Text('ಕನ್ನಡ')),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('Reminders'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/settings/reminders');
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref
                          .read(themeModeProvider.notifier)
                          .updateThemeMode(mode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(
                        value: ThemeMode.dark, child: Text('Dark')),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('App Lock Timeout'),
                trailing: DropdownButton<int>(
                  value: _timeoutMinutes,
                  onChanged: (val) {
                    if (val != null) _updateTimeout(val);
                  },
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Immediately')),
                    DropdownMenuItem(value: 1, child: Text('1 minute')),
                    DropdownMenuItem(value: 5, child: Text('5 minutes')),
                    DropdownMenuItem(value: 30, child: Text('30 minutes')),
                    DropdownMenuItem(value: -1, child: Text('Never')),
                  ],
                ),
              ),

            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            context,
            'Family',
            [
              ListTile(
                leading: const Icon(Icons.family_restroom),
                title: const Text('Manage Babies'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (!isPremium) {
                    context.push('/subscription');
                  } else {
                    context.push('/manage_babies');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            context,
            'Data & Backup',
            [
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Export Backup (Local)'),
                onTap: () async {
                  final success = await BackupService.exportBackup();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(success
                              ? 'Backup exported successfully!'
                              : 'Backup failed')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Import Backup (Local)'),
                onTap: () async {
                  final success = await BackupService.importBackup();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(success
                              ? 'Backup restored successfully! Restarting...'
                              : 'Restore failed')),
                    );
                    if (success) context.go('/'); // Restart app to reload state
                  }
                },
              ),
              if (AppConfig.enableCloudSync)
                ListTile(
                  leading: const Icon(Icons.cloud_sync, color: Colors.blue),
                  title: const Text('Sync Data'),
                  subtitle: const Text('Manage cloud sync and backups'),
                  onTap: () {
                    if (!isPremium) {
                      context.push('/subscription');
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const SyncDetailsSheet(),
                    );
                  },
                ),
              if (!AppConfig.enableCloudBackup)
                ListTile(
                  leading: const Icon(Icons.group, color: Colors.blue),
                  title: const Text('Family Sharing'),
                  subtitle: const Text('Invite partner or family member'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    if (!isPremium) {
                      context.push('/subscription');
                      return;
                    }
                    
                    // 1. Request Contacts Permission
                    final status = await Permission.contacts.request();
                    if (!status.isGranted) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Contacts permission is required to invite family members.')),
                        );
                      }
                      return;
                    }

                    // 2. Open Native Contact Picker
                    final contact = await FlutterContacts.native
                        .showPicker(properties: {ContactProperty.phone});
                    if (contact == null) return; // User canceled

                    // 3. Try to get a phone number
                    if (contact.phones.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Selected contact has no phone number.')),
                        );
                      }
                      return;
                    }

                    final phoneNumber = contact.phones.first.number;
                    final contactName = contact.displayName;

                    // 4. Show Disclaimer Dialog
                    if (mounted) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Invite $contactName?'),
                          content: const Text(
                            'An SMS invitation will be sent to their number.\n\n'
                            'Disclaimer: Standard SMS charges may apply from your network provider. Baby Corn does not charge anything.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Send SMS'),
                            ),
                          ],
                        ),
                      );

                      // 5. Launch SMS App
                      if (confirm == true) {
                        final uri = Uri.parse(
                            "sms:$phoneNumber?body=Hey! Join me on Baby Corn to manage our baby's profile together. Download it here: https://play.google.com/store/apps/details?id=com.babycorn.app");
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Could not open messaging app.')),
                            );
                          }
                        }
                      }
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            context,
            'About',
            [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About Baby Corn'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Baby Corn',
                    applicationVersion: '1.0.0',
                    applicationIcon: Image.asset(
                      'assets/images/logo.png', // Assuming there's a logo in assets, otherwise a generic icon
                      width: 48,
                      height: 48,
                      errorBuilder: (_, __, ___) => const Icon(Icons.child_care, size: 48),
                    ),
                    applicationLegalese: '© 2026 Baby Corn App',
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        "Baby Corn is an all-in-one companion app for modern parents to track and manage their baby's daily activities like feeding, sleeping, and diaper changes.",
                      ),
                    ],
                  );
                },
              ),
              if (_firebaseUser != null)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log Out',
                      style: TextStyle(color: Colors.red)),
                  onTap: _signOut,
                )
              else if (AppConfig.enableFirebaseAuth)
                ListTile(
                  leading: const Icon(Icons.g_mobiledata, size: 32, color: Colors.blue),
                  title: Text(AppLocalizations.of(context)?.signInWithGoogle ?? 'Sign in with Google'),
                  onTap: _signInWithGoogle,
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    final user = _firebaseUser;
    final isGoogleUser = user != null;

    final cardBg = isDark ? const Color(0xFF1E1C20) : Colors.white;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(user, isDark),
          const SizedBox(width: 20),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGoogleUser
                      ? (user.displayName?.isNotEmpty == true
                          ? user.displayName!
                          : 'Baby Corn User')
                      : 'Offline User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (isGoogleUser && user.email != null)
                  Text(
                    user.email!,
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGoogleUser
                        ? AppColors.primary.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGoogleUser
                            ? Icons.verified_rounded
                            : Icons.wifi_off_rounded,
                        size: 12,
                        color: isGoogleUser ? AppColors.primary : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isGoogleUser ? 'Google Account' : 'Offline Mode',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              isGoogleUser ? AppColors.primary : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(User? user, bool isDark) {
    const double size = 72;

    if (user?.photoURL != null) {
      // Google profile photo
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          user!.photoURL!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _defaultAvatar(size, isDark, user.displayName),
        ),
      );
    }

    return _defaultAvatar(size, isDark, user?.displayName);
  }

  Widget _defaultAvatar(double size, bool isDark, String? name) {
    final initials = _getInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.secondary,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '👶';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildSettingsSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias, // This clips the rectangular ripple animations of ListTiles inside
          child: Column(children: children),
        ),
      ],
    );
  }
}
