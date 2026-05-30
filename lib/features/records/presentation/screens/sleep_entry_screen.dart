// features/records/presentation/screens/sleep_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/records_provider.dart';
import '../../domain/models/record_model.dart';
import '../../../../core/constants/app_colors.dart';

class SleepEntryScreen extends ConsumerStatefulWidget {
  const SleepEntryScreen({super.key});

  @override
  ConsumerState<SleepEntryScreen> createState() => _SleepEntryScreenState();
}

class _SleepEntryScreenState extends ConsumerState<SleepEntryScreen> {
  final _noteController = TextEditingController();
  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _endTime = DateTime.now();

  Future<void> _save() async {
    final notifier = ref.read(recordsProvider.notifier);
    
    final record = RecordModel(
      id: const Uuid().v4(),
      type: 'sleep',
      timestamp: _endTime,
      metadata: {
        'startTime': _startTime.toIso8601String(),
        'endTime': _endTime.toIso8601String(),
        'durationMinutes': _endTime.difference(_startTime).inMinutes,
        'durationSeconds': _endTime.difference(_startTime).inSeconds,
        'note': _noteController.text,
      },
    );
    
    final mergeable = notifier.findMergeableRecord(record, const Duration(minutes: 60));

    if (mergeable != null) {
      final shouldMerge = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Merge Records?'),
          content: const Text(
            'You have another sleep record logged around this time. Would you like to merge them into a single continuous sleep session?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Separate'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Merge'),
            ),
          ],
        ),
      );

      if (shouldMerge == true) {
        // Perform merge
        final oldStartTime = DateTime.parse(mergeable.metadata['startTime'] as String);
        final oldEndTime = DateTime.parse(mergeable.metadata['endTime'] as String);
        
        final newStart = oldStartTime.isBefore(_startTime) ? oldStartTime : _startTime;
        final newEnd = oldEndTime.isAfter(_endTime) ? oldEndTime : _endTime;

        final mergedNote = [
          if ((mergeable.metadata['note'] as String?)?.isNotEmpty == true) mergeable.metadata['note'],
          if (_noteController.text.isNotEmpty) _noteController.text,
        ].join(' | ');

        final mergedRecord = mergeable.copyWith(
          timestamp: newEnd,
          metadata: {
            ...mergeable.metadata,
            'startTime': newStart.toIso8601String(),
            'endTime': newEnd.toIso8601String(),
            'durationMinutes': newEnd.difference(newStart).inMinutes,
            'durationSeconds': newEnd.difference(newStart).inSeconds,
            'note': mergedNote,
          },
        );

        await notifier.updateRecord(mergedRecord);
        if (mounted) context.pop();
        return;
      }
    }

    await notifier.addRecord(record);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Log Sleep')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _TimePickerTile(
            label: 'Start Time',
            time: _startTime,
            isDark: isDark,
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_startTime),
              );
              if (time != null) {
                setState(() {
                  _startTime = DateTime(
                    _startTime.year, _startTime.month, _startTime.day,
                    time.hour, time.minute,
                  );
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _TimePickerTile(
            label: 'End Time',
            time: _endTime,
            isDark: isDark,
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_endTime),
              );
              if (time != null) {
                setState(() {
                  _endTime = DateTime(
                    _endTime.year, _endTime.month, _endTime.day,
                    time.hour, time.minute,
                  );
                });
              }
            },
          ),
          const SizedBox(height: 20),
          // Duration display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.sleep.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.sleep.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.bedtime_rounded, size: 18, color: AppColors.sleep),
                const SizedBox(width: 10),
                Text(
                  'Duration: ${_endTime.difference(_startTime).inMinutes} minutes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                  color: AppColors.sleep.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save Record'),
          ),
        ],
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool isDark;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 20, color: isDark ? Colors.white38 : Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white24 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
