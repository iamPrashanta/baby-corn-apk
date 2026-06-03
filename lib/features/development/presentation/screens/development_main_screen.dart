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
import '../../../../core/widgets/full_screen_image_viewer.dart';

class DevelopmentMainScreen extends ConsumerWidget {
  const DevelopmentMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(title: l10n.development),
      body: isPremium ? const _JourneyTimeline() : _buildPremiumLock(context),
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
                    borderRadius: BorderRadius.circular(16),
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

class _JourneyTimeline extends ConsumerStatefulWidget {
  const _JourneyTimeline();

  @override
  ConsumerState<_JourneyTimeline> createState() => _JourneyTimelineState();
}

class _JourneyTimelineState extends ConsumerState<_JourneyTimeline> {
  String _selectedFilter = 'All Journey';
  final List<String> _filters = ['All Journey', 'Photos Only', 'Milestones Only'];

  @override
  Widget build(BuildContext context) {
    final momentsAsync = ref.watch(momentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final standardMilestones = [
      {'emoji': '😊', 'title': l10n.firstSmile, 'subtitle': 'A heartwarming moment'},
      {'emoji': '🔄', 'title': l10n.firstRoll, 'subtitle': 'Tummy to back'},
      {'emoji': '🚼', 'title': l10n.firstCrawl, 'subtitle': 'On the move!'},
      {'emoji': '👣', 'title': l10n.firstSteps, 'subtitle': 'Walking into a new world'},
    ];

    return momentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (moments) {
        final List<Map<String, dynamic>> timelineNodes = [];

        for (var milestone in standardMilestones) {
          final title = milestone['title'] as String;
          final exists = moments.any((m) => m.title.toLowerCase() == title.toLowerCase());
          if (!exists) {
            timelineNodes.add({
              'type': 'pending_milestone',
              'emoji': milestone['emoji'],
              'title': title,
              'subtitle': milestone['subtitle'],
            });
          }
        }

        for (var moment in moments) {
          timelineNodes.add({
            'type': 'moment',
            'moment': moment,
          });
        }

        timelineNodes.sort((a, b) {
          if (a['type'] == 'pending_milestone' && b['type'] == 'moment') return -1;
          if (a['type'] == 'moment' && b['type'] == 'pending_milestone') return 1;
          if (a['type'] == 'moment' && b['type'] == 'moment') {
            final m1 = a['moment'] as MomentModel;
            final m2 = b['moment'] as MomentModel;
            return m2.timestamp.compareTo(m1.timestamp); // Newest moments first
          }
          return 0;
        });

        final filteredNodes = timelineNodes.where((node) {
          if (_selectedFilter == 'Photos Only') return node['type'] == 'moment';
          if (_selectedFilter == 'Milestones Only') return node['type'] == 'pending_milestone';
          return true; // All Journey
        }).toList();

        if (filteredNodes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌱', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text(
                  'Your Journey Begins',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Record moments and track milestones here.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
              ],
            ).animate().fadeIn(),
          );
        }

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedFilter = filter);
                      },
                      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      selectedColor: AppColors.primary.withOpacity(0.2),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 120, left: 16, right: 16),
                itemCount: filteredNodes.length,
                itemBuilder: (context, index) {
                  final node = filteredNodes[index];
                  final isFirst = index == 0;
                  final isLast = index == filteredNodes.length - 1;

                  return _TimelineNodeItem(
                    node: node,
                    isFirst: isFirst,
                    isLast: isLast,
                    isDark: isDark,
                    index: index,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimelineNodeItem extends StatelessWidget {
  final Map<String, dynamic> node;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final int index;

  const _TimelineNodeItem({
    required this.node,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = node['type'] == 'pending_milestone';
    final bool isNextUp = isFirst && isPending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line & Node indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 32,
                  color: isFirst ? Colors.transparent : (isDark ? Colors.white24 : Colors.black12),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPending ? (isNextUp ? AppColors.primary : Colors.grey) : AppColors.primary,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 4,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : (isDark ? Colors.white24 : Colors.black12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: isPending ? _buildPendingCard(context, isNextUp) : _buildMomentCard(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context, bool isNextUp) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => AddMomentSheet(initialTitle: node['title']),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: isNextUp ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: isNextUp ? AppColors.primary.withOpacity(0.2) : Colors.black.withOpacity(0.04),
              blurRadius: isNextUp ? 24 : 16,
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
                color: isNextUp ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(node['emoji'], style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isNextUp)
                    Text(
                      'Next Up',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  Text(
                    node['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    node['subtitle'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: isNextUp ? AppColors.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentCard(BuildContext context) {
    final moment = node['moment'] as MomentModel;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) {
              final file = File(moment.imagePath);
              if (!file.existsSync()) {
                return Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                );
              }
              return GestureDetector(
                onTap: () {
                  context.push('/image_viewer', extra: {
                    'imagePath': file.path,
                    'tag': moment.id,
                  });
                },
                child: Hero(
                  tag: moment.id,
                  child: Image.file(
                    file,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 250,
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                    ),
                  ),
                ),
              );
            }
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        moment.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(moment.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (moment.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    moment.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppColors.surfaceHighlight,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
