// lib/features/settings/presentation/screens/reminders_setting_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/reminder_settings_provider.dart';
import '../../domain/models/reminder_settings_model.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/permission_service.dart';

// Health integrations
import '../../../medication/presentation/providers/medication_provider.dart';
import '../../../records/presentation/providers/records_provider.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../records/domain/models/vaccine_schedule.dart';

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
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMasterToggle(context, ref, settings, isDark),
                if (Platform.isAndroid && settings.isMasterEnabled)
                  _buildAlarmProtectionCard(context, isDark),
                const SizedBox(height: 32),
                if (settings.isMasterEnabled) ...[
                  _buildSectionHeader('EVERYDAY CARE'),
                  _buildEverydayCareCard(context, ref, settings, isDark),

                  const SizedBox(height: 32),

                  _buildSectionHeader('HEALTH & TRACKING'),
                  _buildHealthCard(context, ref, isDark),

                  const SizedBox(height: 64), // bottom padding
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggle(BuildContext context, WidgetRef ref,
      ReminderSettingsModel settings, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: settings.isMasterEnabled
              ? [AppColors.primary, AppColors.primary.withOpacity(0.8)]
              : [Colors.grey.shade400, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: settings.isMasterEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: SwitchListTile(
        title: const Text(
          'Master Reminders',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        subtitle: const Text('Enable or disable all app reminders',
            style: TextStyle(color: Colors.white70)),
        value: settings.isMasterEnabled,
        activeColor: Colors.white,
        activeTrackColor: Colors.white30,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.black26,
        onChanged: (val) async {
          if (val) {
            await ReminderService.requestPermissions(context);
          }
          final is24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
          ref
              .read(reminderSettingsProvider.notifier)
              .toggleMaster(val, is24Hour: is24Hour);
        },
      ),
    );
  }

  Widget _buildAlarmProtectionCard(BuildContext context, bool isDark) {
    if (!Platform.isAndroid) return const SizedBox.shrink();

    return FutureBuilder<Map<String, bool>>(
      future: PermissionService.getAlarmPermissionDiagnostics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final diagnostics = snapshot.data!;
        final allGranted = diagnostics.values.every((v) => v == true);
        final color = allGranted ? Colors.green : AppColors.error;

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(allGranted ? Icons.verified_user_rounded : Icons.shield_rounded, color: color),
                  const SizedBox(width: 8),
                  Text('Alarm Protection Status', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                allGranted 
                  ? 'All systems go! Your alarms are protected and will ring reliably.'
                  : 'Some permissions are missing. Your alarms might not ring on time.', 
                style: TextStyle(color: color, fontSize: 13, height: 1.4)
              ),
              const SizedBox(height: 16),
              _buildDiagnosticRow('Notification permission', diagnostics['notifications'] == true, isDark),
              _buildDiagnosticRow('Exact alarm permission', diagnostics['exactAlarm'] == true, isDark),
              _buildDiagnosticRow('Battery optimization disabled', diagnostics['batteryOptimization'] == true, isDark),
              _buildDiagnosticRow('Full screen intent enabled', diagnostics['fullScreenIntent'] == true, isDark),
              if (!allGranted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                    ),
                    onPressed: () => PermissionService.openSettings(),
                    child: const Text('Open Settings to Fix', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _buildDiagnosticRow(String label, bool isGranted, bool isDark) {
    final color = isGranted ? Colors.green : AppColors.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary.withOpacity(0.8),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEverydayCareCard(BuildContext context, WidgetRef ref,
      ReminderSettingsModel settings, bool isDark) {
    return Card(
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
            title: 'Feeding',
            emoji: '🍼',
            category: 'feeding',
            catSettings: settings.feeding,
          ),
          const Divider(height: 1, indent: 64),
          _buildCategoryTile(
            context,
            ref,
            title: 'Sleep',
            emoji: '😴',
            category: 'sleep',
            catSettings: settings.sleep,
          ),
          const Divider(height: 1, indent: 64),
          _buildCategoryTile(
            context,
            ref,
            title: 'Diaper',
            emoji: '🧷',
            category: 'diaper',
            catSettings: settings.diaper,
          ),
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
      subtitleText = 'Wait ${catSettings.repeatHours} hr after action';
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

      subtitleText += '\nNext: $dayStr • $timeStr';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      subtitle:
          Text(subtitleText, style: const TextStyle(height: 1.4, fontSize: 13)),
      trailing: Switch(
        value: catSettings.isEnabled,
        activeColor: AppColors.primary,
        onChanged: (val) {
          final notifier = ref.read(reminderSettingsProvider.notifier);
          final updated = catSettings.copyWith(isEnabled: val);
          final is24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
          if (category == 'feeding') {
            notifier.updateFeeding(updated, is24Hour: is24Hour);
          }
          if (category == 'sleep') {
            notifier.updateSleep(updated, is24Hour: is24Hour);
          }
          if (category == 'diaper') {
            notifier.updateDiaper(updated, is24Hour: is24Hour);
          }
        },
      ),
      onTap: () {
        context.push('/settings/reminders/detail', extra: category);
      },
    );
  }

  Widget _buildHealthCard(BuildContext context, WidgetRef ref, bool isDark) {
    // Medications logic
    final medsAsync = ref.watch(medicationsProvider);
    int activeMeds = 0;
    if (medsAsync is AsyncData) {
      activeMeds = medsAsync.value!.where((m) => m.isActive).length;
    }

    // Vaccines logic
    final recordsAsync = ref.watch(recordsProvider);
    final activeBaby = ref.watch(activeBabyProvider);
    DateTime? nextVaccineDate;

    if (recordsAsync is AsyncData && activeBaby != null) {
      final records = recordsAsync.value!;
      final vaccineRecords = records.where((r) => r.type == 'vaccine').toList();

      for (final item in standardVaccineSchedule) {
        final isDone = vaccineRecords.any((r) =>
            r.metadata['vaccineName'] == item.name &&
            (r.metadata['status'] == 'completed' ||
                r.metadata['status'] == null));
        if (!isDone) {
          final pendingRecord = vaccineRecords
              .where((r) =>
                  r.metadata['vaccineName'] == item.name &&
                  r.metadata['status'] == 'pending')
              .firstOrNull;
          DateTime dueDate = activeBaby.birthDate
              .add(Duration(days: item.recommendedDaysFromBirth));
          if (pendingRecord != null) {
            final dueDateStr = pendingRecord.metadata['dueDate'];
            if (dueDateStr != null) {
              dueDate = DateTime.parse(dueDateStr);
            } else {
              dueDate = pendingRecord.timestamp;
            }
          }

          if (nextVaccineDate == null || dueDate.isBefore(nextVaccineDate)) {
            nextVaccineDate = dueDate;
          }
        }
      }
    }

    return Card(
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
          // Medications
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('💊', style: TextStyle(fontSize: 24))),
            ),
            title: const Text('Medications',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            subtitle: Text(
                activeMeds > 0
                    ? '$activeMeds active medication(s)'
                    : 'No active medications',
                style: const TextStyle(height: 1.4, fontSize: 13)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey),
            onTap: () => context.push('/medications'),
          ),

          const Divider(height: 1, indent: 64),

          // Vaccines
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.vaccine.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('💉', style: TextStyle(fontSize: 24))),
            ),
            title: const Text('Vaccinations',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            subtitle: Text(
                nextVaccineDate != null
                    ? 'Next due: ${DateFormat('MMM d, yyyy').format(nextVaccineDate)}'
                    : 'All caught up!',
                style: const TextStyle(height: 1.4, fontSize: 13)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey),
            onTap: () => context.push('/vaccines'),
          ),
        ],
      ),
    );
  }
}
