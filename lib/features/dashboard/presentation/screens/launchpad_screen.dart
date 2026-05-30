import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../records/presentation/providers/records_provider.dart';
import '../../../records/domain/models/record_model.dart';
import '../../../auth/domain/models/baby_model.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../records/presentation/widgets/add_record_modal.dart';

import '../../../records/presentation/providers/active_session_provider.dart';

class LaunchpadScreen extends ConsumerWidget {
  const LaunchpadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);
    final activeBaby = ref.watch(activeBabyProvider);
    final allBabies = ref.watch(allBabiesProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context, ref, activeBaby, allBabies, isDark),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildSummaryCard(context, recordsAsync, isDark),
                const SizedBox(height: 48),
                _buildRecentActivitySection(context, recordsAsync, isDark),
                const SizedBox(height: 48),
                _buildQuickLogSection(context, ref, isDark),
                const SizedBox(height: 120), // Padding for bottom nav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, BabyModel? activeBaby, List<BabyModel> allBabies, bool isDark) {
    final babyName = activeBaby?.name ?? 'Baby';
    final age = activeBaby?.birthDate != null ? _formatAge(activeBaby!.birthDate) : '';

    return Container(
      padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF2A2329), Colors.transparent]
              : [const Color(0xFFFFF0ED), Colors.transparent],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF9A8C98),
                    letterSpacing: 0.3,
                  ),
                ).animate().fadeIn(duration: 600.ms),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: allBabies.length > 1
                      ? () => _showProfileSwitcherSheet(context, ref, activeBaby, allBabies, isDark)
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        babyName,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (allBabies.length > 1) ...[  
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 28,
                          color: isDark ? Colors.white54 : const Color(0xFF9A8C98),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
                if (age.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    age,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : const Color(0xFFB4A9B2),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                ]
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : const Color(0xFFFBE4E6),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Center(
              child: Text(
                activeBaby?.avatarEmoji ?? '👶',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildQuickLogSection(BuildContext context, WidgetRef ref, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                emoji: '🍼',
                label: 'Feed',
                color: AppColors.feeding,
                isDark: isDark,
                onTap: () => _logRecord(context, ref, 'feeding'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                emoji: '😴',
                label: 'Sleep',
                color: AppColors.sleep,
                isDark: isDark,
                onTap: () => _logRecord(context, ref, 'sleep'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                emoji: '🩲',
                label: 'Diaper',
                color: AppColors.diaper,
                isDark: isDark,
                onTap: () => _logRecord(context, ref, 'diaper'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSummaryCard(BuildContext context, AsyncValue<List<RecordModel>> recordsAsync, bool isDark) {
    int sleepMinutes = 0;
    int feedsCount = 0;
    int diapersCount = 0;

    final now = DateTime.now();

    recordsAsync.whenData((records) {
      for (final r in records) {
        if (r.timestamp.year == now.year &&
            r.timestamp.month == now.month &&
            r.timestamp.day == now.day) {
          final type = r.type.toLowerCase();
          if (type.contains('sleep')) {
             final dur = r.metadata['durationSeconds'];
             final min = r.metadata['durationMinutes'];
             if (dur != null) {
               sleepMinutes += (dur as int) ~/ 60;
             } else if (min != null) {
               sleepMinutes += min as int;
             }
          } else if (type.contains('feed')) {
             feedsCount++;
          } else if (type == 'diaper') {
             diapersCount++;
          }
        }
      }
    });

    final sleepStr = sleepMinutes >= 60 
        ? '${sleepMinutes ~/ 60}h ${sleepMinutes % 60}m'
        : '${sleepMinutes}m';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C20) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : const Color(0x08000000),
            blurRadius: 32,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Overview",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF4A4458),
                ),
              ),
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('😴', sleepMinutes == 0 ? '--' : sleepStr, 'Sleep', isDark),
              Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              _buildSummaryItem('🍼', '$feedsCount times', 'Feeds', isDark),
              Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              _buildSummaryItem('🩲', '$diapersCount times', 'Diapers', isDark),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSummaryItem(String emoji, String value, String label, bool isDark) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : const Color(0xFFB4A9B2),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, AsyncValue<List<RecordModel>> recordsAsync, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF4A4458),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 20),
        recordsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          error: (e, _) => const SizedBox.shrink(),
          data: (records) {
            if (records.isEmpty) return _EmptyRecentState();
            final recent = records.take(4).toList();
            return Column(
              children: recent.asMap().entries.map((entry) {
                return _RecentTile(record: entry.value, isDark: isDark)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (500 + (entry.key * 100)).ms)
                    .slideY(begin: 0.05, end: 0);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _logRecord(BuildContext context, WidgetRef ref, String initialType) async {
    if (initialType == 'sleep' || initialType == 'feeding') {
      // Removed forced permission request.
      // The user can optionally enable the overlay from Settings.
      // Instantly start the timer globally
      ref.read(activeSessionProvider.notifier).startSession(initialType);
    } else if (initialType == 'diaper') {
      context.push('/entry/diaper?status=Mixed');
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddRecordModal(initialType: initialType),
      );
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Up late? 🌙';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night 🌙';
  }

  String _formatAge(DateTime birthDate) {
    final now = DateTime.now();
    final diff = now.difference(birthDate);
    final days = diff.inDays;
    if (days < 7) return '$days days old';
    if (days < 30) return '${(days / 7).floor()} weeks old';
    final months = (days / 30.44).floor();
    return '$months months old';
  }

  void _showProfileSwitcherSheet(
    BuildContext context,
    WidgetRef ref,
    BabyModel? activeBaby,
    List<BabyModel> allBabies,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _ProfileSwitcherSheet(
        allBabies: allBabies,
        activeBaby: activeBaby,
        isDark: isDark,
        onSelect: (baby) async {
          Navigator.of(sheetContext).pop();
          if (baby.id == activeBaby?.id) return;
          final activeSession = ref.read(activeSessionProvider);
          if (activeSession != null && activeSession.isRunning) {
            final result = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: const Text('Timer Running'),
                content: const Text(
                    'Stop the active timer before switching profiles.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(activeSessionProvider.notifier)
                          .cancelSession();
                      Navigator.pop(ctx, true);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Stop Timer',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (result != true) return;
          }
          ref.read(activeBabyProvider.notifier).setActiveBaby(baby.id);
        },
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? widget.color.withOpacity(0.15) : widget.color.withOpacity(0.12);
    
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white : widget.color.withOpacity(0.8).withBlue(100), // Darken slightly for text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final RecordModel record;
  final bool isDark;
  const _RecentTile({required this.record, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (icon, label, subtitle, color) = _recordMeta(record);
    final timeStr = DateFormat.jm().format(record.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C20) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF9A8C98), fontSize: 13),
                  ),
                ]
              ],
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              color: isDark ? Colors.white38 : const Color(0xFFB4A9B2),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (String, String, String, Color) _recordMeta(RecordModel r) {
    switch (r.type.toLowerCase()) {
      case 'left feeding':
      case 'right feeding':
      case 'feeding':
        final method = r.metadata['side'] ?? r.metadata['method'] ?? 'Feeding';
        final dur = r.metadata['durationSeconds'];
        final durMin = dur != null ? (dur as int) ~/ 60 : r.metadata['duration'];
        return ('🍼', 'Feeding', durMin != null && durMin > 0 ? '$method • ${durMin}m' : '$method', AppColors.feeding);
      case 'sleep':
        final durSec = r.metadata['durationSeconds'];
        final durMin = durSec != null ? (durSec as int) ~/ 60 : r.metadata['durationMinutes'];
        return ('😴', 'Sleep', durMin != null && durMin > 0 ? '${durMin} mins' : 'Sleep logged', AppColors.sleep);
      case 'tummy_time':
      case 'tummy time':
        final dur = r.metadata['durationSeconds'];
        final durMin = dur != null ? (dur as int) ~/ 60 : null;
        return ('🤸', 'Tummy Time', durMin != null && durMin > 0 ? '${durMin} mins' : '', AppColors.tertiary);
      case 'diaper':
        final status = r.metadata['status'] as String? ?? 'Diaper changed';
        if (status == 'Wet') {
          return ('💦', 'Urination', 'Wet diaper', AppColors.urination);
        } else if (status == 'Dirty') {
          return ('💩', 'Stool', 'Dirty diaper', AppColors.stool);
        } else if (status == 'Mixed') {
          return ('🩲', 'Diaper', 'Mixed diaper', AppColors.diaper);
        }
        return ('🩲', 'Diaper', status, AppColors.diaper);
      case 'bath':
        final type = r.metadata['type'] as String? ?? 'Bath';
        final hair = r.metadata['hairWashed'] == true ? 'Hair washed' : '';
        final lotion = r.metadata['lotionApplied'] == true ? 'Lotion applied' : '';
        final parts = [if(hair.isNotEmpty) hair, if(lotion.isNotEmpty) lotion].join(' • ');
        return ('🛁', type, parts.isNotEmpty ? parts : 'Bath logged', Colors.lightBlue);
      default:
        return ('📝', 'Activity', '', AppColors.primary);
    }
  }
}

class _EmptyRecentState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          const Text(
            'A quiet day',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing logged yet today.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Switcher Bottom Sheet ────────────────────────────────────────────

class _ProfileSwitcherSheet extends StatelessWidget {
  final List<BabyModel> allBabies;
  final BabyModel? activeBaby;
  final bool isDark;
  final ValueChanged<BabyModel> onSelect;

  const _ProfileSwitcherSheet({
    required this.allBabies,
    required this.activeBaby,
    required this.isDark,
    required this.onSelect,
  });

  String _formatAge(DateTime birthDate) {
    final days = DateTime.now().difference(birthDate).inDays;
    if (days < 7) return '$days days old';
    if (days < 30) return '${(days / 7).floor()} weeks old';
    final months = (days / 30.44).floor();
    if (months < 24) return '$months months old';
    return '${(months / 12).floor()} years old';
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF252229) : Colors.white;

    return AppBottomSheet(
      child: Column(
        children: [
          // Title
          Text(
            'Switch Baby',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 20),

          // Baby cards
          ...allBabies.map((baby) {
            final isActive = baby.id == activeBaby?.id;
            return GestureDetector(
              onTap: () => onSelect(baby),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withOpacity(0.12)
                      : cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          baby.avatarEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            baby.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatAge(baby.birthDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : const Color(0xFF9A8C98),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Active indicator
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 4),

          // Add baby shortcut
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              context.push('/onboarding?add=true');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: isDark ? Colors.white54 : Colors.black38,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Another Baby',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
