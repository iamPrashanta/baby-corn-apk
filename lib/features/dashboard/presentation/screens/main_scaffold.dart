// features/dashboard/presentation/screens/main_scaffold.dart

import 'package:flutter/material.dart';
import '../../../records/presentation/widgets/add_record_modal.dart';
import 'launchpad_screen.dart';
import '../../../records/presentation/screens/records_timeline_screen.dart';
import '../../../guide/presentation/screens/guide_main_screen.dart';
import '../../../settings/presentation/screens/account_screen.dart';
import '../../../../core/widgets/premium_bottom_nav.dart';
import '../../../../l10n/app_localizations.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LaunchpadScreen(), // 0: Home
    const RecordsTimelineScreen(), // 1: Timeline
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
    
    return Scaffold(
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
            PremiumNavItem(icon: Icons.view_timeline_rounded, label: l10n.records),
            PremiumNavItem(icon: Icons.add_circle_rounded, label: l10n.records), // Add record uses records label or can be hardcoded 'Add'
            PremiumNavItem(icon: Icons.menu_book_rounded, label: l10n.guides),
            PremiumNavItem(icon: Icons.person_rounded, label: l10n.account),
          ],
        ),
    );
  }
}
