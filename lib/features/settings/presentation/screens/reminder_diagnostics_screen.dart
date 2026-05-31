// lib/features/settings/presentation/screens/reminder_diagnostics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../../core/services/reminder_service.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class ReminderDiagnosticsScreen extends StatefulWidget {
  const ReminderDiagnosticsScreen({super.key});

  @override
  State<ReminderDiagnosticsScreen> createState() => _ReminderDiagnosticsScreenState();
}

class _ReminderDiagnosticsScreenState extends State<ReminderDiagnosticsScreen> {
  bool _isLoading = true;
  String _notificationStatus = 'Checking...';
  String _exactAlarmStatus = 'Checking...';
  String _batteryOptStatus = 'Checking...';
  String _timezone = 'Checking...';
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);

    // Permissions
    final notifPerm = await Permission.notification.status;
    final alarmPerm = await Permission.scheduleExactAlarm.status;
    final batteryPerm = await Permission.ignoreBatteryOptimizations.status;

    // Timezone
    String tz = 'Unknown';
    try {
      tz = (await FlutterTimezone.getLocalTimezone()).toString();
    } catch (e) {
      tz = 'Error: $e';
    }

    // Pending notifications
    int count = 0;
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final pending = await plugin.pendingNotificationRequests();
      count = pending.length;
    } catch (e) {
      count = -1;
    }

    setState(() {
      _notificationStatus = notifPerm.isGranted ? 'Granted' : 'Denied/Restricted';
      _exactAlarmStatus = alarmPerm.isGranted ? 'Granted' : 'Denied/Restricted';
      _batteryOptStatus = batteryPerm.isGranted ? 'Ignored (Good)' : 'Optimized (May delay alarms)';
      _timezone = tz;
      _pendingCount = count;
      _isLoading = false;
    });
  }

  Future<void> _scheduleTest() async {
    await ReminderService.scheduleReminder(
      id: 999999,
      title: 'Diagnostics Test',
      body: 'If you see this, notifications are working!',
      delay: const Duration(seconds: 10),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test reminder scheduled in 10 seconds.')),
      );
      _runDiagnostics();
    }
  }

  Future<void> _requestBatteryIgnore() async {
    await Permission.ignoreBatteryOptimizations.request();
    _runDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Reminder Diagnostics'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildCard(
                  'Notification Permission',
                  _notificationStatus,
                  _notificationStatus == 'Granted',
                ),
                _buildCard(
                  'Exact Alarm Permission',
                  _exactAlarmStatus,
                  _exactAlarmStatus == 'Granted',
                ),
                _buildCard(
                  'Battery Optimization',
                  _batteryOptStatus,
                  _batteryOptStatus.contains('Ignored'),
                  action: _batteryOptStatus.contains('Optimized')
                      ? TextButton(
                          onPressed: _requestBatteryIgnore,
                          child: const Text('Fix'),
                        )
                      : null,
                ),
                _buildCard(
                  'Local Timezone',
                  _timezone,
                  true,
                ),
                _buildCard(
                  'Pending Reminders',
                  '$_pendingCount active triggers',
                  _pendingCount > 0,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _scheduleTest,
                  icon: const Icon(Icons.timer),
                  label: const Text('Schedule Test Reminder (10s)'),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(String title, String value, bool isGood, {Widget? action}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isGood ? Icons.check_circle : Icons.error,
              color: isGood ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value),
                ],
              ),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}
