// features/settings/presentation/screens/reminders_setting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/reminder_settings_provider.dart';
import '../../domain/models/reminder_settings_model.dart';
import '../../../../core/constants/app_colors.dart';
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
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1C20) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
              ),
            ),
            child: SwitchListTile(
              title: const Text(
                'Enable Reminders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: const Text('Turn on to manage daily reminders for your baby'),
              value: settings.isMasterEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) async {
                if (val) {
                  await ReminderService.requestPermissions();
                }
                ref.read(reminderSettingsProvider.notifier).toggleMaster(val);
              },
            ),
          ),
          const SizedBox(height: 24),
          
          if (settings.isMasterEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1C20) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                ),
              ),
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
    final subtitleText = catSettings.isRepeat
        ? 'Repeat after ${catSettings.repeatHours} hr'
        : 'Exact time: ${catSettings.exactTime}';

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
          if (category == 'feeding') notifier.updateFeeding(updated);
          if (category == 'sleep') notifier.updateSleep(updated);
          if (category == 'diaper') notifier.updateDiaper(updated);
        },
      ),
      onTap: () {
        context.push('/settings/reminders/detail', extra: category);
      },
    );
  }
}
