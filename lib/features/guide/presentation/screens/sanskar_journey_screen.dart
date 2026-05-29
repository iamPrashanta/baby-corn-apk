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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroHeader(context, completedCount, total, isDark),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sanskar = sortedSanskars[index];
                  final effectiveDate = SanskarDateEngine.getEffectiveDate(sanskar, birthDate);
                  return _buildTimelineCard(context, ref, sanskar, effectiveDate, index, isDark)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                      .slideY(begin: 0.1, end: 0);
                },
                childCount: sortedSanskars.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)), // Bottom nav padding
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, int completed, int total, bool isDark) {
    final double progress = total == 0 ? 0 : completed / total;

    return Container(
      padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF2A2329), Colors.transparent]
              : [const Color(0xFFFFF0ED), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            child: const Center(child: Text('🪔', style: TextStyle(fontSize: 40))),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'Spiritual Journey',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 8),
          Text(
            'A beautiful path of traditional milestones',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white70 : const Color(0xFF9A8C98),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1C20) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Milestones', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                    Text('$completed of $total', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                )
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, WidgetRef ref, SanskarModel sanskar, DateTime date, int index, bool isDark) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    
    String timeText;
    Color timeColor = isDark ? Colors.white54 : Colors.black54;
    
    if (sanskar.isCompleted) {
      timeText = 'Completed';
      timeColor = Colors.green;
    } else if (diff < 0) {
      timeText = 'Past due (${diff.abs()} days ago)';
      timeColor = Colors.orange;
    } else if (diff == 0) {
      timeText = 'Today!';
      timeColor = AppColors.primary;
    } else {
      timeText = 'In $diff days';
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
          color: isDark ? const Color(0xFF1E1C20) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: sanskar.isCompleted ? Colors.green.withOpacity(0.3) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black12 : Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: sanskar.isCompleted 
                    ? Colors.green.withOpacity(0.1) 
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
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
                          sanskar.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(date),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sanskar.sanskritName,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: timeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
