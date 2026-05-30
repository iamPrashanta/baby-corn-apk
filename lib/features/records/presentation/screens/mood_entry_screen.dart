// features/records/presentation/screens/mood_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../../domain/models/record_model.dart';
import '../../../../core/constants/app_colors.dart';

class MoodEntryScreen extends ConsumerStatefulWidget {
  const MoodEntryScreen({super.key});

  @override
  ConsumerState<MoodEntryScreen> createState() => _MoodEntryScreenState();
}

class _MoodEntryScreenState extends ConsumerState<MoodEntryScreen> {
  String _selectedMood = 'Happy';
  String _intensity = 'Moderate';
  DateTime _timestamp = DateTime.now();
  final _noteController = TextEditingController();

  final Map<String, String> _moodMap = {
    'Happy': '😊',
    'Okay': '😐',
    'Sad': '😢',
    'Angry': '😠',
    'Weepy': '😭',
    'Anxious': '😟',
    'Fussy': '😖',
    'Sleepy': '😴',
    'Excited': '🤩',
  };

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time == null || !mounted) return;

    setState(() {
      _timestamp = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _save() async {
    final record = RecordModel(
      id: const Uuid().v4(),
      type: 'mood',
      timestamp: _timestamp,
      metadata: {
        'mood': _selectedMood,
        'emoji': _moodMap[_selectedMood],
        'intensity': _intensity,
        'note': _noteController.text,
      },
    );
    
    await ref.read(recordsProvider.notifier).addRecord(record);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Mood')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.mood.withOpacity(isDark ? 0.2 : 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time, color: Colors.green),
            ),
            title: const Text('Time', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(DateFormat('MMM d, yyyy - h:mm a').format(_timestamp)),
            trailing: TextButton(
              onPressed: _pickDateTime,
              child: const Text('Change'),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'How is baby feeling?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _moodMap.entries.map((e) {
              final isSelected = _selectedMood == e.key;
              return ChoiceChip(
                label: Text('${e.value}  ${e.key}'),
                selected: isSelected,
                selectedColor: AppColors.mood.withOpacity(isDark ? 0.4 : 0.8),
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                onSelected: (val) {
                  if (val) setState(() => _selectedMood = e.key);
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          const Text(
            'Intensity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Mild', label: Text('Mild')),
              ButtonSegment(value: 'Moderate', label: Text('Moderate')),
              ButtonSegment(value: 'Severe', label: Text('Severe')),
            ],
            selected: {_intensity},
            onSelectionChanged: (set) => setState(() => _intensity = set.first),
          ),
          
          const SizedBox(height: 32),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              labelStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.edit_note_rounded,
                  size: 20, color: isDark ? Colors.white24 : Colors.grey.shade400),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.mood.withOpacity(0.8),
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mood,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Save Record', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
