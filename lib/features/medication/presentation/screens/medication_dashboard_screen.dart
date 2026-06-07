// lib/features/medication/presentation/screens/medication_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/liquid_background.dart';
import '../../../../core/widgets/safe_scrollable_wrapper.dart';
import '../providers/medication_provider.dart';
import '../widgets/medication_card.dart';
import 'add_medication_screen.dart';
import '../../domain/models/medication_model.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/notification_service.dart';
import 'package:intl/intl.dart';
import '../../../records/presentation/providers/records_provider.dart';

class MedicationDashboardScreen extends ConsumerWidget {
  const MedicationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider);
    ref.watch(recordsProvider); // Ensure timeline rebuilds immediately on any log changes

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Medications'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Active'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                context.push('/medicine/history');
              },
              tooltip: 'Medication History',
            ),
          ],
        ),
        floatingActionButton: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => const AddMedicationScreen(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine'),
            ),
          ),
        ),
        body: LiquidBackground(
          child: medicationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (medications) {
              final activeMeds = medications.where((m) => m.isActive).toList();
              final lowStockMeds = activeMeds
                  .where((m) => m.remainingQuantity <= m.lowStockThreshold)
                  .toList();

              // Check for Missed Doses Today across all logs
              final allLogs = HiveManager.getRecordsBox().values.where((r) => r.type == 'medication');
              final today = DateTime.now();
              final missedCount = allLogs.where((log) {
                if (log.metadata['status'] != 'missed') return false;
                final stStr = log.metadata['scheduledTime'];
                if (stStr == null) return false;
                final st = DateTime.parse(stStr);
                return st.year == today.year &&
                    st.month == today.month &&
                    st.day == today.day;
              }).length;

              final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 48 + 24;
              final bottomPadding = MediaQuery.of(context).padding.bottom + 100;

              return TabBarView(
                children: [
                  // TAB 1: Pending Doses
                  SafeScrollableWrapper(
                    applySafeArea: false,
                    useIntrinsicHeight: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: topPadding),
                          if (missedCount > 0) ...[
                            _buildMissedDosesBanner(context, missedCount),
                            const SizedBox(height: 24),
                          ],
                          _buildTimeline(context, ref, activeMeds),
                          SizedBox(height: bottomPadding),
                        ],
                      ),
                    ),
                  ),

                  // TAB 2: Active Medications & Summary
                  SafeScrollableWrapper(
                    applySafeArea: false,
                    useIntrinsicHeight: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: topPadding),
                          // Summary Section
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  title: 'Active',
                                  value: activeMeds.length.toString(),
                                  icon: Icons.medication,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _SummaryCard(
                                  title: 'Low Stock',
                                  value: lowStockMeds.length.toString(),
                                  icon: Icons.warning_amber_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (lowStockMeds.isNotEmpty) ...[
                            _buildLowStockSection(context, lowStockMeds),
                            const SizedBox(height: 24),
                          ],
                          if (activeMeds.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('No active medications.'),
                              ),
                            )
                          else
                            ListView.separated(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: activeMeds.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final med = activeMeds[index];
                                return MedicationCard(
                                  medication: med,
                                  onTap: () {
                                    // Navigate to detail screen
                                  },
                                  onEdit: () {
                                    _handleEdit(context, med);
                                  },
                                  onDelete: () {
                                    _handleDelete(context, ref, med);
                                  },
                                  onViewHistory: () {
                                    context.push('/medicine/history');
                                  },
                                );
                              },
                            ),
                          SizedBox(height: bottomPadding),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMissedDosesBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Missed Dose${count > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Please review today\'s timeline.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockSection(
      BuildContext context, List<MedicationModel> lowStockMeds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Running Low',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 12),
        ...lowStockMeds.map((med) {
          int? daysRemaining;
          if (med.times.isNotEmpty && med.doseAmount > 0) {
            final dailyConsumption = med.times.length * med.doseAmount;
            daysRemaining = (med.remainingQuantity / dailyConsumption).floor();
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        '${med.remainingQuantity} ${med.doseUnit} remaining${daysRemaining != null ? ' (≈ $daysRemaining days left)' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    // Placeholder for future e-commerce / refill feature
                  },
                  icon: const Icon(Icons.shopping_cart, size: 16),
                  label: const Text('Buy Soon'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    foregroundColor: AppColors.primary,
                  ),
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimeline(
      BuildContext context, WidgetRef ref, List<MedicationModel> meds) {
    final List<Map<String, dynamic>> pendingDoses = [];
    final List<Map<String, dynamic>> activityDoses = [];
    final now = DateTime.now();

    for (final med in meds) {
      final List<Map<String, dynamic>> expectedDoses = [];
      
      for (final timeStr in med.times) {
        final parts = timeStr.split(' ');
        if (parts.length != 2) {
          continue;
        }
        final timeParts = parts[0].split(':');
        int hour = int.tryParse(timeParts[0]) ?? 8;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        if (parts[1].toUpperCase() == 'PM' && hour != 12) {
          hour += 12;
        } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }

        String period = 'Night';
        if (hour >= 6 && hour < 12) {
          period = 'Morning';
        } else if (hour >= 12 && hour < 17) {
          period = 'Afternoon';
        } else if (hour >= 17 && hour < 21) {
          period = 'Evening';
        }

        expectedDoses.add({
          'med': med,
          'timeStr': timeStr,
          'hour': hour,
          'minute': minute,
          'period': period,
          'status': 'Pending',
        });
      }

      expectedDoses.sort((a, b) {
        int cmp = (a['hour'] as int).compareTo(b['hour'] as int);
        if (cmp == 0) cmp = (a['minute'] as int).compareTo(b['minute'] as int);
        return cmp;
      });

      // Match against today's logs chronologically
      final logs = HiveManager.getRecordsBox().values.where((log) {
          if (log.type != 'medication') return false;
          if (log.metadata['medicationId'] != med.id) return false;
          final ts = log.timestamp;
          return ts.year == now.year && ts.month == now.month && ts.day == now.day && 
                 (log.metadata['status'] == 'taken' || log.metadata['status'] == 'missed' || log.metadata['status'] == 'skipped');
      }).toList();
      
      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      int takenCount = 0;
      for (var dose in expectedDoses) {
        final expectedTime = DateTime(now.year, now.month, now.day, dose['hour'] as int, dose['minute'] as int);
        
        // Find matching log primarily by exact scheduledTime, fallback to chronological if no scheduledTime exists
        dynamic matchingLog;
        try {
          matchingLog = logs.firstWhere((log) {
            final scheduledStr = log.metadata['scheduledTime'] as String?;
            if (scheduledStr != null) {
              final scheduledTime = DateTime.parse(scheduledStr);
              return scheduledTime.hour == expectedTime.hour && scheduledTime.minute == expectedTime.minute;
            }
            return false;
          });
        } catch (_) {
          matchingLog = null;
        }

        // Backward compatibility fallback for older logs
        if (matchingLog == null && takenCount < logs.length) {
          final unassignedLogs = logs.where((l) => l.metadata['scheduledTime'] == null).toList();
          if (unassignedLogs.isNotEmpty && takenCount < unassignedLogs.length) {
             matchingLog = unassignedLogs[takenCount];
          }
        }

        if (matchingLog != null) {
          final logStatus = matchingLog.metadata['status'];
          dose['status'] = logStatus == 'taken' ? 'Taken' 
                         : logStatus == 'skipped' ? 'Skipped' 
                         : 'Missed_Log';
          takenCount++;
        }
      }

      for (var dose in expectedDoses) {
         if (dose['status'] == 'Pending') {
            int h = dose['hour'];
            int m = dose['minute'];
            if (now.hour > h || (now.hour == h && now.minute > m + 30)) {
               dose['status'] = 'Missed';
            }
         }
      }

      int expected = expectedDoses.length;
      int pendingCount = expectedDoses.where((d) => d['status'] == 'Pending' || d['status'] == 'Missed').length;
      debugPrint('[PENDING RECALCULATED] expected=$expected taken=$takenCount pending=$pendingCount for med ${med.name}');
      debugPrint('[PENDING MATCHING] scheduled=$expected logs=${logs.length} matched=$takenCount remaining=${expected - takenCount}');

      for (var dose in expectedDoses) {
        if (dose['status'] == 'Pending' || dose['status'] == 'Missed') {
          pendingDoses.add(dose);
        } else {
          activityDoses.add(dose);
        }
      }
    }

    if (pendingDoses.isEmpty && activityDoses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No doses scheduled for today.'),
      );
    }

    pendingDoses.sort((a, b) {
      int cmp = (a['hour'] as int).compareTo(b['hour'] as int);
      if (cmp == 0) cmp = (a['minute'] as int).compareTo(b['minute'] as int);
      return cmp;
    });

    activityDoses.sort((a, b) {
      int cmp = (a['hour'] as int).compareTo(b['hour'] as int);
      if (cmp == 0) cmp = (a['minute'] as int).compareTo(b['minute'] as int);
      return cmp;
    });

    final pendingGrouped = <String, List<Map<String, dynamic>>>{
      'Morning': [], 'Afternoon': [], 'Evening': [], 'Night': [],
    };
    for (final dose in pendingDoses) {
      pendingGrouped[dose['period'] as String]!.add(dose);
    }

    final activityGrouped = <String, List<Map<String, dynamic>>>{
      'Morning': [], 'Afternoon': [], 'Evening': [], 'Night': [],
    };
    for (final dose in activityDoses) {
      activityGrouped[dose['period'] as String]!.add(dose);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pendingDoses.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text('Pending Doses (${pendingDoses.length})', 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          ...pendingGrouped.entries.where((e) => e.value.isNotEmpty).map((entry) {
            return _buildTimelinePeriod(context, ref, entry.key, entry.value, isActivity: false);
          }),
        ],
        if (activityDoses.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text('Today\'s Activity', 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          ...activityGrouped.entries.where((e) => e.value.isNotEmpty).map((entry) {
            return _buildTimelinePeriod(context, ref, entry.key, entry.value, isActivity: true);
          }),
        ],
      ],
    );
  }

  Widget _buildTimelinePeriod(
      BuildContext context, WidgetRef ref, String period, List<Map<String, dynamic>> doses, {bool isActivity = false}) {
    IconData periodIcon = Icons.nightlight_round;
    Color periodColor = Colors.indigo;
    if (period == 'Morning') {
      periodIcon = Icons.wb_sunny;
      periodColor = AppColors.primary;
    } else if (period == 'Afternoon') {
      periodIcon = Icons.wb_cloudy;
      periodColor = Colors.lightBlue;
    } else if (period == 'Evening') {
      periodIcon = Icons.brightness_3;
      periodColor = Colors.deepPurpleAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(periodIcon, color: periodColor, size: 20),
              const SizedBox(width: 8),
              Text(
                period,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: periodColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...doses.map((dose) {
            final med = dose['med'] as MedicationModel;
            final status = dose['status'] as String;

            Color statusColor = Colors.grey;
            IconData statusIcon = Icons.schedule;

            if (status == 'Taken') {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
            } else if (status == 'Missed' || status == 'Missed_Log') {
              statusColor = Colors.redAccent;
              statusIcon = Icons.cancel;
            } else if (status == 'Skipped') {
              statusColor = AppColors.primary;
              statusIcon = Icons.next_plan;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8, left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(4.0),
                border: Border(left: BorderSide(color: statusColor, width: 4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              med.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (status == 'Missed') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: const Text(
                                  'Late',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${dose['timeStr']} • ${med.doseAmount} ${med.doseUnit}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (status == 'Taken')
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: Colors.green.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.green.withOpacity(0.5)),
                       ),
                       child: const Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(Icons.check_circle, color: Colors.green, size: 14),
                           SizedBox(width: 4),
                           Text('Taken', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     )
                  else if (status == 'Pending' || status == 'Missed')
                     Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         IconButton(
                           icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                           onPressed: () {
                              _handleTakeDose(context, ref, med);
                           },
                           tooltip: 'Mark Taken',
                         ),
                         IconButton(
                           icon: const Icon(Icons.snooze, color: Colors.orange),
                           onPressed: () {
                              _handleSnooze(context, med, dose);
                           },
                           tooltip: 'Snooze 10 min',
                         ),
                         IconButton(
                           icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                           onPressed: () {
                              _handleMissDose(context, ref, med);
                           },
                           tooltip: 'Mark Missed',
                         ),
                       ],
                     ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _handleSnooze(BuildContext context, MedicationModel med, Map<String, dynamic> dose) {
    final notificationId = Object.hash(med.id, 'snooze', DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF;
    ReminderService.scheduleReminder(
      id: notificationId,
      title: 'Snoozed: ${med.name}',
      body: 'Time to take your snoozed medication.',
      delay: const Duration(minutes: 10),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${med.name} snoozed for 10 minutes.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMissDose(BuildContext context, WidgetRef ref, MedicationModel med) async {
    await ref.read(medicationsProvider.notifier).missDose(med);
    await ReminderService.scheduleMedication(med);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dose recorded as missed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleEdit(BuildContext context, MedicationModel med) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      routeSettings: RouteSettings(arguments: med),
      builder: (context) => const AddMedicationScreen(),
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref, MedicationModel med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ReminderService.cancelMedication(med);
              debugPrint('[SCHEDULES REMOVED] Cancelled all reminders for med ${med.id}');
              
              ref.read(medicationsProvider.notifier).deleteMedication(med.id);
              debugPrint('[MEDICATION DELETED] Deleted med ${med.id}');
              
              if (context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medication deleted.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTakeDose(
      BuildContext context, WidgetRef ref, MedicationModel med) async {
    
    TimeOfDay selectedTime = TimeOfDay.now();
    
    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const Text(
                    'Dose Taken',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text('Taken At:', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedTime.format(ctx), style: const TextStyle(fontSize: 16)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ),
            );
          }
        );
      }
    );

    if (confirmed != true) return;

    final now = DateTime.now();
    final actualDateTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);

    // We delegate the heavy lifting to the provider which logs it and reduces stock
    final logId = await ref.read(medicationsProvider.notifier).takeDose(med, actualTime: actualDateTime);

    if (!context.mounted) return;

    if (logId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dose recorded as taken.'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              await ref.read(medicationsProvider.notifier).undoDose(med, logId);
              await ReminderService.scheduleMedication(med);
            },
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Calculate next pending dose for notification
    await ReminderService.scheduleMedication(med);
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
