// features/records/presentation/screens/diaper_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/records_provider.dart';
import '../../domain/models/record_model.dart';
import '../../../../core/constants/app_colors.dart';

class DiaperEntryScreen extends ConsumerStatefulWidget {
  final String? initialStatus;
  const DiaperEntryScreen({super.key, this.initialStatus});

  @override
  ConsumerState<DiaperEntryScreen> createState() => _DiaperEntryScreenState();
}

class _DiaperEntryScreenState extends ConsumerState<DiaperEntryScreen> {
  late String _status;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final init = widget.initialStatus;
    if (init == 'Wet' || init == 'Dirty' || init == 'Mixed') {
      _status = init!;
    } else {
      _status = 'Wet';
    }
  }

  Future<void> _save() async {
    final record = RecordModel(
      id: const Uuid().v4(),
      type: 'diaper',
      timestamp: DateTime.now(),
      metadata: {
        'status': _status,
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
      appBar: AppBar(title: const Text('Log Diaper')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Wet', label: Text('Wet')),
              ButtonSegment(value: 'Dirty', label: Text('Dirty')),
              ButtonSegment(value: 'Mixed', label: Text('Mixed')),
            ],
            selected: {_status},
            onSelectionChanged: (set) => setState(() => _status = set.first),
          ),
          const SizedBox(height: 28),
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
                  color: AppColors.diaper.withOpacity(0.5),
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
            child: const Text('Save Record'),
          ),
        ],
      ),
    );
  }
}
