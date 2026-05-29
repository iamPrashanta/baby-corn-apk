// features/reminders/data/repositories/reminder_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_storage/hive_manager.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});

class ReminderRepository {
  Future<void> saveReminderSettings(String type, bool isEnabled, int intervalMinutes) async {
    final box = HiveManager.getSettingsBox();
    await box.put('reminder_${type}_enabled', isEnabled);
    await box.put('reminder_${type}_interval', intervalMinutes);
  }

  bool isReminderEnabled(String type) {
    final box = HiveManager.getSettingsBox();
    return box.get('reminder_${type}_enabled', defaultValue: false) as bool;
  }
  
  int getReminderInterval(String type) {
    final box = HiveManager.getSettingsBox();
    return box.get('reminder_${type}_interval', defaultValue: 120) as int;
  }
}
