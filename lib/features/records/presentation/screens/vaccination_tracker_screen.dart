import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/record_model.dart';
import '../../domain/models/vaccine_schedule.dart';
import '../providers/records_provider.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../../core/services/reminder_service.dart';

enum VaccineStatus { overdue, dueToday, upcoming, completed }

class VaccineDisplayItem {
  final String name;
  final String description;
  final DateTime dueDate;
  final bool isCustom;
  final RecordModel? loggedRecord;
  final RecordModel? customPendingRecord; // the record representing the custom schedule
  final String categoryAge;

  VaccineDisplayItem({
    required this.name,
    required this.description,
    required this.dueDate,
    this.isCustom = false,
    this.loggedRecord,
    this.customPendingRecord,
    required this.categoryAge,
  });
  
  VaccineStatus get status {
    if (loggedRecord != null) return VaccineStatus.completed;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (dueDay.isBefore(today)) return VaccineStatus.overdue;
    if (dueDay.year == today.year && dueDay.month == today.month && dueDay.day == today.day) return VaccineStatus.dueToday;
    return VaccineStatus.upcoming;
  }
}

class VaccinationTrackerScreen extends ConsumerWidget {
  const VaccinationTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBaby = ref.watch(activeBabyProvider);
    final recordsAsync = ref.watch(recordsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeBaby == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vaccinations')),
        body: const Center(child: Text('No active baby profile')),
      );
    }

    final birthDate = activeBaby.birthDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccination Tracker'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Custom'),
        backgroundColor: AppColors.vaccine,
        foregroundColor: Colors.white,
      ),
      body: recordsAsync.when(
        data: (records) {
          // Filter to all vaccine records
          final vaccineRecords = records.where((r) => r.type == 'vaccine').toList();
          
          final List<VaccineDisplayItem> allItems = [];

          // 1. Process standard schedule
          for (final item in standardVaccineSchedule) {
            final dueDate = birthDate.add(Duration(days: item.recommendedDaysFromBirth));
            final isDone = vaccineRecords.any((r) => r.metadata['vaccineName'] == item.name && r.metadata['status'] != 'pending');
            final loggedRecord = isDone
                ? vaccineRecords.firstWhere((r) => r.metadata['vaccineName'] == item.name && r.metadata['status'] != 'pending')
                : null;
            
            allItems.add(VaccineDisplayItem(
              name: item.name,
              description: item.description,
              dueDate: dueDate,
              isCustom: false,
              loggedRecord: loggedRecord,
              categoryAge: item.categoryAge,
            ));
          }

          // 2. Process custom vaccines
          // A custom vaccine has metadata['isCustom'] == true
          // It can be pending (status == 'pending') or completed (status == 'completed' or null status if legacy)
          final customRecords = vaccineRecords.where((r) => r.metadata['isCustom'] == true).toList();
          
          for (final record in customRecords) {
            if (record.metadata['status'] == 'pending') {
              // It's a scheduled custom vaccine that hasn't been administered yet
              final dueDateStr = record.metadata['dueDate'];
              final dueDate = dueDateStr != null ? DateTime.parse(dueDateStr) : record.timestamp;
              allItems.add(VaccineDisplayItem(
                name: record.metadata['vaccineName'] ?? 'Custom Vaccine',
                description: record.metadata['note'] ?? 'Custom scheduled vaccine',
                dueDate: dueDate,
                isCustom: true,
                customPendingRecord: record,
                categoryAge: 'Custom',
              ));
            } else {
              // It's a completed custom vaccine
              final dueDateStr = record.metadata['dueDate'];
              final dueDate = dueDateStr != null ? DateTime.parse(dueDateStr) : record.timestamp;
              allItems.add(VaccineDisplayItem(
                name: record.metadata['vaccineName'] ?? 'Custom Vaccine',
                description: record.metadata['note'] ?? 'Custom vaccine',
                dueDate: dueDate,
                isCustom: true,
                loggedRecord: record,
                categoryAge: 'Custom',
              ));
            }
          }

          // Group by status
          final Map<VaccineStatus, List<VaccineDisplayItem>> grouped = {
            VaccineStatus.overdue: [],
            VaccineStatus.dueToday: [],
            VaccineStatus.upcoming: [],
            VaccineStatus.completed: [],
          };

          for (final item in allItems) {
            grouped[item.status]!.add(item);
          }

          // Sort within groups
          grouped[VaccineStatus.overdue]!.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          grouped[VaccineStatus.dueToday]!.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          grouped[VaccineStatus.upcoming]!.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          grouped[VaccineStatus.completed]!.sort((a, b) => b.loggedRecord!.timestamp.compareTo(a.loggedRecord!.timestamp));

          final sections = [
            if (grouped[VaccineStatus.overdue]!.isNotEmpty) _buildSection(context, 'Overdue', grouped[VaccineStatus.overdue]!, Colors.red, isDark, ref),
            if (grouped[VaccineStatus.dueToday]!.isNotEmpty) _buildSection(context, 'Due Today', grouped[VaccineStatus.dueToday]!, Colors.orange, isDark, ref),
            if (grouped[VaccineStatus.upcoming]!.isNotEmpty) _buildUpcomingSection(context, 'Upcoming', grouped[VaccineStatus.upcoming]!, AppColors.vaccine, isDark, ref),
            if (grouped[VaccineStatus.completed]!.isNotEmpty) _buildSection(context, 'Completed', grouped[VaccineStatus.completed]!, Colors.green, isDark, ref),
          ];

          if (sections.isEmpty) {
            return const Center(child: Text('No vaccines found.'));
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: sections,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<VaccineDisplayItem> items, Color accentColor, bool isDark, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C20) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0x0A000000),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(isDark ? 0.2 : 0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: items.map((item) => _buildItem(context, item, isDark, ref)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection(BuildContext context, String title, List<VaccineDisplayItem> items, Color accentColor, bool isDark, WidgetRef ref) {
    // Group by categoryAge
    final Map<String, List<VaccineDisplayItem>> groups = {};
    for (var item in items) {
      groups.putIfAbsent(item.categoryAge, () => []).add(item);
    }

    // Sort groups by the earliest dueDate in that group
    final sortedKeys = groups.keys.toList()..sort((a, b) {
      if (a == 'Custom') return 1;
      if (b == 'Custom') return -1;
      return groups[a]!.first.dueDate.compareTo(groups[b]!.first.dueDate);
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C20) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0x0A000000),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(isDark ? 0.2 : 0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...sortedKeys.map((key) {
            final groupItems = groups[key]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 16, bottom: 4),
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...groupItems.map((item) => _buildItem(context, item, isDark, ref)),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, VaccineDisplayItem item, bool isDark, WidgetRef ref) {
    final isDone = item.status == VaccineStatus.completed;
    final isOverdue = item.status == VaccineStatus.overdue;

    return InkWell(
      onTap: () {
        if (isDone) {
          _showEditOrDeleteDialog(context, ref, item.loggedRecord!, item.name);
        } else {
          _showLogDialog(context, ref, item);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? Colors.green.withOpacity(0.2) : (isDark ? Colors.white10 : Colors.grey.shade100),
                border: Border.all(
                  color: isDone ? Colors.green : (isOverdue ? Colors.red : (isDark ? Colors.white24 : Colors.grey.shade300)),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(
                isDone ? Icons.check : Icons.circle,
                size: 16,
                color: isDone ? Colors.green : Colors.transparent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDone ? Colors.grey : (isOverdue ? Colors.red : (isDark ? Colors.white : const Color(0xFF4A4458))),
                          ),
                        ),
                      ),
                      if (item.isCustom)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.vaccine.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('CUSTOM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.vaccine)),
                        )
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDone ? Colors.grey.shade400 : (isDark ? Colors.white54 : Colors.grey.shade600),
                        height: 1.3,
                      ),
                    ),
                  if (!isDone)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Due: ${DateFormat('MMM d, yyyy').format(item.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOverdue ? Colors.red : AppColors.vaccine,
                        ),
                      ),
                    ),
                  if (isDone && item.loggedRecord != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✅ Given ${DateFormat('MMM d, yyyy').format(item.loggedRecord!.timestamp)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (item.isCustom && !isDone)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeletePendingCustomDialog(context, ref, item),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomDialog(BuildContext context, WidgetRef ref) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final nameController = TextEditingController();
    final noteController = TextEditingController();
    bool enableReminder = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1C20) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Custom Vaccine',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Vaccine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date & Time Picker
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today, color: AppColors.vaccine),
                          title: const Text('Date'),
                          subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (d != null) {
                              setState(() => selectedDate = d);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time, color: AppColors.vaccine),
                          title: const Text('Time'),
                          subtitle: Text(selectedTime.format(context)),
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime,
                            );
                            if (t != null) {
                              setState(() => selectedTime = t);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Reminder'),
                    subtitle: const Text('Notify me before due date'),
                    value: enableReminder,
                    activeColor: AppColors.vaccine,
                    onChanged: (val) => setState(() => enableReminder = val),
                  ),
                  const Divider(),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vaccine,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      final id = const Uuid().v4();
                      final dueDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      
                      final record = RecordModel(
                        id: id,
                        type: 'vaccine', // store as generic vaccine
                        timestamp: dueDateTime,
                        metadata: {
                          'vaccineName': nameController.text.trim(),
                          'isCustom': true,
                          'status': 'pending',
                          'dueDate': dueDateTime.toIso8601String(),
                          'note': noteController.text.trim(),
                          'reminderEnabled': enableReminder,
                        },
                      );
                      await ref.read(recordsProvider.notifier).addRecord(record);
                      
                      if (enableReminder) {
                         final now = DateTime.now();
                         final t24h = dueDateTime.subtract(const Duration(hours: 24));
                         final t2h = dueDateTime.subtract(const Duration(hours: 2));
                         
                         final baseId = id.hashCode.abs() % 100000;
                         
                         if (t24h.isAfter(now)) {
                           await ReminderService.scheduleReminder(
                             id: baseId,
                             title: 'Upcoming Vaccine Tomorrow',
                             body: '${nameController.text.trim()} is due tomorrow at ${selectedTime.format(context)}.',
                             delay: t24h.difference(now),
                           );
                         }
                         if (t2h.isAfter(now)) {
                           await ReminderService.scheduleReminder(
                             id: baseId + 1,
                             title: 'Upcoming Vaccine',
                             body: '${nameController.text.trim()} is due in 2 hours.',
                             delay: t2h.difference(now),
                           );
                         }
                         if (dueDateTime.isAfter(now)) {
                           await ReminderService.scheduleReminder(
                             id: baseId + 2,
                             title: 'Vaccine Due Now',
                             body: '${nameController.text.trim()} is due now.',
                             delay: dueDateTime.difference(now),
                           );
                         }
                      }
                      
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Schedule Vaccine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLogDialog(BuildContext context, WidgetRef ref, VaccineDisplayItem item) {
    DateTime selectedDate = DateTime.now();
    final noteController = TextEditingController(text: item.customPendingRecord?.metadata['note'] ?? '');
    final batchController = TextEditingController();
    bool isGovtProvided = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1C20) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Log ${item.name}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  // Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: AppColors.vaccine),
                    title: const Text('Administered On'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                    trailing: TextButton(
                      child: const Text('Change'),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) {
                          setState(() => selectedDate = d);
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  
                  // Provided by Govt
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Provided by Government'),
                    subtitle: const Text('Administered at a Govt facility or program'),
                    value: isGovtProvided,
                    activeColor: AppColors.vaccine,
                    onChanged: (val) {
                      setState(() => isGovtProvided = val);
                    },
                  ),
                  const Divider(),
                  
                  // Batch Number
                  TextField(
                    controller: batchController,
                    decoration: const InputDecoration(
                      labelText: 'Batch / Lot Number (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notes
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vaccine,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (item.isCustom && item.customPendingRecord != null) {
                        // Delete the pending scheduled record first
                        ref.read(recordsProvider.notifier).deleteRecord(item.customPendingRecord!.id);
                        
                        // Cancel any pending notifications for this id
                        ReminderService.cancelReminder(item.customPendingRecord!.id.hashCode.abs() % 100000);
                      }
                      
                      final record = RecordModel(
                        id: const Uuid().v4(),
                        type: 'vaccine',
                        timestamp: selectedDate,
                        metadata: {
                          'vaccineName': item.name,
                          'batchNumber': batchController.text,
                          'note': noteController.text,
                          'providedByGovt': isGovtProvided,
                          'isCustom': item.isCustom,
                          'dueDate': item.dueDate.toIso8601String(),
                          'status': 'completed',
                        },
                      );
                      await ref.read(recordsProvider.notifier).addRecord(record);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditOrDeleteDialog(BuildContext context, WidgetRef ref, RecordModel record, String vaccineName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(vaccineName),
        content: Text('This vaccine was logged on ${DateFormat('MMM d, yyyy').format(record.timestamp)}.\n\nBatch: ${record.metadata['batchNumber'] ?? 'N/A'}\nNotes: ${record.metadata['note'] ?? 'None'}\nGovt Provided: ${record.metadata['providedByGovt'] == true ? 'Yes' : 'No'}'),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Delete Log', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (confirmCtx) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text('Are you sure you want to delete this vaccine log?'),
                  actions: [
                    TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(confirmCtx)),
                    TextButton(
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        ref.read(recordsProvider.notifier).deleteRecord(record.id);
                        Navigator.pop(confirmCtx);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDeletePendingCustomDialog(BuildContext context, WidgetRef ref, VaccineDisplayItem item) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        title: const Text('Delete Custom Vaccine'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(confirmCtx)),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              if (item.customPendingRecord != null) {
                ref.read(recordsProvider.notifier).deleteRecord(item.customPendingRecord!.id);
                final baseId = item.customPendingRecord!.id.hashCode.abs() % 100000;
                ReminderService.cancelReminder(baseId);
                ReminderService.cancelReminder(baseId + 1);
                ReminderService.cancelReminder(baseId + 2);
              }
              Navigator.pop(confirmCtx);
            },
          ),
        ],
      ),
    );
  }
}
