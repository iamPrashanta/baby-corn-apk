// core/local_storage/hive_manager.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../features/records/domain/models/record_model.dart';
import '../../features/records/domain/models/active_session_model.dart';
import '../../features/guide/domain/models/sanskar_model.dart';
import '../../features/development/domain/models/moment_model.dart';
import '../../features/medication/domain/models/medication_model.dart';
import '../../features/settings/domain/models/family_member_model.dart';
import '../../features/guide/domain/models/food_intro_record.dart';

class HiveManager {
  static const String babyProfileBox = 'baby_profile';
  static const String recordsBox = 'records';
  static const String remindersBox = 'reminders';
  static const String settingsBox = 'settings';

  static const String syncQueueBox = 'sync_queue'; // for offline-first sync engine
  static const String activeSessionBox = 'active_session';
  static const String sanskarsBox = 'sanskars';
  static const String momentsBox = 'moments';
  static const String medicationsBox = 'medications';
  static const String familyMembersBox = 'family_members';
  static const String foodTrackerBox = 'food_tracker';
  static const String scheduledNotificationKeysBox = 'scheduled_notification_keys';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters safely
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RecordModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ActiveSessionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SanskarModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SanskarRuleAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SanskarOffsetUnitAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(MomentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(MedicationModelAdapter());
    }
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(FamilyMemberModelAdapter());
    }
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(FoodIntroStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(51)) {
      Hive.registerAdapter(FoodIntroRecordAdapter());
    }
    
    // Open Boxes
    await Future.wait([
      Hive.openBox(babyProfileBox),
      Hive.openBox<RecordModel>(recordsBox),
      Hive.openBox(remindersBox),
      Hive.openBox(settingsBox),

      Hive.openBox(syncQueueBox),
      Hive.openBox<ActiveSessionModel>(activeSessionBox),
      Hive.openBox<SanskarModel>(sanskarsBox),
      Hive.openBox<MomentModel>(momentsBox),
      Hive.openBox<MedicationModel>(medicationsBox),
      Hive.openBox<FamilyMemberModel>(familyMembersBox),
      Hive.openBox<FoodIntroRecord>(foodTrackerBox),
      Hive.openBox<String>(scheduledNotificationKeysBox),
    ]);
  }

  static Box<RecordModel> getRecordsBox() => Hive.box<RecordModel>(recordsBox);
  static Box<ActiveSessionModel> getActiveSessionBox() => Hive.box<ActiveSessionModel>(activeSessionBox);
  static Box<SanskarModel> getSanskarsBox() => Hive.box<SanskarModel>(sanskarsBox);
  static Box<MomentModel> getMomentsBox() => Hive.box<MomentModel>(momentsBox);
  static Box<MedicationModel> getMedicationsBox() => Hive.box<MedicationModel>(medicationsBox);
  static Box<FamilyMemberModel> getFamilyMembersBox() => Hive.box<FamilyMemberModel>(familyMembersBox);
  static Box<FoodIntroRecord> getFoodTrackerBox() => Hive.box<FoodIntroRecord>(foodTrackerBox);
  static Box<String> getScheduledNotificationKeysBox() => Hive.box<String>(scheduledNotificationKeysBox);
  static Box getSyncQueueBox() => Hive.box(syncQueueBox);
  static Box getSettingsBox() => Hive.box(settingsBox);
  static Box getProfileBox() => Hive.box(babyProfileBox);
}
