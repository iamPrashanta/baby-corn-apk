import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/liquid_background.dart';
import '../../../../core/widgets/safe_scrollable_wrapper.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../domain/models/medication_model.dart';
import '../../domain/models/medication_log_model.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../../core/design/tokens/colors.dart';

class MedicationHistoryScreen extends ConsumerStatefulWidget {
  const MedicationHistoryScreen({super.key});

  @override
  ConsumerState<MedicationHistoryScreen> createState() =>
      _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState
    extends ConsumerState<MedicationHistoryScreen> {
  String _selectedFilter = 'Today';
  DateTimeRange? _customDateRange;
  final List<String> _filters = ['Today', '7 Days', '30 Days', 'Custom'];

  @override
  Widget build(BuildContext context) {
    final activeBaby = ref.watch(activeBabyProvider);

    // Fetch and combine data
    final medBox = HiveManager.getMedicationsBox();
    final logBox = HiveManager.getMedicationLogsBox();

    // 1. Get all medications for this baby
    final babyMeds =
        medBox.values.where((m) => m.babyId == activeBaby?.id).toList();
    final babyMedIds = babyMeds.map((m) => m.id).toSet();

    // 2. Get all logs for those medications
    var logs = logBox.values
        .where((log) => babyMedIds.contains(log.medicationId))
        .toList();

    // 3. Apply Filter
    final now = DateTime.now();
    if (_selectedFilter == 'Today') {
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      logs = logs.where((l) => l.scheduledTime.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && l.scheduledTime.isBefore(endOfDay)).toList();
    } else if (_selectedFilter == '7 Days') {
      final cutoff = now.subtract(const Duration(days: 7));
      logs = logs.where((l) => l.scheduledTime.isAfter(cutoff)).toList();
    } else if (_selectedFilter == '30 Days') {
      final cutoff = now.subtract(const Duration(days: 30));
      logs = logs.where((l) => l.scheduledTime.isAfter(cutoff)).toList();
    } else if (_selectedFilter == 'Custom' && _customDateRange != null) {
      final start = _customDateRange!.start;
      final end = _customDateRange!.end.add(const Duration(days: 1)); // Include end day
      logs = logs.where((l) => l.scheduledTime.isAfter(start) && l.scheduledTime.isBefore(end)).toList();
    }

    // 4. Sort descending by scheduled time
    logs.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Medication History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SafeScrollableWrapper(
          useIntrinsicHeight: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 16),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(
                            filter == 'Custom' && _customDateRange != null && _selectedFilter == 'Custom'
                                ? '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d').format(_customDateRange!.end)}'
                                : filter,
                          ),
                          selected: isSelected,
                          onSelected: (selected) async {
                            if (filter == 'Custom') {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                initialDateRange: _customDateRange,
                              );
                              if (range != null) {
                                setState(() {
                                  _customDateRange = range;
                                  _selectedFilter = filter;
                                });
                              }
                            } else if (selected) {
                              setState(() => _selectedFilter = filter);
                            }
                          },
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.5),
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                if (logs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No history found.'),
                    ),
                  )
                else
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final med =
                          babyMeds.firstWhere((m) => m.id == log.medicationId);
                      return _HistoryCard(log: log, medication: med);
                    },
                  ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final MedicationLogModel log;
  final MedicationModel medication;

  const _HistoryCard({required this.log, required this.medication});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    if (log.status == 'taken') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (log.status == 'skipped') {
      statusColor = AppColors.primary;
      statusIcon = Icons.next_plan;
    } else if (log.status == 'missed') {
      statusColor = Colors.redAccent;
      statusIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      medication.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      DateFormat('MMM d').format(log.scheduledTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('hh:mm a').format(log.scheduledTime)} • ${medication.doseAmount} ${medication.doseUnit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (log.status == 'taken' && log.takenBy.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Given by ${log.takenBy}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
                if (log.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.note,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
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
