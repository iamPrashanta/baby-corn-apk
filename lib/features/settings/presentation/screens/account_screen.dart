// lib/features/settings/presentation/screens/account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/design/tokens/colors.dart';
// import '../widgets/sync_details_sheet.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design/layouts/custom_app_bar.dart';
// import '../../../../core/local_storage/hive_manager.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../records/presentation/providers/records_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/premium_provider.dart';
import '../providers/theme_provider.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen>
    with WidgetsBindingObserver {

  // Firebase user accessed via provider in build()

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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



  Future<void> _signInWithGoogle() async {
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed in with Google!')),
        );
        // Note: Auto-sync on sign-in is removed in favor of manual Backup & Restore.
        // The user can go to the Backup & Restore screen to retrieve their data.

        // Invalidate providers to force UI refresh with new Hive data
        ref.invalidate(activeBabyProvider);
        ref.invalidate(recordsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
      }
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed out. You are now in Offline Mode.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[ACCOUNT UI UPDATED]');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = ref.watch(premiumProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Account & Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ─── Profile Card ───────────────────────────────────────────
          _buildProfileCard(isDark, user),
          const SizedBox(height: 24),

          _buildSettingsSection(
            context,
            AppLocalizations.of(context)?.appTitle ?? 'App Settings',
            [
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('Reminders'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/settings/reminders');
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/language');
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('App Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: ref.watch(themeModeProvider),
                  onChanged: (mode) {
                    if (mode != null) {
                      ref
                          .read(themeModeProvider.notifier)
                          .updateThemeMode(mode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              ),

            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(context, 'Family', [
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
            ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text('Manage Subscription'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/subscription');
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSettingsSection(
            context,
            'Data & Backup',
            [
              ListTile(
                leading: const Icon(Icons.cloud_sync, color: AppColors.primary),
                title: const Text('Backup & Restore'),
                subtitle: const Text('Save your baby\'s records to Google Cloud'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/backup_restore');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            context,
            'System',
            [
              ListTile(
                leading: const Icon(Icons.bug_report, color: AppColors.primary),
                title: const Text('App Diagnostics'),
                subtitle: const Text('Test OEM alarm background restrictions'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/diagnostics');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(context, 'About', [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About Baby Corn'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Baby Corn',
                  applicationVersion: '1.0.0',
                  applicationIcon: Image.asset(
                    'assets/images/logo_transparent.png', // Assuming there's a logo in assets, otherwise a generic icon
                    width: 48,
                    height: 48,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.child_care, size: 48),
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
            if (user != null)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _signOut();
                          },
                          child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              )
            else if (AppConfig.enableFirebaseAuth)
              ListTile(
                leading: const Icon(
                  Icons.g_mobiledata,
                  size: 32,
                  color: Colors.blue,
                ),
                title: Text(
                  AppLocalizations.of(context)?.signInWithGoogle ??
                      'Sign in with Google',
                ),
                onTap: _signInWithGoogle,
              ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, User? user) {
    final isGoogleUser = user != null;

    final cardBg = Theme.of(context).cardColor;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(4.0),
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
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isGoogleUser
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGoogleUser
                            ? Icons.verified_rounded
                            : Icons.wifi_off_rounded,
                        size: 12,
                        color: isGoogleUser
                            ? AppColors.primary
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isGoogleUser ? 'Google Account' : 'Offline Mode',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isGoogleUser
                              ? AppColors.primary
                              : AppColors.primary,
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
          colors: [AppColors.primary.withOpacity(0.8), AppColors.secondary],
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
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          clipBehavior: Clip
              .antiAlias, // This clips the rectangular ripple animations of ListTiles inside
          child: Column(children: children),
        ),
      ],
    );
  }
}
