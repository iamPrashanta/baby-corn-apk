import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/record_model.dart';
import '../providers/records_provider.dart';
import '../widgets/add_appointment_modal.dart';
import '../../../../core/services/reminder_service.dart';

class DoctorAppointmentsScreen extends ConsumerWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Appointments'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const AddAppointmentModal(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Schedule'),
        backgroundColor: const Color(0xFF6A4C93), // Using a distinct color for appointments
        foregroundColor: Colors.white,
      ),
      body: recordsAsync.when(
        data: (records) {
          final appointments = records.where((r) => r.type == 'appointment').toList();
          if (appointments.isEmpty) {
            return const Center(child: Text('No appointments scheduled.'));
          }

          final Map<String, List<RecordModel>> grouped = {
            'Upcoming': [],
            'Completed': [],
            'Missed': [],
            'Cancelled': [],
          };
          
          for (final a in appointments) {
            String status = a.metadata['status'] ?? '';
            if (status.isEmpty) {
               status = a.timestamp.isAfter(DateTime.now()) ? 'Upcoming' : 'Completed';
            }
            if (grouped.containsKey(status)) {
              grouped[status]!.add(a);
            } else {
              grouped['Upcoming']!.add(a);
            }
          }

          grouped['Upcoming']!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          grouped['Completed']!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          grouped['Missed']!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          grouped['Cancelled']!.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              if (grouped['Upcoming']!.isNotEmpty) ...[
                _buildHeader('Upcoming', isDark),
                ...grouped['Upcoming']!.map((a) => _buildAppointmentCard(context, ref, a, isDark, 'Upcoming')),
              ],
              if (grouped['Completed']!.isNotEmpty) ...[
                _buildHeader('Completed', isDark),
                ...grouped['Completed']!.map((a) => _buildAppointmentCard(context, ref, a, isDark, 'Completed')),
              ],
              if (grouped['Missed']!.isNotEmpty) ...[
                _buildHeader('Missed', isDark),
                ...grouped['Missed']!.map((a) => _buildAppointmentCard(context, ref, a, isDark, 'Missed')),
              ],
              if (grouped['Cancelled']!.isNotEmpty) ...[
                _buildHeader('Cancelled', isDark),
                ...grouped['Cancelled']!.map((a) => _buildAppointmentCard(context, ref, a, isDark, 'Cancelled')),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF4A4458),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, WidgetRef ref, RecordModel record, bool isDark, String currentStatus) {
    final docName = record.metadata['doctorName'] ?? 'Doctor';
    final specialization = record.metadata['specialization'] ?? '';
    final clinic = record.metadata['location'] ?? '';
    final note = record.metadata['notes'] ?? '';
    
    final isUpcoming = currentStatus == 'Upcoming';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isUpcoming ? const Color(0xFF6A4C93).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isUpcoming ? const Color(0xFF6A4C93) : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, yyyy').format(record.timestamp),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUpcoming ? const Color(0xFF6A4C93) : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isUpcoming ? const Color(0xFF6A4C93) : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(record.timestamp),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUpcoming ? const Color(0xFF6A4C93) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        docName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF4A4458),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirm(context, ref, record);
                        } else {
                          // Change status
                          final updatedMeta = Map<String, dynamic>.from(record.metadata);
                          updatedMeta['status'] = value;
                          final updatedRecord = record.copyWith(metadata: updatedMeta);
                          ref.read(recordsProvider.notifier).updateRecord(updatedRecord);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Upcoming', child: Text('Mark Upcoming')),
                        const PopupMenuItem(value: 'Completed', child: Text('Mark Completed')),
                        const PopupMenuItem(value: 'Missed', child: Text('Mark Missed')),
                        const PopupMenuItem(value: 'Cancelled', child: Text('Mark Cancelled')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
                if (specialization.isNotEmpty)
                  Text(
                    specialization,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(height: 12),
                if (clinic.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          clinic,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_alt_outlined, size: 16, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => AddAppointmentModal(
                          initialDoctor: docName,
                          initialSpecialization: specialization,
                          initialClinic: clinic,
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Create Follow-up'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6A4C93),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, RecordModel record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              ref.read(recordsProvider.notifier).deleteRecord(record.id);
              // Cancel any scheduled reminders for this appointment
              if (record.metadata['reminderEnabled'] == true) {
                 ReminderService.cancelReminder(record.id.hashCode.abs() % 100000); // 24h reminder
                 ReminderService.cancelReminder((record.id.hashCode.abs() % 100000) + 1); // 2h reminder
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
