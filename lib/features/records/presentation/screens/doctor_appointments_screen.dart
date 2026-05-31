import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/record_model.dart';
import '../providers/records_provider.dart';
import 'package:go_router/go_router.dart';
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

          final now = DateTime.now();
          final upcoming = appointments.where((a) => a.timestamp.isAfter(now)).toList();
          final past = appointments.where((a) => a.timestamp.isBefore(now) || a.timestamp.isAtSameMomentAs(now)).toList();

          upcoming.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          past.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              if (upcoming.isNotEmpty) ...[
                _buildHeader('Upcoming', isDark),
                ...upcoming.map((a) => _buildAppointmentCard(context, ref, a, isDark, true)),
              ],
              if (past.isNotEmpty) ...[
                _buildHeader('Past', isDark),
                ...past.map((a) => _buildAppointmentCard(context, ref, a, isDark, false)),
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

  Widget _buildAppointmentCard(BuildContext context, WidgetRef ref, RecordModel record, bool isDark, bool isUpcoming) {
    final docName = record.metadata['doctorName'] ?? 'Doctor';
    final specialization = record.metadata['specialization'] ?? '';
    final clinic = record.metadata['location'] ?? '';
    final note = record.metadata['notes'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C20) : Colors.white,
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
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirm(context, ref, record);
                      },
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
