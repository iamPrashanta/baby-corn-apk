// core/local_storage/hive_manager.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../features/records/domain/models/record_model.dart';
import '../../features/records/domain/models/active_session_model.dart';
import '../../features/guide/domain/models/sanskar_model.dart';

class HiveManager {
  static const String babyProfileBox = 'baby_profile';
  static const String recordsBox = 'records';
  static const String remindersBox = 'reminders';
  static const String settingsBox = 'settings';
  static const String cachedStatsBox = 'cached_stats';
  static const String syncQueueBox = 'sync_queue'; // for offline-first sync engine
  static const String activeSessionBox = 'active_session';
  static const String sanskarsBox = 'sanskars';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    Hive.registerAdapter(RecordModelAdapter());
    Hive.registerAdapter(ActiveSessionModelAdapter());
    Hive.registerAdapter(SanskarModelAdapter());
    Hive.registerAdapter(SanskarRuleAdapter());
    Hive.registerAdapter(SanskarOffsetUnitAdapter());
    
    // Open Boxes
    await Future.wait([
      Hive.openBox(babyProfileBox),
      Hive.openBox<RecordModel>(recordsBox),
      Hive.openBox(remindersBox),
      Hive.openBox(settingsBox),
      Hive.openBox(cachedStatsBox),
      Hive.openBox(syncQueueBox),
      Hive.openBox<ActiveSessionModel>(activeSessionBox),
      Hive.openBox<SanskarModel>(sanskarsBox),
    ]);
  }

  static Box<RecordModel> getRecordsBox() => Hive.box<RecordModel>(recordsBox);
  static Box<ActiveSessionModel> getActiveSessionBox() => Hive.box<ActiveSessionModel>(activeSessionBox);
  static Box<SanskarModel> getSanskarsBox() => Hive.box<SanskarModel>(sanskarsBox);
  static Box getSyncQueueBox() => Hive.box(syncQueueBox);
  static Box getSettingsBox() => Hive.box(settingsBox);
  static Box getProfileBox() => Hive.box(babyProfileBox);
}
