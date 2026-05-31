import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'sanskar_journey_screen.dart';
import 'baby_cry_language_screen.dart';
import 'baby_rashes_screen.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/theme/glass_system/glass_colors.dart';

import '../../../../l10n/app_localizations.dart';

class GuideMainScreen extends StatelessWidget {
  const GuideMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(title: l10n.guides),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
        children: [
          _buildGuideCard(
            context: context,
            title: l10n.cryLanguage,
            icon: Icons.record_voice_over_rounded,
            color: const Color(0xFF81C784),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BabyCryLanguageScreen()));
            },
          ),
          _buildGuideCard(
            context: context,
            title: "First Foods (6+ Months)",
            icon: Icons.restaurant_menu_rounded,
            color: const Color(0xFFFFB74D),
            onTap: () => context.push('/guide/first_foods'),
          ),
          _buildGuideCard(
            context: context,
            title: l10n.babyRashes,
            icon: Icons.healing_rounded,
            color: const Color(0xFFE57373),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BabyRashesScreen()));
            },
          ),
          _buildGuideCard(
            context: context,
            title: l10n.spiritualJourney,
            icon: Icons.self_improvement_rounded,
            color: const Color(0xFFBA68C8),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SanskarJourneyScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? GlassColors.darkGlassSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

