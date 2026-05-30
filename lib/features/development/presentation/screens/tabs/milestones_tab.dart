import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

class MilestonesTab extends StatelessWidget {
  const MilestonesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final milestones = [
      {'emoji': '😊', 'title': l10n.firstSmile, 'subtitle': 'A heartwarming moment'},
      {'emoji': '🔄', 'title': l10n.firstRoll, 'subtitle': 'Tummy to back, or back to tummy'},
      {'emoji': '🚼', 'title': l10n.firstCrawl, 'subtitle': 'On the move!'},
      {'emoji': '👣', 'title': l10n.firstSteps, 'subtitle': 'Walking into a new world'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24).copyWith(bottom: 120),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final milestone = milestones[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _MilestoneCard(
            emoji: milestone['emoji']!,
            title: milestone['title']!,
            subtitle: milestone['subtitle']!,
            isDark: isDark,
            onTap: () {
              // Coming Soon Modal
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.all(32),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Text(milestone['emoji']!, style: const TextStyle(fontSize: 48)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.comingSoon,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Soon you can log your baby\'s ${milestone['title']} here.',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).slideY(begin: 0.1, end: 0),
        );
      },
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _MilestoneCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1C20) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : const Color(0xFF9A8C98),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
