// lib/features/settings/presentation/screens/reminders_setting_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/reminder_settings_provider.dart';
import '../../domain/models/reminder_settings_model.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/services/reminder_service.dart';

class RemindersSettingScreen extends ConsumerWidget {
  const RemindersSettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Master Toggle
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
              side: BorderSide(
                  color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08)),
            ),
            color: Theme.of(context).cardColor,
            child: SwitchListTile(
              title: const Text(
                'Enable Reminders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle:
                  const Text('Turn on to manage daily reminders for your baby'),
              value: settings.isMasterEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) async {
                if (val) {
                  await ReminderService.requestPermissions();
                }
                final is24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
                ref.read(reminderSettingsProvider.notifier).toggleMaster(val, is24Hour: is24Hour);
              },
            ),
          ),

          // Exact Alarm Warning (Android 12+)
          if (Platform.isAndroid && settings.isMasterEnabled)
            FutureBuilder<PermissionStatus>(
              future: Permission.scheduleExactAlarm.status,
              builder: (context, snapshot) {
                if (snapshot.hasData && !snapshot.data!.isGranted) {
                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Exact Alarms Denied',
                                  style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text(
                                  'Reminders may be delayed or missed. Please enable "Alarms & reminders" in settings.',
                                  style: TextStyle(
                                      color: AppColors.error, fontSize: 12)),
                              TextButton(
                                onPressed: () {
                                  openAppSettings();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  alignment: Alignment.centerLeft,
                                ),
                                child: const Text('Open Settings',
                                    style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

          const SizedBox(height: 24),

          if (settings.isMasterEnabled) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text(
                'CATEGORIES',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
                side: BorderSide(
                    color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08)),
              ),
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  _buildCategoryTile(
                    context,
                    ref,
                    title: 'Feeding Reminders',
                    emoji: '🍼',
                    category: 'feeding',
                    catSettings: settings.feeding,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildCategoryTile(
                    context,
                    ref,
                    title: 'Sleep Reminders',
                    emoji: '😴',
                    category: 'sleep',
                    catSettings: settings.sleep,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildCategoryTile(
                    context,
                    ref,
                    title: 'Diaper Reminders',
                    emoji: '🧷',
                    category: 'diaper',
                    catSettings: settings.diaper,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String emoji,
    required String category,
    required ReminderCategorySettings catSettings,
  }) {
    String subtitleText = '';
    if (catSettings.mode == 'smart') {
      subtitleText = 'Smart Mode: Wait ${catSettings.repeatHours} hr after action';
    } else if (catSettings.mode == 'repeat') {
      subtitleText = 'Repeat every ${catSettings.repeatHours} hr';
    } else {
      subtitleText = 'Exact time: ${catSettings.exactTime}';
    }

    if (catSettings.isEnabled && catSettings.nextScheduledTime != null) {
      final now = DateTime.now();
      final isToday = catSettings.nextScheduledTime!.year == now.year && 
                      catSettings.nextScheduledTime!.month == now.month && 
                      catSettings.nextScheduledTime!.day == now.day;
      
      final dayStr = isToday ? "Today" : "Tomorrow";
      final is24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
      final timeStr = is24Hour 
          ? DateFormat('HH:mm').format(catSettings.nextScheduledTime!) 
          : DateFormat('h:mm a').format(catSettings.nextScheduledTime!);
      
      subtitleText += '\nNext reminder: $dayStr • $timeStr';
    }

    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitleText),
      trailing: Switch(
        value: catSettings.isEnabled,
        activeColor: AppColors.primary,
        onChanged: (val) {
          final notifier = ref.read(reminderSettingsProvider.notifier);
          final updated = catSettings.copyWith(isEnabled: val);
          final is24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
          if (category == 'feeding') notifier.updateFeeding(updated, is24Hour: is24Hour);
          if (category == 'sleep') notifier.updateSleep(updated, is24Hour: is24Hour);
          if (category == 'diaper') notifier.updateDiaper(updated, is24Hour: is24Hour);
        },
      ),
      onTap: () {
        context.push('/settings/reminders/detail', extra: category);
      },
    );
  }
}
