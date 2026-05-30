// features/records/presentation/screens/feeding_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/records_provider.dart';
import '../../domain/models/record_model.dart';
import '../../../../core/constants/app_colors.dart';

class FeedingEntryScreen extends ConsumerStatefulWidget {
  const FeedingEntryScreen({super.key});

  @override
  ConsumerState<FeedingEntryScreen> createState() => _FeedingEntryScreenState();
}

class _FeedingEntryScreenState extends ConsumerState<FeedingEntryScreen> {
  String _feedingMethod = 'Left Breast';
  final _durationController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _timestamp = DateTime.now();

  Future<void> _save() async {
    final notifier = ref.read(recordsProvider.notifier);
    
    final record = RecordModel(
      id: const Uuid().v4(),
      type: 'feeding',
      timestamp: _timestamp,
      metadata: {
        'method': _feedingMethod,
        'side': _feedingMethod,
        'duration': int.tryParse(_durationController.text) ?? 0,
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
            'You have another feeding record logged around this time. Would you like to merge them into a single feeding session?',
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
        final oldDuration = (mergeable.metadata['duration'] as num?)?.toInt() ?? 0;
        final newDuration = int.tryParse(_durationController.text) ?? 0;
        
        final oldMethod = mergeable.metadata['method'] as String? ?? '';
        String mergedMethod = _feedingMethod;
        
        if (oldMethod.contains('Breast') && _feedingMethod.contains('Breast') && oldMethod != _feedingMethod) {
          mergedMethod = 'Left & Right Breast';
        }

        final mergedNote = [
          if ((mergeable.metadata['note'] as String?)?.isNotEmpty == true) mergeable.metadata['note'],
          if (_noteController.text.isNotEmpty) _noteController.text,
        ].join(' | ');

        final mergedRecord = mergeable.copyWith(
          timestamp: _timestamp.isAfter(mergeable.timestamp) ? _timestamp : mergeable.timestamp,
          metadata: {
            ...mergeable.metadata,
            'method': mergedMethod,
            'side': mergedMethod,
            'duration': oldDuration + newDuration,
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

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.grey.shade500,
        fontSize: 14,
      ),
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: isDark ? Colors.white24 : Colors.grey.shade400)
          : null,
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
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Feeding')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Left Breast', label: Text('Left')),
              ButtonSegment(value: 'Right Breast', label: Text('Right')),
              ButtonSegment(value: 'Bottle', label: Text('Bottle')),
              ButtonSegment(value: 'Solid', label: Text('Solid')),
            ],
            selected: {_feedingMethod},
            onSelectionChanged: (set) => setState(() => _feedingMethod = set.first),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Duration (minutes)', icon: Icons.timer_outlined),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _noteController,
            decoration: _inputDecoration('Notes (optional)', icon: Icons.edit_note_rounded),
            maxLines: 3,
            minLines: 1,
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
