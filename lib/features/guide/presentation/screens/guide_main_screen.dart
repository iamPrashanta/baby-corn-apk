import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'sanskar_journey_screen.dart';
import 'baby_cry_language_screen.dart';
import 'baby_rashes_screen.dart';
import '../../../../core/design/layouts/custom_app_bar.dart';
import '../../../../core/design/tokens/colors.dart';

import '../../../../l10n/app_localizations.dart';

class GuideMainScreen extends StatelessWidget {
  const GuideMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(title: l10n.guides),
      body: ListView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
        children: [
          Text(
            "Knowledge Base",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Explore expert guides, track milestones, and learn how to best care for your baby.",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _buildGuideListTile(
            context: context,
            title: l10n.cryLanguage,
            subtitle: "Learn to decode your baby's universal cries and understand their needs instantly.",
            icon: Icons.record_voice_over_rounded,
            color: AppColors.secondary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BabyCryLanguageScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildGuideListTile(
            context: context,
            title: "First Foods (6+ Months)",
            subtitle: "Track new foods, record reactions, and monitor potential allergies safely.",
            icon: Icons.restaurant_menu_rounded,
            color: AppColors.primary,
            onTap: () => context.push('/guide/first_foods'),
          ),
          const SizedBox(height: 16),
          _buildGuideListTile(
            context: context,
            title: l10n.babyRashes,
            subtitle: "Identify and treat common skin conditions with our visual rash guide.",
            icon: Icons.healing_rounded,
            color: AppColors.error,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BabyRashesScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildGuideListTile(
            context: context,
            title: l10n.spiritualJourney,
            subtitle: "Track the 16 traditional Sanskars and important spiritual milestones.",
            icon: Icons.self_improvement_rounded,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SanskarJourneyScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuideListTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.05 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4.0),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.black26, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

