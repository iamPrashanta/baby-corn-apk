// lib/features/settings/presentation/screens/reminder_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_settings_provider.dart';
import '../../domain/models/reminder_settings_model.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/native/alarm/ringtone_channel.dart';
import '../../../../features/reminders/domain/models/alarm_profile_model.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class ReminderDetailScreen extends ConsumerStatefulWidget {
  final String category; // 'feeding', 'sleep', or 'diaper'

  const ReminderDetailScreen({super.key, required this.category});

  @override
  ConsumerState<ReminderDetailScreen> createState() =>
      _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends ConsumerState<ReminderDetailScreen> {
  late String _mode;
  late int _repeatHours;
  late TimeOfDay _exactTime;
  DateTime? _nextScheduledTime;
  late AlarmProfile _profile;
  String? _currentlyPlayingUri;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(reminderSettingsProvider);
    final catSettings = _getCatSettings(settings);

    _mode = catSettings.mode;
    _repeatHours = catSettings.repeatHours;
    _nextScheduledTime = catSettings.nextScheduledTime;
    _profile = catSettings.profile;

    final parts = catSettings.exactTime.split(':');
    _exactTime = TimeOfDay(
      hour: parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 8) : 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    super.dispose();
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

    final formattedTime =
        '${_exactTime.hour.toString().padLeft(2, '0')}:${_exactTime.minute.toString().padLeft(2, '0')}';

    final updated = currentSettings.copyWith(
      mode: _mode,
      repeatHours: _repeatHours,
      exactTime: formattedTime,
      profile: _profile,
      isEnabled: true, // Auto-enable when saving from inner page
    );

    final is24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
    
    // Auto-enable master switch if it was off
    final fullSettings = ref.read(reminderSettingsProvider);
    if (!fullSettings.isMasterEnabled) {
      notifier.toggleMaster(true, is24Hour: is24Hour);
    }

    if (widget.category == 'feeding') notifier.updateFeeding(updated, is24Hour: is24Hour);
    if (widget.category == 'sleep') notifier.updateSleep(updated, is24Hour: is24Hour);
    if (widget.category == 'diaper') notifier.updateDiaper(updated, is24Hour: is24Hour);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getCategoryTitle()} settings saved!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      ),
    );

    context.pop();
  }

  String _getCategoryTitle() {
    if (widget.category == 'feeding') return 'Feeding Reminder';
    if (widget.category == 'sleep') return 'Sleep Reminder';
    if (widget.category == 'diaper') return 'Diaper Reminder';
    return 'Reminder';
  }

  void _showSoundPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Select Alarm Sound', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  _buildSoundOption('Phone Default Alarm', 'default', setSheetState),
                  _buildSoundOption('Baby Corn Soft Bell', 'assets/audio/alarm.wav', setSheetState),
                  _buildSoundOption('Baby Corn Gentle Chime', 'assets/audio/chime.wav', setSheetState, isComingSoon: true),
                  _buildSoundOption('Baby Corn Piano', 'assets/audio/piano.wav', setSheetState, isComingSoon: true),
                  ListTile(
                    title: const Text('Pick From Device'),
                    leading: const Icon(Icons.folder_open),
                    onTap: () async {
                      FlutterRingtonePlayer().stop();
                      if (mounted) {
                        setState(() => _currentlyPlayingUri = null);
                        setSheetState(() => _currentlyPlayingUri = null);
                      }
                      Navigator.pop(context);
                      final result = await RingtoneChannel.pickRingtone(
                        currentUri: _profile.ringtoneUri,
                        isAlarm: _profile.alarmType == 'full_alarm',
                      );
                      if (result != null) {
                        setState(() {
                          _profile = _profile.copyWith(
                            ringtoneUri: result['uri'],
                            ringtoneTitle: result['title'],
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          }
        );
      },
    ).whenComplete(() {
      FlutterRingtonePlayer().stop();
      if (mounted) {
        setState(() => _currentlyPlayingUri = null);
      }
    });
  }

  Widget _buildSoundOption(String title, String uri, StateSetter setSheetState, {bool isComingSoon = false}) {
    final isSelected = _profile.ringtoneUri == uri;
    final isPlaying = _currentlyPlayingUri == uri;
    
    return ListTile(
      title: Text(title, style: TextStyle(color: isComingSoon ? Colors.grey : null)),
      subtitle: isComingSoon ? const Text('Coming Soon') : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isComingSoon)
            IconButton(
              icon: Icon(
                isPlaying ? Icons.stop_circle : Icons.play_circle_outline,
                color: isPlaying ? AppColors.error : AppColors.primary,
              ),
              onPressed: () {
                if (isPlaying) {
                  FlutterRingtonePlayer().stop();
                  setSheetState(() => _currentlyPlayingUri = null);
                  setState(() => _currentlyPlayingUri = null);
                } else {
                  FlutterRingtonePlayer().stop();
                  if (uri == 'default') {
                    FlutterRingtonePlayer().playAlarm(asAlarm: false, looping: false);
                  } else if (uri.startsWith('assets/')) {
                    FlutterRingtonePlayer().play(fromAsset: uri, asAlarm: false, looping: false);
                  } else {
                    FlutterRingtonePlayer().play(fromFile: uri, asAlarm: false, looping: false);
                  }
                  setSheetState(() => _currentlyPlayingUri = uri);
                  setState(() => _currentlyPlayingUri = uri);
                }
              },
            ),
          if (isSelected) const Icon(Icons.check, color: AppColors.primary),
        ],
      ),
      onTap: isComingSoon
          ? null
          : () {
              setState(() {
                _profile = _profile.copyWith(
                  ringtoneUri: uri,
                  ringtoneTitle: title,
                );
              });
              Navigator.pop(context);
            },
    );
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
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: SegmentedButton<String>(
                segments: [
                  const ButtonSegment(value: 'exact', label: Text('Exact')),
                  const ButtonSegment(value: 'repeat', label: Text('Repeat')),
                  if (widget.category == 'feeding') // Show Smart only for feeding currently
                    const ButtonSegment(value: 'smart', label: Text('Smart')),
                ],
                selected: {_mode},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _mode = newSelection.first;
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
            const SizedBox(height: 32),

            if (_nextScheduledTime != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Scheduled Trigger:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy • hh:mm a').format(_nextScheduledTime!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_mode == 'exact' && _nextScheduledTime!.day != DateTime.now().day) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Today's reminder time has passed. Next reminder scheduled for tomorrow.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (_mode == 'repeat' || _mode == 'smart') ...[
              Text(
                _mode == 'smart' ? 'Wait Between Feeds' : 'Repeat Every',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_mode == 'smart') ...[
                const SizedBox(height: 8),
                Text(
                  'Calculated automatically from your last feeding record.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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
                    style: const TextStyle(
                        fontSize: 64, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Text('hr',
                      style: TextStyle(fontSize: 24, color: Colors.grey)),
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
            ] else if (_mode == 'exact') ...[
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
                  borderRadius: BorderRadius.circular(4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color:
                            AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                      ),
                    ),
                    child: Text(
                      _exactTime.format(context),
                      style: const TextStyle(
                          fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Alarm Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use Full-Screen Alarm'),
              subtitle: const Text('Wakes device and sounds alarm tone'),
              value: _profile.alarmType == 'full_alarm',
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _profile = _profile.copyWith(alarmType: val ? 'full_alarm' : 'notification');
                });
              },
            ),
            ListTile(
              title: const Text('Alarm Sound'),
              subtitle: Text('Selected: ${_profile.ringtoneTitle}'),
              trailing: const Icon(Icons.music_note),
              onTap: _showSoundPicker,
            ),
            SwitchListTile(
              title: const Text('Gradually Increase Volume'),
              subtitle: const Text('Fade in over 30 seconds'),
              value: _profile.gradualVolume,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _profile = _profile.copyWith(gradualVolume: val);
                });
              },
            ),
            SwitchListTile(
              title: const Text('Vibrate'),
              value: _profile.vibrationEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _profile = _profile.copyWith(vibrationEnabled: val);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
