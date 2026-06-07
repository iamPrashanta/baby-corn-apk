import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/liquid_background.dart';
import '../../../../core/widgets/safe_scrollable_wrapper.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../../../core/services/reminder_service.dart';
import '../../domain/models/medication_model.dart';
import '../../../records/domain/models/record_model.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../records/presentation/providers/records_provider.dart';

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
    final logBox = HiveManager.getRecordsBox();

    // 1. Get all medications for this baby
    final babyMeds =
        medBox.values.where((m) => m.babyId == activeBaby?.id).toList();
    final babyMedIds = babyMeds.map((m) => m.id).toSet();

    // 2. Get all logs for those medications
    var logs = logBox.values
        .where((log) =>
            log.type == 'medication' &&
            babyMedIds.contains(log.metadata['medicationId']))
        .toList();

    // 3. Apply Filter
    final now = DateTime.now();
    if (_selectedFilter == 'Today') {
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      logs = logs
          .where((l) =>
              l.timestamp.isAfter(
                  startOfDay.subtract(const Duration(milliseconds: 1))) &&
              l.timestamp.isBefore(endOfDay))
          .toList();
    } else if (_selectedFilter == '7 Days') {
      final cutoff = now.subtract(const Duration(days: 7));
      logs = logs.where((l) => l.timestamp.isAfter(cutoff)).toList();
    } else if (_selectedFilter == '30 Days') {
      final cutoff = now.subtract(const Duration(days: 30));
      logs = logs.where((l) => l.timestamp.isAfter(cutoff)).toList();
    } else if (_selectedFilter == 'Custom' && _customDateRange != null) {
      final start = _customDateRange!.start;
      final end =
          _customDateRange!.end.add(const Duration(days: 1)); // Include end day
      logs = logs
          .where((l) => l.timestamp.isAfter(start) && l.timestamp.isBefore(end))
          .toList();
    }

    // 4. Sort descending by scheduled time
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Medication History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: FloatingActionButton.extended(
            onPressed: () => _showAddPastLogModal(context, babyMeds),
            icon: const Icon(Icons.add),
            label: const Text('Add Past Log'),
          ),
        ),
      ),
      body: LiquidBackground(
        child: SafeScrollableWrapper(
          useIntrinsicHeight: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        16),

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
                            filter == 'Custom' &&
                                    _customDateRange != null &&
                                    _selectedFilter == 'Custom'
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
                      final med = babyMeds.firstWhere(
                          (m) => m.id == log.metadata['medicationId']);
                      return Dismissible(
                        key: Key(log.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          await ref
                              .read(recordsProvider.notifier)
                              .deleteRecord(log.id);
                          await ReminderService.scheduleMedication(med);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Log deleted')),
                            );
                          }
                        },
                        child: _HistoryCard(log: log, medication: med),
                      );
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

  void _showAddPastLogModal(BuildContext context, List<MedicationModel> meds) {
    if (meds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No medications available. Add one first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPastLogSheet(meds: meds),
    );
  }
}

class _AddPastLogSheet extends ConsumerStatefulWidget {
  final List<MedicationModel> meds;
  const _AddPastLogSheet({required this.meds});
  @override
  ConsumerState<_AddPastLogSheet> createState() => _AddPastLogSheetState();
}

class _AddPastLogSheetState extends ConsumerState<_AddPastLogSheet> {
  late MedicationModel _selectedMed;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _selectedMed = widget.meds.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
          const Text('Log Past Dose',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Text('Medication:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          DropdownButtonFormField<MedicationModel>(
            value: _selectedMed,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: widget.meds
                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedMed = val);
            },
          ),
          const SizedBox(height: 16),
          const Text('Date & Time:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) setState(() => _selectedTime = time);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedTime.format(context)),
                        const Icon(Icons.access_time, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () async {
              final actualTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute);

              final activeBaby = ref.read(activeBabyProvider);

              final log = RecordModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: 'medication',
                timestamp: actualTime,
                metadata: {
                  'babyId': activeBaby?.id,
                  'medicationId': _selectedMed.id,
                  'medicationName': _selectedMed.name,
                  'scheduledTime': actualTime.toIso8601String(),
                  'takenTime': actualTime.toIso8601String(),
                  'status': 'taken',
                  'takenBy': 'Caregiver (Manual)',
                  'note': 'Manually added past log',
                },
              );

              ref.read(recordsProvider.notifier).addRecord(log);

              // Decrease stock
              final medBox = HiveManager.getMedicationsBox();
              final med = medBox.get(_selectedMed.id);
              if (med != null) {
                double newStock = med.remainingQuantity - med.doseAmount;
                if (newStock < 0) newStock = 0;
                medBox.put(med.id, med.copyWith(remainingQuantity: newStock));
                await ReminderService.scheduleMedication(med);
              }

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Past log added successfully')),
              );

              // Force rebuild in parent by triggering a state change if needed,
              // but recordsProvider watch should rebuild it automatically.
            },
            child: const Text('Save Past Log'),
          ),
        ],
      ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RecordModel log;
  final MedicationModel medication;

  const _HistoryCard({required this.log, required this.medication});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    final status = log.metadata['status'] as String? ?? 'unknown';

    if (status == 'taken') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'skipped') {
      statusColor = AppColors.primary;
      statusIcon = Icons.next_plan;
    } else if (status == 'missed') {
      statusColor = Colors.redAccent;
      statusIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4.0),
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
                      DateFormat('MMM d').format(log.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (log.metadata['scheduledTime'] != null &&
                    log.metadata['takenTime'] != null) ...[
                  Text(
                    'Scheduled: ${DateFormat('hh:mm a').format(DateTime.parse(log.metadata['scheduledTime']))}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    'Taken: ${DateFormat('hh:mm a').format(DateTime.parse(log.metadata['takenTime']))} • ${medication.doseAmount} ${medication.doseUnit}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ] else ...[
                  Text(
                    '${DateFormat('hh:mm a').format(log.timestamp)} • ${medication.doseAmount} ${medication.doseUnit}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                if (status == 'taken' && log.metadata['takenBy'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Given by ${log.metadata['takenBy']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
                if (log.metadata['note'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.metadata['note'],
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
