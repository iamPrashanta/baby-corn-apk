// lib/features/dashboard/presentation/screens/main_scaffold.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../records/presentation/widgets/add_record_modal.dart';
import 'launchpad_screen.dart';
import '../../../development/presentation/screens/development_main_screen.dart';
import '../../../guide/presentation/screens/guide_main_screen.dart';
import '../../../settings/presentation/screens/account_screen.dart';
import '../../../../core/design/layouts/premium_bottom_nav.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/local_storage/hive_manager.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestNotifications();
      // Alarm recovery hook: if the FullScreenIntent launched the app while
      // the main.dart post-frame callback ran before this scaffold was mounted,
      // this second call ensures navigation still happens.
      AlarmService.checkPendingAlarm();
    });
  }

  Future<void> _checkAndRequestNotifications() async {
    if (!mounted) return;
    final settingsBox = HiveManager.getSettingsBox();
    final hasAsked = settingsBox.get('asked_notifications', defaultValue: false);
    if (!hasAsked) {
      await PermissionService.requestNotifications(context);
      await settingsBox.put('asked_notifications', true);
    }
  }

  final List<Widget> _screens = [
    const LaunchpadScreen(), // 0: Home
    const DevelopmentMainScreen(), // 1: Development
    const SizedBox.shrink(), // 2: Record (Never shown, handled via modal)
    const GuideMainScreen(), // 3: Guide/Sanskars
    const AccountScreen(), // 4: Profile
  ];

  void _showAddRecordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddRecordModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        final now = DateTime.now();
        final maxDuration = const Duration(seconds: 2);
        final isWarning = _lastPressedAt == null ||
            now.difference(_lastPressedAt!) > maxDuration;

        if (isWarning) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Click back again to exit the app'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: PremiumBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              _showAddRecordModal(context);
            } else {
              setState(() => _currentIndex = index);
            }
          },
          items: [
            PremiumNavItem(icon: Icons.home_rounded, label: l10n.launchpad),
            PremiumNavItem(
                icon: Icons.timeline_rounded, label: l10n.development),
            PremiumNavItem(
                icon: Icons.add_circle_rounded,
                label: l10n
                    .records), // Add record uses records label or can be hardcoded 'Add'
            PremiumNavItem(icon: Icons.menu_book_rounded, label: l10n.guides),
            PremiumNavItem(icon: Icons.person_rounded, label: l10n.account),
          ],
        ),
      ),
    );
  }
}
