import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/local_storage/hive_manager.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool _isLoading = true;
  bool _hasExactAlarm = false;
  bool _hasNotifications = false;
  bool _isBatteryOptimized = false;
  
  int _babiesCount = 0;
  int _recordsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkDatabaseHealth();
    _checkPermissions();
  }

  void _checkDatabaseHealth() {
    try {
      final profileBox = HiveManager.getProfileBox();
      final recordsBox = HiveManager.getRecordsBox();
      
      final babiesJson = profileBox.get('babies_list');
      if (babiesJson != null) {
        _babiesCount = (jsonDecode(babiesJson) as List).length;
      }
      _recordsCount = recordsBox.length;
    } catch (_) {
      debugPrint("Diagnostics DB error: $_");
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    
    final exactAlarm = await Permission.scheduleExactAlarm.status;
    final notifications = await Permission.notification.status;
    final batteryOpt = await Permission.ignoreBatteryOptimizations.status;

    if (mounted) {
      setState(() {
        _hasExactAlarm = exactAlarm.isGranted;
        _hasNotifications = notifications.isGranted;
        // If it's granted, it means the app is IGNORING optimizations (which is good)
        // If it's denied, it is still being optimized.
        _isBatteryOptimized = !batteryOpt.isGranted; 
        _isLoading = false;
      });
    }
  }

  Future<void> _requestExactAlarm() async {
    await Permission.scheduleExactAlarm.request();
    _checkPermissions();
  }

  Future<void> _requestNotifications() async {
    await Permission.notification.request();
    _checkPermissions();
  }

  Future<void> _requestBattery() async {
    await Permission.ignoreBatteryOptimizations.request();
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Diagnostics')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Alarm Diagnostics (OEM Test)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _DiagnosticTile(
                  title: 'Exact Alarms',
                  isGood: _hasExactAlarm,
                  description: 'Required for reliable background alarms.',
                  onAction: _hasExactAlarm ? null : _requestExactAlarm,
                ),
                const Divider(),
                _DiagnosticTile(
                  title: 'Notifications',
                  isGood: _hasNotifications,
                  description: 'Required to show alarm and reminder popups.',
                  onAction: _hasNotifications ? null : _requestNotifications,
                ),
                const Divider(),
                _DiagnosticTile(
                  title: 'Battery Optimization',
                  isGood: !_isBatteryOptimized,
                  description: 'Should be DISABLED (Ignored) so OEMs (Samsung, Xiaomi, Oppo) don\'t kill alarms.',
                  onAction: !_isBatteryOptimized ? null : _requestBattery,
                ),
                const SizedBox(height: 24),
                const Text('Database Diagnostics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _DiagnosticTile(
                  title: 'Registered Profiles',
                  isGood: true,
                  description: '$_babiesCount baby profile(s) found in Hive.',
                ),
                const Divider(),
                _DiagnosticTile(
                  title: 'Stored Records',
                  isGood: true,
                  description: '$_recordsCount record(s) logged securely offline.',
                ),
              ],
            ),
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  final String title;
  final bool isGood;
  final String description;
  final VoidCallback? onAction;

  const _DiagnosticTile({
    required this.title,
    required this.isGood,
    required this.description,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isGood ? Icons.check_circle : Icons.warning_amber_rounded,
        color: isGood ? Colors.green : AppColors.primary,
        size: 32,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(description),
      trailing: onAction != null 
          ? ElevatedButton(onPressed: onAction, child: const Text('Fix'))
          : const Text('OK', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
    );
  }
}
