// features/records/presentation/screens/vaccination_tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/record_model.dart';
import '../../domain/models/vaccine_schedule.dart';
import '../providers/records_provider.dart';
import '../../../auth/presentation/providers/baby_provider.dart';

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
      body: recordsAsync.when(
        data: (records) {
          // Get all logged vaccine records for this baby
          final loggedVaccines = records.where((r) => r.type == 'vaccine').toList();

          // Group standard schedule by category
          final Map<String, List<VaccineScheduleItem>> grouped = {};
          for (final item in standardVaccineSchedule) {
            grouped.putIfAbsent(item.categoryAge, () => []).add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final category = grouped.keys.elementAt(index);
              final items = grouped[category]!;
              final firstItem = items.first;
              
              final dueDate = birthDate.add(Duration(days: firstItem.recommendedDaysFromBirth));
              final isOverdue = DateTime.now().isAfter(dueDate) && firstItem.recommendedDaysFromBirth > 0;
              
              // Check how many are completed
              int completedCount = 0;
              for (final v in items) {
                if (loggedVaccines.any((r) => r.metadata['vaccineName'] == v.name)) {
                  completedCount++;
                }
              }
              final isFullyCompleted = completedCount == items.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isFullyCompleted
                                    ? Colors.green
                                    : (isOverdue ? Colors.red : Colors.grey),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFullyCompleted
                                ? Colors.green.withOpacity(0.2)
                                : AppColors.vaccine.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$completedCount / ${items.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isFullyCompleted ? Colors.green : AppColors.vaccine,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Vaccine items
                  ...items.map((vaccine) {
                    final isDone = loggedVaccines.any((r) => r.metadata['vaccineName'] == vaccine.name);
                    final loggedRecord = isDone
                        ? loggedVaccines.firstWhere((r) => r.metadata['vaccineName'] == vaccine.name)
                        : null;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      leading: Icon(
                        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isDone ? Colors.green : Colors.grey.shade400,
                        size: 28,
                      ),
                      title: Text(
                        vaccine.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vaccine.description.isNotEmpty)
                            Text(
                              vaccine.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDone ? Colors.grey : (isDark ? Colors.white70 : Colors.grey.shade700),
                              ),
                            ),
                          if (isDone && loggedRecord != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '✅ Given on ${DateFormat('MMM d, yyyy').format(loggedRecord.timestamp)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        if (isDone) {
                          // Allow viewing or deleting? For now just show a simple snackbar or dialog
                          _showEditOrDeleteDialog(context, ref, loggedRecord!, vaccine.name);
                        } else {
                          _showLogDialog(context, ref, vaccine.name, dueDate);
                        }
                      },
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showLogDialog(BuildContext context, WidgetRef ref, String vaccineName, DateTime dueDate) {
    DateTime selectedDate = DateTime.now();
    final noteController = TextEditingController();
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
                    'Log $vaccineName',
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
                      final record = RecordModel(
                        id: const Uuid().v4(),
                        type: 'vaccine',
                        timestamp: selectedDate,
                        metadata: {
                          'vaccineName': vaccineName,
                          'batchNumber': batchController.text,
                          'note': noteController.text,
                          'providedByGovt': isGovtProvided,
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
              ref.read(recordsProvider.notifier).deleteRecord(record.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
