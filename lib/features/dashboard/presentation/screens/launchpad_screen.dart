// lib/features/dashboard/presentation/screens/launchpad_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../records/presentation/providers/records_provider.dart';
import '../../../records/domain/models/record_model.dart';
import '../../../records/domain/models/vaccine_schedule.dart';
import '../../../auth/domain/models/baby_model.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../records/presentation/providers/active_session_provider.dart';
import '../../../records/presentation/widgets/timeline_tile.dart';
import '../../../settings/presentation/providers/reminder_settings_provider.dart';
import '../../../settings/domain/models/reminder_settings_model.dart';
import '../../../guide/domain/models/food_intro_record.dart';
import '../../../guide/presentation/providers/food_tracker_provider.dart';

class LaunchpadScreen extends ConsumerWidget {
  const LaunchpadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);
    final activeBaby = ref.watch(activeBabyProvider);
    final allBabies = ref.watch(allBabiesProvider);
    final filterDate = ref.watch(timelineFilterDateProvider);
    final reminderSettings = ref.watch(reminderSettingsProvider);
    final foodRecords = ref.watch(foodTrackerProvider);

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
                _buildMissedReminders(context, reminderSettings, isDark),
                _buildSummaryCard(context, recordsAsync, isDark),
                _buildUpcomingVaccineCard(context, recordsAsync, activeBaby, isDark),
                _buildUpcomingAppointmentCard(context, recordsAsync, isDark),
                _buildFoodObservationCard(context, foodRecords, isDark),
                const SizedBox(height: 32),
                _buildTimelineHeader(context, ref, filterDate, isDark),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: _buildTimelineSlivers(recordsAsync, isDark),
          ),
          const SliverPadding(
              padding: EdgeInsets.only(bottom: 120)), // Padding for bottom nav
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref,
      BabyModel? activeBaby, List<BabyModel> allBabies, bool isDark) {
    final babyName = activeBaby?.name ?? 'Baby';
    final age =
        activeBaby?.birthDate != null ? _formatAge(activeBaby!.birthDate) : '';

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
                      ? () => _showProfileSwitcherSheet(
                          context, ref, activeBaby, allBabies, isDark)
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
                          color:
                              isDark ? Colors.white54 : const Color(0xFF9A8C98),
                        ),
                      ],
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),
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
          ).animate().scale(
              duration: 600.ms, curve: Curves.easeOutBack, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildMissedReminders(BuildContext context, ReminderSettingsModel settings, bool isDark) {
    final now = DateTime.now();
    final missed = <String>[];

    void check(ReminderCategorySettings cat, String title) {
      if (cat.isEnabled && cat.nextScheduledTime != null) {
        if (now.difference(cat.nextScheduledTime!).inMinutes >= 30) {
          missed.add(title);
        }
      }
    }

    check(settings.feeding, 'Feeding');
    check(settings.sleep, 'Sleep');
    check(settings.diaper, 'Diaper');

    if (missed.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: missed.map((title) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '⚠ Missed $title Reminder',
                  style: TextStyle(
                    color: isDark ? Colors.orange[300] : Colors.orange[800], 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context,
      AsyncValue<List<RecordModel>> recordsAsync, bool isDark) {
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
              Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                  '😴', sleepMinutes == 0 ? '--' : sleepStr, 'Sleep', isDark),
              Container(
                  width: 1,
                  height: 40,
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              _buildSummaryItem('🍼', '$feedsCount times', 'Feeds', isDark),
              Container(
                  width: 1,
                  height: 40,
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              _buildSummaryItem('🩲', '$diapersCount times', 'Diapers', isDark),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildUpcomingVaccineCard(BuildContext context, AsyncValue<List<RecordModel>> recordsAsync, BabyModel? activeBaby, bool isDark) {
    if (activeBaby == null) return const SizedBox.shrink();
    
    return recordsAsync.when(
      data: (records) {
        final loggedVaccines = records.where((r) => r.type == 'vaccine').toList();
        
        VaccineScheduleItem? nextVaccine;
        DateTime? nextDueDate;
        
        for (final item in standardVaccineSchedule) {
          final isDone = loggedVaccines.any((r) => r.metadata['vaccineName'] == item.name);
          if (!isDone) {
            nextVaccine = item;
            nextDueDate = activeBaby.birthDate.add(Duration(days: item.recommendedDaysFromBirth));
            break;
          }
        }
        
        if (nextVaccine == null) return const SizedBox.shrink(); // All done!
        
        final isOverdue = DateTime.now().isAfter(nextDueDate!) && nextVaccine.recommendedDaysFromBirth > 0;
        
        return GestureDetector(
          onTap: () => context.push('/vaccines'),
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [AppColors.vaccine.withOpacity(0.3), AppColors.vaccine.withOpacity(0.1)]
                    : [AppColors.vaccine.withOpacity(0.15), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.vaccine.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.vaccine.withOpacity(isDark ? 0.1 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.vaccine.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💉', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Upcoming Vaccine',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.vaccine,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Overdue', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextVaccine.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF4A4458),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due: ${DateFormat('MMM d, yyyy').format(nextDueDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.vaccine),
              ],
            ),
          )
            .animate()
            .fadeIn(duration: 600.ms, delay: 500.ms)
            .slideY(begin: 0.05, end: 0),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildUpcomingAppointmentCard(BuildContext context, AsyncValue<List<RecordModel>> recordsAsync, bool isDark) {
    return recordsAsync.when(
      data: (records) {
        final appointments = records.where((r) => r.type == 'appointment' && r.timestamp.isAfter(DateTime.now())).toList();
        if (appointments.isEmpty) return const SizedBox.shrink();
        
        appointments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final nextAppointment = appointments.first;
        
        return GestureDetector(
          onTap: () => context.push('/appointments'),
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [const Color(0xFF6A4C93).withOpacity(0.3), const Color(0xFF6A4C93).withOpacity(0.1)]
                    : [const Color(0xFF6A4C93).withOpacity(0.15), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF6A4C93).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A4C93).withOpacity(isDark ? 0.1 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A4C93).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🩺', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming Appointment',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A4C93),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextAppointment.metadata['doctorName'] ?? 'Doctor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF4A4458),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('MMM d').format(nextAppointment.timestamp)} at ${DateFormat('h:mm a').format(nextAppointment.timestamp)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF6A4C93)),
              ],
            ),
          )
            .animate()
            .fadeIn(duration: 600.ms, delay: 500.ms)
            .slideY(begin: 0.05, end: 0),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFoodObservationCard(BuildContext context, List<FoodIntroRecord> records, bool isDark) {
    final activeRecords = records.where((r) => r.status == FoodIntroStatus.observing).toList();
    if (activeRecords.isEmpty) return const SizedBox.shrink();

    final activeRecord = activeRecords.first;
    final now = DateTime.now();
    final difference = now.difference(activeRecord.dateIntroduced).inHours;
    
    int day;
    String timeRemaining;
    double progress = 0.0;
    
    if (difference < 24) {
      day = 1;
      timeRemaining = "${24 - difference} Hours Remaining";
      progress = difference / 72;
    } else if (difference < 48) {
      day = 2;
      timeRemaining = "${48 - difference} Hours Remaining";
      progress = difference / 72;
    } else if (difference < 72) {
      day = 3;
      timeRemaining = "${72 - difference} Hours Remaining";
      progress = difference / 72;
    } else {
      day = 3;
      timeRemaining = "Observation complete.";
      progress = 1.0;
    }

    final emoji = activeRecord.foodName.toLowerCase().contains("apple") ? "🍎" : 
                  activeRecord.foodName.toLowerCase().contains("banana") ? "🍌" :
                  activeRecord.foodName.toLowerCase().contains("carrot") ? "🥕" :
                  activeRecord.foodName.toLowerCase().contains("avocado") ? "🥑" :
                  activeRecord.foodName.toLowerCase().contains("egg") ? "🥚" : "🍽️";

    return GestureDetector(
      onTap: () => context.push('/guide/food_tracker'),
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E221E) : const Color(0xFFFFF6ED),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeRecord.foodName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF4A4458),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Day $day of 3',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  timeRemaining,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      )
        .animate()
        .fadeIn(duration: 600.ms, delay: 550.ms)
        .slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildSummaryItem(
      String emoji, String value, String label, bool isDark) {
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

  Widget _buildTimelineHeader(
      BuildContext context, WidgetRef ref, DateTime? filterDate, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF4A4458),
            letterSpacing: -0.3,
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            if (filterDate != null) {
              ref.read(timelineFilterDateProvider.notifier).state = null;
              return;
            }

            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              ref.read(timelineFilterDateProvider.notifier).state = picked;
            }
          },
          icon: Icon(
              filterDate != null
                  ? Icons.close_rounded
                  : Icons.filter_list_rounded,
              size: 20),
          label: Text(filterDate != null
              ? DateFormat('MMM d').format(filterDate)
              : 'Filter Date'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor:
                filterDate != null ? AppColors.primary.withOpacity(0.1) : null,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildTimelineSlivers(
      AsyncValue<List<RecordModel>> recordsAsync, bool isDark) {
    return recordsAsync.when(
      loading: () => const SliverToBoxAdapter(
          child: Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()))),
      error: (e, _) =>
          SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
      data: (records) {
        if (records.isEmpty)
          return const SliverToBoxAdapter(child: EmptyTimelineState());

        final grouped = <String, List<RecordModel>>{};
        for (final r in records) {
          final dateKey = DateFormat('EEEE, d MMMM').format(r.timestamp);
          grouped.putIfAbsent(dateKey, () => []).add(r);
        }

        final items = <Widget>[];
        for (final entry in grouped.entries) {
          items.add(
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          );
          for (int i = 0; i < entry.value.length; i++) {
            items.add(
              TimelineTile(
                      record: entry.value[i],
                      isLast: i == entry.value.length - 1)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: (i * 100).ms)
                  .slideX(
                      begin: -0.1,
                      end: 0,
                      curve: Curves.easeOutCubic,
                      delay: (i * 100).ms),
            );
          }
        }

        return SliverList(
          delegate: SliverChildListDelegate(items),
        );
      },
    );
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
                      ref.read(activeSessionProvider.notifier).cancelSession();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color:
                      isActive ? AppColors.primary.withOpacity(0.12) : cardBg,
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatAge(baby.birthDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF9A8C98),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Active indicator
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
