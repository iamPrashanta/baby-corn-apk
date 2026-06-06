// lib/features/development/presentation/screens/development_main_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/layouts/custom_app_bar.dart';
import '../../../settings/presentation/providers/premium_provider.dart';
import '../../../settings/presentation/screens/subscription_screen.dart';
import '../providers/moments_provider.dart';
import '../widgets/add_moment_sheet.dart';
import '../../domain/models/moment_model.dart';

class DevelopmentMainScreen extends ConsumerWidget {
  const DevelopmentMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(title: l10n.development),
      body: isPremium ? const _MomentsGallery() : _buildPremiumLock(context),
      floatingActionButton: isPremium
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddMomentSheet(),
                    );
                  },
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
                  label: Text(l10n.addMoment, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPremiumLock(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pro Feature',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Unlock the Development Journey, track milestones, and save unlimited moments with the Baby Corn Pro plan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen()),
                  );
                },
                icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
                label: const Text(
                  'Unlock for ₹99/month',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentsGallery extends ConsumerWidget {
  const _MomentsGallery();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsAsync = ref.watch(momentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final standardMilestones = [
      {'emoji': '😊', 'title': l10n.firstSmile, 'subtitle': 'A heartwarming moment'},
      {'emoji': '😄', 'title': l10n.firstLaugh, 'subtitle': 'A joyful sound'},
      {'emoji': '🔄', 'title': l10n.firstRoll, 'subtitle': 'Tummy to back'},
      {'emoji': '🪑', 'title': l10n.firstSit, 'subtitle': 'Sitting up strong'},
      {'emoji': '🚼', 'title': l10n.firstCrawl, 'subtitle': 'On the move!'},
      {'emoji': '🧍', 'title': l10n.firstStand, 'subtitle': 'Standing tall'},
      {'emoji': '👣', 'title': l10n.firstSteps, 'subtitle': 'Walking into a new world'},
      {'emoji': '🦷', 'title': l10n.firstTooth, 'subtitle': 'A little bite'},
      {'emoji': '🗣️', 'title': l10n.firstWord, 'subtitle': 'First words spoken'},
      {'emoji': '👏', 'title': l10n.firstClap, 'subtitle': 'Clapping hands'},
      {'emoji': '👋', 'title': l10n.firstWave, 'subtitle': 'Saying hello'},
      {'emoji': '🥣', 'title': l10n.firstSolidFood, 'subtitle': 'First bites'},
      {'emoji': '✂️', 'title': l10n.firstHaircut, 'subtitle': 'A fresh look'},
      {'emoji': '🎂', 'title': l10n.firstBirthday, 'subtitle': 'Happy Birthday!'},
    ];

    return momentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (moments) {
        // Find achieved milestones
        final achievedCount = standardMilestones.where((m) => 
          moments.any((moment) => moment.title.toLowerCase() == (m['title'] as String).toLowerCase())
        ).length;

        // Ensure newest photos at the top
        final sortedMoments = List<MomentModel>.from(moments)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeaderCard(context, achievedCount, sortedMoments.length, isDark),
            ),
            SliverToBoxAdapter(
              child: _buildHorizontalMilestones(context, standardMilestones, sortedMoments, isDark),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 120),
              sliver: sortedMoments.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                  : SliverToBoxAdapter(
                      child: _buildMasonryGrid(context, sortedMoments, isDark),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context, int milestones, int photos, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Milestones', value: milestones.toString()),
          Container(width: 1, height: 40, color: Colors.white24),
          _Stat(label: 'Moments', value: photos.toString()),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildHorizontalMilestones(BuildContext context, List<Map<String, String>> milestones, List<MomentModel> moments, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Milestones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final m = milestones[index];
              final title = m['title']!;
              final exists = moments.any((moment) => moment.title.toLowerCase() == title.toLowerCase());
              return _MilestoneStoryItem(
                emoji: m['emoji']!,
                title: title,
                isCompleted: exists,
                isDark: isDark,
                onTap: () {
                  if (!exists) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => AddMomentSheet(initialTitle: title),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMasonryGrid(BuildContext context, List<MomentModel> moments, bool isDark) {
    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];
    
    for (int i = 0; i < moments.length; i++) {
      if (i % 2 == 0) {
        leftColumn.add(_buildPhotoCard(context, moments[i], isDark));
      } else {
        rightColumn.add(_buildPhotoCard(context, moments[i], isDark));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          child: Text(
            'Moments Gallery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: leftColumn)),
            const SizedBox(width: 12),
            Expanded(child: Column(children: rightColumn)),
          ],
        ).animate().fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildPhotoCard(BuildContext context, MomentModel moment, bool isDark) {
    final file = File(moment.imagePath);
    return GestureDetector(
      onTap: () {
        context.push('/image_viewer', extra: {
          'imagePath': file.existsSync() ? file.path : 'placeholder',
          'tag': moment.id,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: moment.id,
              child: () {
                if (file.existsSync()) {
                  return Image.file(
                    file,
                    fit: BoxFit.cover,
                  );
                } else {
                  debugPrint('[MOMENT IMAGE MISSING] Falling back to placeholder');
                  return Image.asset(
                    'assets/images/moment_placeholder.png',
                    fit: BoxFit.cover,
                  );
                }
              }(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moment.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d').format(moment.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No Moments Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your baby\'s firsts!',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _MilestoneStoryItem extends StatelessWidget {
  final String emoji;
  final String title;
  final bool isCompleted;
  final bool isDark;
  final VoidCallback onTap;

  const _MilestoneStoryItem({
    required this.emoji,
    required this.title,
    required this.isCompleted,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.primary.withOpacity(0.1) : (isDark ? Colors.white12 : Colors.grey.shade100),
                border: Border.all(
                  color: isCompleted ? AppColors.primary : (isDark ? Colors.white24 : Colors.grey.shade300),
                  width: isCompleted ? 2.5 : 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w500,
                color: isCompleted ? (isDark ? Colors.white : AppColors.lightTextPrimary) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
