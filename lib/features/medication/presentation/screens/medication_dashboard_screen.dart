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

class MedicationDashboardScreen extends ConsumerWidget {
  const MedicationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Medications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicationScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      body: LiquidBackground(
        child: SafeScrollableWrapper(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 120),

                // Summary Section
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Active',
                        value: medicationsAsync.maybeWhen(
                          data: (meds) =>
                              meds.where((m) => m.isActive).length.toString(),
                          orElse: () => '-',
                        ),
                        icon: Icons.medication,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Low Stock',
                        value: medicationsAsync.maybeWhen(
                          data: (meds) => meds
                              .where((m) =>
                                  m.isActive &&
                                  m.remainingQuantity <= m.lowStockThreshold)
                              .length
                              .toString(),
                          orElse: () => '-',
                        ),
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                medicationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (medications) {
                    final activeMeds =
                        medications.where((m) => m.isActive).toList();
                    final lowStockMeds = activeMeds
                        .where(
                            (m) => m.remainingQuantity <= m.lowStockThreshold)
                        .toList();

                    // Check for Missed Doses Today across all logs
                    final allLogs = HiveManager.getMedicationLogsBox().values;
                    final today = DateTime.now();
                    final missedCount = allLogs
                        .where((log) =>
                            log.status == 'missed' &&
                            log.scheduledTime.year == today.year &&
                            log.scheduledTime.month == today.month &&
                            log.scheduledTime.day == today.day)
                        .length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (missedCount > 0) ...[
                          _buildMissedDosesBanner(context, missedCount),
                          const SizedBox(height: 24),
                        ],
                        if (lowStockMeds.isNotEmpty) ...[
                          _buildLowStockSection(context, lowStockMeds),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          "Today's Timeline",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        _buildTimeline(context, activeMeds),
                        const SizedBox(height: 32),
                        Text(
                          'Active Medications',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final med = activeMeds[index];
                              return MedicationCard(
                                medication: med,
                                onTap: () {
                                  // TODO: Navigate to detail screen
                                },
                                onTakeDose: () {
                                  _handleTakeDose(context, ref, med);
                                },
                                onDuplicate: () {
                                  _handleDuplicate(context, med);
                                },
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 100), // Space for FAB
              ],
            ),
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
        borderRadius: BorderRadius.circular(16),
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
                color: Colors.orangeAccent,
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
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
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
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                    foregroundColor: Colors.orangeAccent,
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context, List<MedicationModel> meds) {
    // Generate a list of all doses for today
    final List<Map<String, dynamic>> todayDoses = [];
    final now = DateTime.now();

    for (final med in meds) {
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

        // Check if taken/missed by looking at logs
        final logs = HiveManager.getMedicationLogsBox().values.where((log) =>
            log.medicationId == med.id &&
            log.scheduledTime.year == now.year &&
            log.scheduledTime.month == now.month &&
            log.scheduledTime.day == now.day &&
            log.scheduledTime.hour == hour &&
            log.scheduledTime.minute == minute);

        String status = 'Pending';
        if (logs.isNotEmpty) {
          status = logs.first.status == 'taken'
              ? 'Taken'
              : logs.first.status == 'skipped'
                  ? 'Skipped'
                  : 'Missed';
        } else if (now.hour > hour ||
            (now.hour == hour && now.minute > minute + 30)) {
          status = 'Missed'; // Safety fallback visually
        }

        todayDoses.add({
          'med': med,
          'timeStr': timeStr,
          'hour': hour,
          'minute': minute,
          'period': period,
          'status': status,
        });
      }
    }

    if (todayDoses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No doses scheduled for today.'),
      );
    }

    todayDoses.sort((a, b) {
      int cmp = (a['hour'] as int).compareTo(b['hour'] as int);
      if (cmp == 0) cmp = (a['minute'] as int).compareTo(b['minute'] as int);
      return cmp;
    });

    final grouped = <String, List<Map<String, dynamic>>>{
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
      'Night': [],
    };

    for (final dose in todayDoses) {
      grouped[dose['period'] as String]!.add(dose);
    }

    return Column(
      children: grouped.entries.where((e) => e.value.isNotEmpty).map((entry) {
        return _buildTimelinePeriod(context, entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildTimelinePeriod(
      BuildContext context, String period, List<Map<String, dynamic>> doses) {
    IconData periodIcon = Icons.nightlight_round;
    Color periodColor = Colors.indigo;
    if (period == 'Morning') {
      periodIcon = Icons.wb_sunny;
      periodColor = Colors.amber;
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
            } else if (status == 'Missed') {
              statusColor = Colors.redAccent;
              statusIcon = Icons.cancel;
            } else if (status == 'Skipped') {
              statusColor = Colors.orange;
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
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: statusColor, width: 4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _handleDuplicate(BuildContext context, MedicationModel med) {
    // Navigate to AddMedicationScreen, ideally passing the med data via state/args
    // Since we don't have a structured duplicate route setup, we will just push it manually
    // For now we'll push empty Add screen. In a full implementation we'd pass the `med` object.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicationScreen(),
        settings: RouteSettings(
            arguments: med), // AddMedicationScreen can extract this
      ),
    );
  }

  void _handleTakeDose(
      BuildContext context, WidgetRef ref, MedicationModel med) {
    // We delegate the heavy lifting to the provider which logs it and reduces stock
    ref.read(medicationsProvider.notifier).takeDose(med);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dose recorded as taken!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        borderRadius: BorderRadius.circular(20),
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
