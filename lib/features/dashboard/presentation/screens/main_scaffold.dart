// features/dashboard/presentation/screens/main_scaffold.dart

import 'package:flutter/material.dart';
import '../../../records/presentation/widgets/add_record_modal.dart';
import 'launchpad_screen.dart';
import '../../../records/presentation/screens/records_timeline_screen.dart';
import '../../../guide/presentation/screens/sanskar_journey_screen.dart';
import '../../../settings/presentation/screens/account_screen.dart';
import '../../../../core/widgets/premium_bottom_nav.dart';

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
    const SanskarJourneyScreen(), // 3: Guide/Sanskars
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
          items: const [
            PremiumNavItem(icon: Icons.home_rounded, label: 'Home'),
            PremiumNavItem(icon: Icons.view_timeline_rounded, label: 'Timeline'),
            PremiumNavItem(icon: Icons.add_circle_rounded, label: 'Record'),
            PremiumNavItem(icon: Icons.menu_book_rounded, label: 'Guide'),
            PremiumNavItem(icon: Icons.person_rounded, label: 'Profile'),
          ],
        ),
    );
  }
}
