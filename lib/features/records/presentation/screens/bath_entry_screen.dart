// features/records/presentation/screens/bath_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/records_provider.dart';
import '../../domain/models/record_model.dart';

class BathEntryScreen extends ConsumerStatefulWidget {
  const BathEntryScreen({super.key});

  @override
  ConsumerState<BathEntryScreen> createState() => _BathEntryScreenState();
}

class _BathEntryScreenState extends ConsumerState<BathEntryScreen> {
  String _type = 'Tub Bath';
  bool _hairWashed = false;
  bool _lotionApplied = false;
  final _noteController = TextEditingController();

  Future<void> _save() async {
    final record = RecordModel(
      id: const Uuid().v4(),
      type: 'bath',
      timestamp: DateTime.now(),
      metadata: {
        'type': _type,
        'hairWashed': _hairWashed,
        'lotionApplied': _lotionApplied,
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
      appBar: AppBar(title: const Text('Log Bath')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          const Text(
            'Bath Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Sponge Bath', label: Text('Sponge')),
              ButtonSegment(value: 'Tub Bath', label: Text('Tub')),
              ButtonSegment(value: 'Shower', label: Text('Shower')),
            ],
            selected: {_type},
            onSelectionChanged: (set) => setState(() => _type = set.first),
          ),
          const SizedBox(height: 28),
          
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hair Washed', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Did you wash baby\'s hair?'),
            secondary: const Icon(Icons.face_retouching_natural, color: Colors.blueAccent),
            value: _hairWashed,
            onChanged: (val) => setState(() => _hairWashed = val),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lotion / Massage', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Applied lotion or massaged after?'),
            secondary: const Icon(Icons.clean_hands, color: Colors.teal),
            value: _lotionApplied,
            onChanged: (val) => setState(() => _lotionApplied = val),
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
                  color: Colors.lightBlue.withOpacity(0.5),
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
