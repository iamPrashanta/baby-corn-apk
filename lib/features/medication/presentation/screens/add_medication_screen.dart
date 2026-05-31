// lib/features/medication/presentation/screens/add_medication_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/design/components/dialogs/app_bottom_sheet.dart';
import '../providers/medication_provider.dart';
import '../../domain/models/medication_model.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../auth/presentation/providers/baby_provider.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _doseAmountController = TextEditingController(text: "1");
  final _doseUnitController = TextEditingController(text: "Tablet(s)");
  final _totalQuantityController = TextEditingController(text: "30");
  final _notesController = TextEditingController();

  String _selectedType = 'Tablet';
  String _selectedSchedule = 'OD';
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

  final List<String> _types = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Drops',
    'Injection',
    'Powder',
    'Supplement'
  ];
  final List<String> _schedules = ['OD', 'BD', 'TDS', 'QDS', 'SOS'];

  @override
  void dispose() {
    _nameController.dispose();
    _doseAmountController.dispose();
    _doseUnitController.dispose();
    _totalQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateTimesForSchedule(String schedule) {
    setState(() {
      _selectedSchedule = schedule;
      switch (schedule) {
        case 'OD':
          _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
          break;
        case 'BD':
          _selectedTimes = [
            const TimeOfDay(hour: 8, minute: 0),
            const TimeOfDay(hour: 20, minute: 0)
          ];
          break;
        case 'TDS':
          _selectedTimes = [
            const TimeOfDay(hour: 8, minute: 0),
            const TimeOfDay(hour: 14, minute: 0),
            const TimeOfDay(hour: 20, minute: 0)
          ];
          break;
        case 'QDS':
          _selectedTimes = [
            const TimeOfDay(hour: 8, minute: 0),
            const TimeOfDay(hour: 12, minute: 0),
            const TimeOfDay(hour: 16, minute: 0),
            const TimeOfDay(hour: 20, minute: 0)
          ];
          break;
        case 'SOS':
          _selectedTimes = [];
          break;
      }
    });
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (picked != null && picked != _selectedTimes[index]) {
      setState(() {
        _selectedTimes[index] = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final babyId = ref.read(activeBabyProvider)?.id;
    if (babyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active baby profile.')));
      return;
    }

    final totalQty = double.tryParse(_totalQuantityController.text) ?? 30.0;
    final doseAmt = double.tryParse(_doseAmountController.text) ?? 1.0;

    final medication = MedicationModel(
      id: const Uuid().v4(),
      babyId: babyId,
      name: _nameController.text.trim(),
      type: _selectedType,
      prescribedFor: 'Baby', // Default to baby for now
      scheduleType: _selectedSchedule,
      times: _selectedTimes.map((t) => _formatTime(t)).toList(),
      doseAmount: doseAmt,
      doseUnit: _doseUnitController.text.trim(),
      totalQuantity: totalQty,
      remainingQuantity: totalQty,
      lowStockThreshold: totalQty * 0.2, // 20%
      startDate: DateTime.now(),
      notes: _notesController.text.trim(),
    );

    ref.read(medicationsProvider.notifier).addMedication(medication);
    ReminderService.scheduleMedication(medication);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      useGlass: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Add Medication',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),

            // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name',
                      hintText: 'e.g., Vitamin D3',
                      filled: true,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Type
                  Text('Medicine Type',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _types
                        .map((type) => ChoiceChip(
                              label: Text(type),
                              selected: _selectedType == type,
                              onSelected: (s) =>
                                  setState(() => _selectedType = type),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Schedule
                  Text('Schedule',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _schedules
                        .map((sched) => ChoiceChip(
                              label: Text(sched),
                              selected: _selectedSchedule == sched,
                              onSelected: (s) => _updateTimesForSchedule(sched),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Times
                  if (_selectedSchedule != 'SOS') ...[
                    Text('Reminder Times',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...List.generate(_selectedTimes.length, (index) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: Text(_formatTime(_selectedTimes[index])),
                        trailing: TextButton(
                          onPressed: () => _selectTime(index),
                          child: const Text('Edit'),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 24),

                  // Dosage
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _doseAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Dose Amount',
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _doseUnitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit (e.g., ml, drops)',
                            filled: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stock
                  TextFormField(
                    controller: _totalQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Quantity Purchased',
                      helperText: 'For automatic stock tracking',
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      filled: true,
                    ),
                  ),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Save Medication',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
