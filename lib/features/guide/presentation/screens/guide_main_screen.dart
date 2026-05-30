import 'package:flutter/material.dart';
import 'sanskar_journey_screen.dart';
import 'baby_cry_language_screen.dart';
import 'baby_rashes_screen.dart';
import '../../../../core/constants/app_colors.dart';

import '../../../../l10n/app_localizations.dart';

class GuideMainScreen extends StatelessWidget {
  const GuideMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.guides),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              Tab(text: l10n.spiritualJourney),
              Tab(text: l10n.cryLanguage),
              Tab(text: l10n.babyRashes),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SanskarJourneyScreen(),
            BabyCryLanguageScreen(),
            BabyRashesScreen(),
          ],
        ),
      ),
    );
  }
}
