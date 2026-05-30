import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../domain/models/sanskar_model.dart';
import '../../domain/services/sanskar_date_engine.dart';
import '../providers/sanskar_provider.dart';
import '../widgets/sanskar_detail_sheet.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';

class SanskarJourneyScreen extends ConsumerWidget {
  const SanskarJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sanskars = ref.watch(sanskarsProvider);
    final activeBaby = ref.watch(activeBabyProvider);
    final birthDate = activeBaby?.birthDate ?? DateTime.now(); // Fallback
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completedCount = sanskars.where((s) => s.isCompleted).length;
    final total = sanskars.length;

    // Sort by effective date
    final sortedSanskars = List<SanskarModel>.from(sanskars)
      ..sort((a, b) {
        final dateA = SanskarDateEngine.getEffectiveDate(a, birthDate);
        final dateB = SanskarDateEngine.getEffectiveDate(b, birthDate);
        return dateA.compareTo(dateB);
      });

    final locale = ref.watch(localeProvider);
    final isHindi = locale.languageCode == 'hi';
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.spiritualJourney,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                Text(
                  l10n.spiritualJourneyDesc,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final sanskar = sortedSanskars[index];
                final effectiveDate = SanskarDateEngine.getEffectiveDate(sanskar, birthDate);
                return _buildTimelineCard(context, ref, sanskar, effectiveDate, index, isDark, isHindi, l10n)
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: 0.05, end: 0, duration: 200.ms);
              },
              childCount: sortedSanskars.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)), // Bottom nav padding
      ],
    );
  }

  // Removed _buildHeroHeader

  Widget _buildTimelineCard(BuildContext context, WidgetRef ref, SanskarModel sanskar, DateTime date, int index, bool isDark, bool isHindi, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    
    String timeText;
    Color timeColor = isDark ? Colors.white54 : Colors.black54;
    
    if (sanskar.isCompleted) {
      timeText = l10n.completedStatus;
      timeColor = Colors.green;
    } else if (diff < 0) {
      timeText = l10n.pastDueStatus;
      timeColor = Colors.orange;
    } else if (diff == 0) {
      timeText = l10n.todayStatus;
      timeColor = AppColors.primary;
    } else {
      timeText = l10n.inDaysStatus(diff.toString());
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => SanskarDetailSheet(sanskar: sanskar, effectiveDate: date),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sanskar.isCompleted
                        ? Colors.green.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: sanskar.isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.green, size: 28)
                        : Text(sanskar.emojiIcon, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isHindi ? sanskar.sanskritName : sanskar.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sanskar.isCompleted
                              ? Colors.green.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sanskar.isCompleted ? Colors.green : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              sanskar.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
