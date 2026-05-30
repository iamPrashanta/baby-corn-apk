// features/settings/presentation/screens/reminder_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/reminder_settings_provider.dart';
import '../../domain/models/reminder_settings_model.dart';
import '../../../../core/constants/app_colors.dart';

class ReminderDetailScreen extends ConsumerStatefulWidget {
  final String category; // 'feeding', 'sleep', or 'diaper'

  const ReminderDetailScreen({super.key, required this.category});

  @override
  ConsumerState<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends ConsumerState<ReminderDetailScreen> {
  late bool _isRepeat;
  late int _repeatHours;
  late TimeOfDay _exactTime;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(reminderSettingsProvider);
    final catSettings = _getCatSettings(settings);
    
    _isRepeat = catSettings.isRepeat;
    _repeatHours = catSettings.repeatHours;
    
    final parts = catSettings.exactTime.split(':');
    _exactTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  ReminderCategorySettings _getCatSettings(ReminderSettingsModel settings) {
    if (widget.category == 'feeding') return settings.feeding;
    if (widget.category == 'sleep') return settings.sleep;
    if (widget.category == 'diaper') return settings.diaper;
    return const ReminderCategorySettings();
  }

  void _save() {
    final notifier = ref.read(reminderSettingsProvider.notifier);
    final currentSettings = _getCatSettings(ref.read(reminderSettingsProvider));
    
    final formattedTime = '${_exactTime.hour.toString().padLeft(2, '0')}:${_exactTime.minute.toString().padLeft(2, '0')}';
    
    final updated = currentSettings.copyWith(
      isRepeat: _isRepeat,
      repeatHours: _repeatHours,
      exactTime: formattedTime,
    );

    if (widget.category == 'feeding') notifier.updateFeeding(updated);
    if (widget.category == 'sleep') notifier.updateSleep(updated);
    if (widget.category == 'diaper') notifier.updateDiaper(updated);

    context.pop();
  }

  String _getCategoryTitle() {
    if (widget.category == 'feeding') return 'Feeding Reminder';
    if (widget.category == 'sleep') return 'Sleep Reminder';
    if (widget.category == 'diaper') return 'Diaper Reminder';
    return 'Reminder';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryTitle()),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Control
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Repeat Interval')),
                  ButtonSegment(value: false, label: Text('Exact Time')),
                ],
                selected: {_isRepeat},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isRepeat = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary.withOpacity(0.2);
                      }
                      return Colors.transparent;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            if (_isRepeat) ...[
              const Text(
                'Repeat Every',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_repeatHours > 1) setState(() => _repeatHours--);
                    },
                    icon: const Icon(Icons.remove_circle_outline, size: 48),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '$_repeatHours',
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Text('hr', style: TextStyle(fontSize: 24, color: Colors.grey)),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: () {
                      if (_repeatHours < 24) setState(() => _repeatHours++);
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 48),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'Remind At',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Center(
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _exactTime,
                    );
                    if (picked != null) {
                      setState(() => _exactTime = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1C20) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                      ),
                    ),
                    child: Text(
                      _exactTime.format(context),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
