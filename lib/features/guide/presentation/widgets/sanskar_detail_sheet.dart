import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/sanskar_model.dart';
import '../providers/sanskar_provider.dart';
import '../../../../core/constants/app_colors.dart';

class SanskarDetailSheet extends ConsumerStatefulWidget {
  final SanskarModel sanskar;
  final DateTime effectiveDate;

  const SanskarDetailSheet({
    super.key,
    required this.sanskar,
    required this.effectiveDate,
  });

  @override
  ConsumerState<SanskarDetailSheet> createState() => _SanskarDetailSheetState();
}

class _SanskarDetailSheetState extends ConsumerState<SanskarDetailSheet> {
  late TextEditingController _notesController;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.sanskar.notes);
    _currentDate = widget.sanskar.customDate ?? widget.effectiveDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _currentDate = picked);
      ref.read(sanskarsProvider.notifier).updateCustomDate(widget.sanskar.id, picked);
    }
  }

  void _saveNotes() {
    ref.read(sanskarsProvider.notifier).updateNotes(widget.sanskar.id, _notesController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes saved!')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sanskar = ref.watch(sanskarsProvider).firstWhere((s) => s.id == widget.sanskar.id);

    return Material(
      color: isDark ? const Color(0xFF1E1C20) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(sanskar.emojiIcon, style: const TextStyle(fontSize: 32))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sanskar.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        sanskar.sanskritName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: sanskar.isCompleted,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    ref.read(sanskarsProvider.notifier).markCompleted(sanskar.id, val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Spiritual Meaning',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              sanskar.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Scheduled Date', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(DateFormat.yMMMMd().format(_currentDate)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                        label: const Text('Change'),
                      ),
                    ],
                  ),
                  if (sanskar.customDate != null) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Revert to traditional (${sanskar.defaultRule.traditionalTimingText})', style: const TextStyle(fontSize: 12)),
                        TextButton(
                          onPressed: () {
                            ref.read(sanskarsProvider.notifier).updateCustomDate(sanskar.id, null);
                            setState(() => _currentDate = widget.effectiveDate); // Revert local state to originally calculated
                          },
                          child: const Text('Reset', style: TextStyle(fontSize: 12)),
                        )
                      ],
                    )
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Remind me beforehand', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Get a notification a few days prior'),
              value: sanskar.reminderEnabled,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                ref.read(sanskarsProvider.notifier).toggleReminder(sanskar.id, val);
              },
            ),
            const SizedBox(height: 24),
            const Text('Personal Notes / Memories', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add family traditions, pandit details, or memories here...',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saveNotes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Notes'),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
