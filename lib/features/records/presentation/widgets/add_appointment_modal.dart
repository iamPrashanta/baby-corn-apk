import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/record_model.dart';
import '../providers/records_provider.dart';
import '../../../../core/services/reminder_service.dart';

class AddAppointmentModal extends ConsumerStatefulWidget {
  final String? initialDoctor;
  final String? initialSpecialization;
  final String? initialClinic;

  const AddAppointmentModal({
    super.key,
    this.initialDoctor,
    this.initialSpecialization,
    this.initialClinic,
  });

  @override
  ConsumerState<AddAppointmentModal> createState() => _AddAppointmentModalState();
}

class _AddAppointmentModalState extends ConsumerState<AddAppointmentModal> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  
  final _docNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _clinicController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _enableReminder = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialDoctor != null) _docNameController.text = widget.initialDoctor!;
    if (widget.initialSpecialization != null) _specializationController.text = widget.initialSpecialization!;
    if (widget.initialClinic != null) _clinicController.text = widget.initialClinic!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
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
            'Schedule Appointment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _docNameController,
            decoration: const InputDecoration(
              labelText: 'Doctor Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _specializationController,
            decoration: const InputDecoration(
              labelText: 'Specialization (e.g. Pediatrician)',
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
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF6A4C93)),
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) {
                      setState(() => _selectedDate = d);
                    }
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: Color(0xFF6A4C93)),
                  title: const Text('Time'),
                  subtitle: Text(_selectedTime.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (t != null) {
                      setState(() => _selectedTime = t);
                    }
                  },
                ),
              ),
            ],
          ),
          const Divider(),
          
          TextField(
            controller: _clinicController,
            decoration: const InputDecoration(
              labelText: 'Clinic / Location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remind Me'),
            subtitle: const Text('24 hours and 2 hours before'),
            value: _enableReminder,
            activeColor: const Color(0xFF6A4C93),
            onChanged: (val) => setState(() => _enableReminder = val),
          ),
          const Divider(),
          
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A4C93),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () async {
              if (_docNameController.text.trim().isEmpty) return;
              
              final appointmentDateTime = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );
              
              final id = const Uuid().v4();
              final record = RecordModel(
                id: id,
                type: 'appointment',
                timestamp: appointmentDateTime,
                metadata: {
                  'doctorName': _docNameController.text.trim(),
                  'specialization': _specializationController.text.trim(),
                  'location': _clinicController.text.trim(),
                  'notes': _notesController.text.trim(),
                  'reminderEnabled': _enableReminder,
                  'status': 'Upcoming',
                },
              );
              
              await ref.read(recordsProvider.notifier).addRecord(record);
              
              if (_enableReminder) {
                 final now = DateTime.now();
                 final t24h = appointmentDateTime.subtract(const Duration(hours: 24));
                 final t2h = appointmentDateTime.subtract(const Duration(hours: 2));
                 
                 final baseId = id.hashCode.abs() % 100000;
                 
                 if (t24h.isAfter(now)) {
                   await ReminderService.scheduleReminder(
                     id: baseId,
                     title: 'Doctor Appointment Tomorrow',
                     body: 'Appointment with ${_docNameController.text.trim()} at ${_selectedTime.format(context)}',
                     delay: t24h.difference(now),
                   );
                 }
                 
                 if (t2h.isAfter(now)) {
                   await ReminderService.scheduleReminder(
                     id: baseId + 1,
                     title: 'Doctor Appointment Soon',
                     body: 'Appointment with ${_docNameController.text.trim()} in 2 hours',
                     delay: t2h.difference(now),
                   );
                 }
              }
              
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Schedule Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
